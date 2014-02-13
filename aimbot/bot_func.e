include std/socket.e as slib
include std/net/http.e as http
include std/net/dns.e as dns
include html.e

constant SESS_USER_NAME     = 1,
		 SESS_WIKI_SITE     = 2,
		 SESS_WIKI          = 3,
		 SESS_CUR_PAGE      = 4,
		 SESS_LAST_SEARCH   = 5,
		 SESS_HEADERS       = 6,
		 SESS_LINKS         = 7,
		 SESS_TABLES        = 8,
		 SESS_LAST_TIME     = 9,
		 SESS_HAS_NEWLINE   = 10,
		 SESS_LAST_SESSION  = 11,
		
		 SESSION_TIMEOUT    = 300,
     
	 wiki_sites = {"wikipedia", "wiktionary", "wikibooks",
		       "wikinews", "wikiversity", "wikispecies",
		       "wikisource", "wikiquote"}

sequence session, msg
integer msg_parser

session = {}
msg = {}

-- notify all users with open sessions of the crash
function bot_error (object x)
    integer fn
    object ln
    atom t
    
    fn = open("ex.err", "r")
    ln = {gets(fn), gets(fn)}
    close(fn)

    ln[1] = ln[1][1..$ - 1]
    ln[2] = ln[2][1..$ - 1]

    for i = 1 to length(session) do
		--send_message(server[2], session[i][SESS_USER_NAME], "fatal error: \n" & ln[1] & ln[2])
		send_message(session[i][SESS_USER_NAME], "fatal error: \n" & ln[1] & ln[2])
    end for
    
    t = time() + 5
    while time() < t do end while
    
    slib:close(server)
    
    return 0
end function

procedure session_cleanup ()
    sequence pruned

    pruned = {}
    
    for i = 1 to length(session) do
		if time() < session[i][SESS_LAST_TIME] + SESSION_TIMEOUT then
			pruned = append(pruned, session[i])
		end if
    end for
    
    session = pruned
end procedure

function get_session (sequence user)
    integer sessID
    
    sessID = 0
    
    session_cleanup()

    for i = 1 to length(session) do
		if compare_name(session[i][SESS_USER_NAME], user) then
			sessID = i
			exit
		end if
    end for
    
    if sessID then
		return sessID
    else
		session = append(session, {user, "en.wikipedia.org", {}, 0, "", {}, {}, {}, time(), 0, {}})
		return length(session)
    end if
end function

function convert_nonalphanum (sequence str)
    sequence out
    out = ""
    
    for i = 1 to length(str) do
		if isalnum(str[i]) then
			out &= str[i]
		else
			out &= sprintf("%%%02x", str[i])
		end if
    end for

    return out
end function

procedure load_wiki (sequence sock, sequence from, sequence w_mode, sequence url)
    sequence out, sess_last
    object file, addr
    integer c, sessID
    
    sessID = get_session(from)
    sess_last = session[sessID]

    url = "http://" & session[sessID][SESS_WIKI_SITE] & "/w/index.php?" & w_mode & "=" &
			convert_nonalphanum(url) &
			"&go=Go&printable=yes"

    puts(1, "retrieving " & url & "...")
	file = http_get(url)
	if sequence(file) then
	    puts(1, "parsing\n")
	    out = parse_html_page(file[2])
	    session[sessID][SESS_HEADERS] = out[2]
	    session[sessID][SESS_LINKS] = out[3]
	    session[sessID][SESS_TABLES] = out[4]
	    out = out[1]

	    if length(out) > max_message_size then
			session[sessID][SESS_WIKI] = {}
			for i = 1 to length(out) by max_message_size do
				c = i + max_message_size - 1
				if c > length(out) then c = length(out) end if
				session[sessID][SESS_WIKI] = append(session[sessID][SESS_WIKI], out[i..c])
			end for
	    else
			session[sessID][SESS_WIKI] = {out}
	    end if

	    session[sessID][SESS_LAST_SESSION] = sess_last
	    session[sessID][SESS_CUR_PAGE] = 1
	    send_message(from, session[sessID][SESS_WIKI][1], 1)
	else
		? file
	    puts(1, "failed\n")
	    send_message(from, "unable to access page")
	end if
end procedure

procedure goto_page (sequence sock, sequence from, sequence page)
    integer sessID
    
    sessID = get_session(from)

    page = value(page)
    if page[1] = GET_SUCCESS then
		session[sessID][SESS_CUR_PAGE] = page[2]
		send_message(from, session[sessID][SESS_WIKI][page[2]])
    end if
end procedure

procedure next_page (sequence sock, sequence from)
    integer sessID, cur
    
    sessID = get_session(from)
    cur = session[sessID][SESS_CUR_PAGE]

    if length(session[sessID][SESS_WIKI]) > cur then
		cur += 1
		send_message(from, session[sessID][SESS_WIKI][cur])
		session[sessID][SESS_CUR_PAGE] = cur
    else
		send_message(from, "you are on the last page")
    end if
end procedure

procedure repeat_page (sequence sock, sequence from)
    integer sessID
    
    sessID = get_session(from)

    if session[sessID][SESS_CUR_PAGE] then
		send_message(from, session[sessID][SESS_WIKI]
							[session[sessID][SESS_CUR_PAGE]])
    end if
end procedure

procedure find_in_page (sequence sock, sequence from, sequence phrase)
    sequence pages, out
    integer sessID
    
    sessID = get_session(from)

    phrase = lower(phrase)
    pages = {}
    
    for i = 1 to length(session[sessID][SESS_WIKI]) do
		if match(phrase, lower(session[sessID][SESS_WIKI][i])) then
			pages &= i
		end if
    end for

    if length(pages) then
		out = "found: "
		for i = 1 to length(pages) do
			out &= sprintf("%d ", pages[i])
		end for
		send_message(from, out)
    else
		send_message(from, "phrase not found")
    end if
end procedure

procedure table_of_contents (sequence sock, sequence from)
    sequence headers, out
    integer sessID
    
    sessID = get_session(from)
    headers = session[sessID][SESS_HEADERS]

    out = ""
    
    for i = 1 to length(headers) do
		out &= sprintf("%s, %d", headers[i])
		if i < length(headers) then out &= "; " end if
    end for

    send_message(from, out)
end procedure

procedure view_table (sequence sock, sequence from, sequence page)
    integer sessID
    
    sessID = get_session(from)
    
    page = value(page)
    if page[1] = GET_SUCCESS and
       page[2] > 0 and
       page[2] <= length(session[sessID][SESS_TABLES]) then
		send_message(from, session[sessID][SESS_TABLES][page[2]], 1)
    end if
end procedure

procedure change_site (sequence sock, sequence from, sequence site)
    integer sessID

    sessID = get_session(from)

    if not find(site, wiki_sites) then
		msg = "available sites: "
		for i = 1 to length(wiki_sites) do
			msg &= wiki_sites[i] & ", "
		end for
		send_message(from, msg[1..$ - 2])
    else
		session[sessID][SESS_WIKI_SITE] = "en." & lower(msg[3..$]) & ".org"
		send_message(from, site & " ok")
    end if
end procedure

procedure goto_link (sequence sock, sequence from, sequence id)
    sequence links
    integer sessID
    
    sessID = get_session(from)
    links = session[sessID][SESS_LINKS]
    
    id = value(id)
    if id[1] = GET_SUCCESS and id[2] >= 1 and id[2] <= length(links) then
		load_wiki(sock, from, "title", links[id[2]])
    else
		if length(links) then
			send_message(from, sprintf("links range from 1 to %d", length(links)))
		else
			send_message(from, "no links")
		end if
    end if
end procedure

procedure go_back (sequence sock, sequence from)
    sequence sess_cur, sess_last
    integer sessID
    
    sessID = get_session(from)
    sess_cur = session[sessID]
    sess_last = sess_cur[SESS_LAST_SESSION]
    sess_last[SESS_LAST_TIME] = time()
    sess_last[SESS_LAST_SESSION] = sess_cur
    
    session[sessID] = sess_last
end procedure

procedure help (sequence sock, sequence from)
    send_message(from, "usage: " &
			   "w [page] - navigate to [page] / "&
			   "s [phrase] - search for [phrase] / "&
			   "n - next page / "&
			   "r - repeat page / "&
			   "b - go to last page / "&
			   "p [n] - go to page [n] / "&
			   "l [n] - go to link [n] / "&
			   "f [phrase] - find [phrase] in current wiki / "&
			   "c - show table of contents / "&
			   "t [n] - see table [n]")
end procedure

function msg_text (sequence str)
    msg &= str

    return 1
end function

procedure bot_msg(sequence from, sequence text)
    printf(1, "%s: '%s'\n", {from, text})
    
    for i = 1 to length(session) do
		if compare_name(session[i][SESS_USER_NAME], from) then
			session[i][SESS_LAST_TIME] = time()
			exit
		end if
    end for
    
    if match("<html>", lower(text)) = 1 then
		msg = ""
		restart(msg_parser)
		parse(msg_parser, text)
    else
		msg = text
    end if
    
    if match("w ", lower(msg)) = 1 then
		load_wiki(server[2], from, "title", msg[3..$])

    elsif match("s ", lower(msg)) = 1 then
		load_wiki(server[2], from, "search", msg[3..$])
    
    elsif match("p ", lower(msg)) then
		goto_page(server[2], from, msg[3..$])

    elsif equal("n", lower(msg)) then
		next_page(server[2], from)

    elsif equal("r", lower(msg)) then
		repeat_page(server[2], from)

    elsif equal("b", lower(msg)) then
		go_back(server[2], from)

    elsif match("f ", lower(msg)) = 1 then
		find_in_page(server[2], from, msg[3..$])

    elsif equal("c", lower(msg)) then
		table_of_contents(server[2], from)
    
    elsif match("t ", lower(msg)) = 1 then
		view_table(server[2], from, msg[3..$])
    
    elsif match("g ", lower(msg)) = 1 then
		change_site(server[2], from, lower(msg[3..$]))

    elsif match("l ", lower(msg)) = 1 then
		goto_link(server[2], from, msg[3..$])
    
    elsif equal("kebert xela", lower(msg)) then
		? 1 / 0

    elsif equal(lower(msg), "h") then
		help(server[2], from)
    end if
end procedure

msg_hook = routine_id("bot_msg")
msg_parser = new_html_parser()
set_text_routine(msg_parser, routine_id("msg_text"))
crash_routine(routine_id("bot_error"))
