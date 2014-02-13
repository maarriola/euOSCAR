include wildcard.e

constant roast_str = {#F3, #26, #81, #C4, #39, #86, #DB, #92, #71, #A3, #B9, #E6, #53, #7A, #95, #7C}

global function strip_name (sequence str)
    sequence out
    
    out = ""
    
    for i = 1 to length(str) do
    if str[i] != ' ' then
        out &= str[i]
    end if
    end for
    
    return lower(out)
end function

global function compare_name (sequence s1, sequence s2)
    return equal(strip_name(s1), strip_name(s2))
end function

global function roast (sequence pw)
    integer countB
    sequence out, outB
    
    out = ""
    
    countB = 1
    
    for count = 1 to length(pw) do
    out &= xor_bits(pw[count], roast_str[countB])

    countB += 1
    if countB > length(roast_str) then
        countB = 1
    end if
    end for
    
    return out
end function

global function bytesto16 (sequence s)
    return s[1] * #100 + s[2]
end function

global function bytesto32 (sequence s)
    return s[1] * #1000000 + s[2] * #10000 + s[3] * #100 + s[4]
end function

global function i16tobytes (integer i)
    return floor(i / #100) & remainder(i, #100)
end function

global function i32tobytes (integer i)
    return {floor(floor(i / #10000) / #100),
        remainder(floor(i / #10000), #100),
        floor(remainder(i, #10000) / #100),
        remainder(remainder(i, #10000), #100)}
end function

global procedure safe_proc (integer id, sequence args)
    if id > -1 then
    call_proc(id, args)
    end if
end procedure

global function make_SNAC (integer fam, integer sub, integer flag, atom req, sequence data)
    return i16tobytes(fam) &
       i16tobytes(sub) &
       i16tobytes(flag) &
       i32tobytes(req) &
       data
end function

global function make_FLAP (integer chan, atom seq, sequence data)
    return #2A &
       chan &
       i16tobytes(seq) &
       i16tobytes(length(data)) &
       data
end function

global function make_TLV (integer typ, sequence str)
    return i16tobytes(typ) &
       i16tobytes(length(str)) &
       str
end function

global function make_fragment (integer id, integer ver, sequence str)
    return id &
       ver &
       i16tobytes(length(str)) &
       str
end function


global function strip_html (sequence txt)
    sequence new, links, imgs, URL, tag
    integer in_tag, x, lnum

    new = ""
    tag = ""
    in_tag = 0
    x = 0
    lnum = 1
    
    links = {}
    imgs = {}
    
    for i = 1 to length(txt) do
    if txt[i] = '<' and not in_tag then
        in_tag = 1
        x = 0
        tag = ""
    elsif txt[i] = '>' and in_tag then
        in_tag = 0
    -- parsing the tag
    elsif in_tag = 1 and x = 0 then
        if txt[i] = ' ' then
        if equal(lower(tag), "a") then
            new &= sprintf("[%d]", lnum)
            lnum += 1
            x = 0
            tag = ""
        end if
        elsif txt[i] = '=' and equal(lower(tag), "href") then
        x = 1
        tag = ""
        else
        tag &= txt[i]
        end if
    -- parsing the HREF paramater of an anchor tag
    elsif in_tag = 1 and x = 1 then
        if txt[i] = ' ' then
        if tag[1] = '"' or tag[1] = '\'' then
            tag = tag[2..$ - 1]
        end if
        
        links = append(links, tag)
        
        x = 2
        end if
    elsif in_tag = 0 then
        new &= txt[i]
    end if
    end for
    
    return {new, links, imgs}
end function

