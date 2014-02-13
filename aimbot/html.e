constant EV_NONE        = 0,
         EV_HEADER      = 1,
         EV_LINK        = 2,
         EV_TABLE_DATA  = 3,
         EV_SCRIPT      = 4

sequence parser_out, headers, tables, links, href, table
integer tlevel, next, parser

table = {}
tlevel = 0
next = EV_NONE

function nest_table (sequence tab, integer l)
    integer z

    for i = length(tab) to 1 by -1 do
        if length(tab[i]) and sequence(tab[i][1]) then
            tab[i] = nest_table(tab[i], l + 1)
        elsif tab[i][1] = #FE then
            z = tab[i][2]
            tab[i] = table[z]
        end if
    end for

    if l = 0 then
        return tab[1]
    else
        return tab
    end if
end function

function format_table (sequence tab)
    sequence out
    out = ""

    for i = 1 to length(tab) do
        for j = 1 to length(tab[i]) do
            if sequence(tab[i][j]) and sequence(tab[i][j][1]) then
                out &= format_table(tab[i][j])
            else
                out &= tab[i][j]
            end if
        end for
        out &= '\n'
    end for
    
    return out
end function

procedure add_to_end (sequence str)
    if tlevel and length(table[tlevel]) then
        if length(table[tlevel][$]) then
            table[tlevel][$][$] &= str
        else
            table[tlevel][$] = {{str}}
        end if
    else
        parser_out &= str
    end if
end procedure

function remove_newlines (sequence str)
    sequence rem
    integer first, count, i
    
    rem = {}
    first = -1
    count = 0
    i = 1
    
    while i <= length(str) do
        if str[i] = 10 then
            if count = 0 then first = i end if
            count += 1
        elsif str[i] != 10 and count then
            rem = append(rem, {first, count})

            first = -1
            count = 0
        end if

        i += 1
    end while
    
    for j = 1 to length(rem) do
        str = str[1..rem[j][1] - 1] & 32 & str[rem[j][1] + rem[j][2]..$]
    end for
    
    return str
end function

function html_text (sequence str)
    if equal(str, {10}) then return 1 end if

    if next = EV_TABLE_DATA then
        if tlevel and length(str) and length(table[tlevel][$]) then
            table[tlevel][$][$] &= str
            table[tlevel][$][$] = remove_newlines(table[tlevel][$][$])
        end if
    elsif next = EV_HEADER then
        str = remove_newlines(str)
        headers = append(headers, {str, floor(length(parser_out) / max_message_size) + 1})
        parser_out &= sprintf("==%s==\n", {str})
        next = EV_NONE
    elsif next = EV_LINK then
        add_to_end(remove_newlines(str))
    else
        parser_out &= remove_newlines(str)
    end if

    return 1
end function

function html_start (sequence tag, sequence params, sequence pvals)
    integer x
    --printf(1, "html_start: %s\n", {tag})
    
    tag = lower(tag)
    if equal(tag, "div") then
        params = lower(params)
        for i = 1 to length(params) do
            if equal(params[i], "class") and equal(pvals[i], "visualClear") then
                return 0
            end if
        end for
    elsif equal(tag, "table") then
        if tlevel >= 1 then
            add_to_end(#FE & tlevel + 1)
        elsif tlevel = 0 then
            parser_out &= sprintf("[TABLE %d]", length(tables) + 1)
        end if
        tlevel += 1
        table = append(table, {})
    elsif equal(tag, "tr") then
        table[tlevel] = append(table[tlevel], {})
    elsif find(tag, {"td", "th"}) then
        next = EV_TABLE_DATA
        table[tlevel][$] = append(table[tlevel][$], {})
    elsif equal(tag, "a") then
        x = find("href", lower(params))
        if x then
            if match("/wiki/", pvals[x]) = 1 then
                pvals[x] = pvals[x][7..$]
            elsif match("/w/index.php?", pvals[x]) = 1 then
                pvals[x] = pvals[x][match("title=", pvals[x]) + 6..$]
                pvals[x] = pvals[x][1..find('&', pvals[x]) - 1]
            else
                pvals[x] = 0
            end if
        
            if sequence(pvals[x]) then
                next = EV_LINK
                links = append(links, pvals[x])
                add_to_end("{")
            end if
        end if
    elsif find(tag, {"img"}) then
        add_to_end("[img]")
    elsif equal(tag, "br") then
        add_to_end("\n")
    elsif equal("span", tag) then
        params = lower(params)
        for i = 1 to length(params) do
            if equal(params[i], "class") and equal(pvals[i], "mw-headline") then
                next = EV_HEADER
            end if
        end for
    elsif equal("script", tag) then
        next = EV_SCRIPT
    end if
    return 1
end function

function wiki_wait_for_begin (sequence tag, sequence params, sequence pvals)
    if equal(lower(tag), "div") and
       length(pvals) and
       equal(pvals[1], "contentSub") then
        parser_out = ""
        set_start_tag_routine(parser, routine_id("html_start"))
    end if
    return 1
end function

function html_end (sequence tag)
    tag = lower(tag)
    
    if equal(tag, "table") then
        -- move backwards in the queue
        tlevel -= 1
    
        if tlevel = 0 then
            --tables &= format_table(table)
            tables = append(tables, format_table(table))
            table = {}
        end if
    elsif find(tag, {"td", "th"}) then
        next = EV_NONE
    elsif equal(tag, "br") then
        add_to_end("\n")
    elsif equal(tag, "script") then
        next = EV_NONE
    elsif equal(tag, "a") then
        if next = EV_LINK then
            next = EV_NONE
            add_to_end(sprintf("|%d}", length(links)))
        end if
    end if
    return 1
end function

global function parse_html_page (sequence file)
    tables = {}
    links = {}
    headers = {}
    parser_out = ""
    set_start_tag_routine(parser, routine_id("wiki_wait_for_begin"))
    parse(parser, file)

    return {parser_out, headers, links, tables}
end function

parser = new_html_parser()
set_start_tag_routine(parser, routine_id("html_start"))
set_end_tag_routine(parser, routine_id("html_end"))
set_text_routine(parser, routine_id("html_text"))


