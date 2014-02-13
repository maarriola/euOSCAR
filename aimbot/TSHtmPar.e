--// TSHtmPar.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 4. August 2002.
--// HTML parser.
--// 
--// Why I wrote it:
--// - You can't parse HTML pages with XML parser
--//   because HTML pages don't have so strict syntax
--//   like XML does. For example, there is no closing </P>
--//   most of the time.
--// - I didn't find any HTML parser on the web
--//   which could be used in Euphoria easily.
--//   There are some Java and PHP HTML parsers,
--//   later I found out about libww which is in C
--//   but I already written a lot of this parser.
--// 
--// Main features:
--// - It's event based. Only three events exist:
--//   start tag, end tag and text event.
--// - It's good for very large HTML pages because
--//   main parsing routine continues where previous call
--//   to it left, so you can read HTML page
--//   byte by byte and call main parsing function in loop
--//   and each time pass the read character as parameter
--//   to it and it would work.
--//   You can of course use it as normal parser, to parse
--//   whole HTML page in one call.
--// - It can parse any HTML without reporting any errors,
--//   it never reports any errors.
--//   It's intended to be used to parse any HTML pages
--//   which are found on the internet.
--// - It supports unlimited number of HTML parsers to be running
--//   at the same time in same program.
--// - Speed: It wasn't my main concern. On Duron 700 MHZ 128 MB RAM:
--//   171 KB large HTML file was parsed in 0.65 seconds
--//   if whole page was passed as one string and
--//   so one call to parse() was made.
--//   If whole page was passed character by character and so
--//   parse() was called in loop it took 1.04 seconds.
--// 
--// 
--// Algorithm:
--// 
--// Because parse() has to continue where previous call to it left
--// it has a little different algorithm:
--// It uses a lot of global variables (global to this library)
--// which remember at which state is parser.
--// So this library could easily be made
--// to parse half of a very large html page,
--// save global variables on disk (in eds database),
--// turn off computer, read those global variables back from
--// disk and parse the other half of that html page.
--// Cool huh? :)





without type_check

--// TSLibrary include files:
include TSSeq.e
include TSMisc.e as misc
include TSDebug.e as debug
include TSError.e
include TSTypes.e
--// Standard include files:





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Variables and constants. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--// Number of all html parsers currently created.
integer Num_html_parsers
Num_html_parsers = 0

--// Html parser id.
type ID (integer id)
    return id >= 1 and id <= Num_html_parsers
end type

--// For use with 'START_TAG'.
constant TAGNAME = 1,
    TAG_PARAM_NAMES = 2,
    TAG_PARAM_VALS = 3

--// Start tag, should have this format:
--// 1. tag name, string
--// 2. tag parameters names, sequence with strings
--// 3. tag parameters values, sequence with strings
--//    matches with previous sequence.
type START_TAG (sequence s)
    return
	length (s) = 3 and
	is_string (s [TAGNAME]) and
	sequence (s [TAG_PARAM_NAMES]) and
	sequence (s [TAG_PARAM_VALS]) and
	length (s [TAG_PARAM_NAMES]) = length (s [TAG_PARAM_VALS])
end type

--// sequence which contains START_TAG types.
type START_TAG_LIST (sequence s)
    for i = 1 to length (s) do
	if not START_TAG (s [i]) then
	    return false
	end if
    end for
    return true
end type

--//
--// Word types:
--//=>
    constant
	--// Unknown.
	WORD_UNKNOWN = 0,
	--// Start tag name.
	WORD_START_TAG_NAME = 1,
	--// Tag parameter name.
	WORD_PARAM_NAME = 2,
	--// Tag parameter value.
	WORD_PARAM_VAL = 3,
	--// END TAG NAME.
	WORD_END_TAG_NAME = 6,
	--// "/" character after "<"
	WORD_SLASH = 7,
	--// "<" character
	WORD_LEFT_HTML_BRACE = 8,
	--// ">" character
	WORD_RIGHT_HTML_BRACE = 9,
	--// Text between previous and current tag.
	--// It doesn't matter if start or end tags.
	WORD_TEXT = 10
--//
--// Start tag types:
--//=>
    constant COMMENT = 1,
	SCRIPT = 2
--//
--// Global sequences which hold data
--// for all html parsers objects:
--//=>    
    --// For every html parser object:
    --// Id of routine which should be called
    --// when start tag is found,
    --// -1 if no event handler is set up.
    sequence Start_tag_routine
    --// For every html parser object:
    --// Id of routine which should be called
    --// when end tag is found,
    --// -1 if no event handler is set up.
    sequence End_tag_routine
    --// For every html parser object:
    --// Id of routine which should be called
    --// when text between two tags is found,
    --// -1 if no event handler is set up.
    sequence Text_routine
    --// For every html parser object:
    --// Current word we are completing, string.
    sequence Word_completing
    --// For every html parser object:
    --// Type of 'Word_completing',
    --// one of WORD_... constants, integer.
    sequence Word_completing_type
    --// For every html parser object:
    --// Previous word type, members are
    --// one of the WORD_... constants.
    sequence Prev_word_type
    --// For every html parser object:
    --// Current start tag we are completing.
    --// This is really START_TAG_LIST type
    --// but I have to keep it sequence else
    --// it crashes when appending...
    sequence Start_tag_completing
    --// For every html parser object:
    --// Previous character.
    sequence Previous_char
    --// For every html parser object:
    --// If we are at that stage of parser
    --// that we should ignore
    --// any whitespace we encounter.
    sequence Ignore_whitespace
    --// For every html parser object:
    --// String quote character, either '"' or '\''.
    --// It it's 0 that means we're not in string.
    sequence String_quote_char
    --// For every html parser object:
    --// What is type of start tag, only
    --// if it is important, else it is 0.
    --// It can be: COMMENT <!-- -->
    --// Or it can be SCRIPT.
    sequence Start_tag_type
    --// For every html parser object:
    --// String, last few characters that were
    --// passed to parse ().
    --// Length of it is equal or smaller to
    --// constant NUM_LAST_FEW_CHARS
    sequence Last_few_chars
    constant NUM_LAST_FEW_CHARS = 20

    Start_tag_routine = {}
    End_tag_routine = {}
    Text_routine = {}
    Word_completing = {}
    Word_completing_type = {}
    Prev_word_type = {}
    Start_tag_completing = {}
    Previous_char = {}
    Ignore_whitespace = {}
    String_quote_char = {}
    Start_tag_type = {}
    Last_few_chars = {}
    
    
    
    
    
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Local routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--// Called when complete start tag is got.
--// retruns true if to continue main parsing loop, false if to exit it
function end_start_tag (ID id)
    BOOL ret_val
    STRING tag_name
    sequence param_names, param_values
    ret_val = true
    tag_name = Start_tag_completing [id] [TAGNAME]
    --//
    --// Get 'Start_tag_type':
    --//=>
	if equal  (lower (tag_name), "script") then
	    Start_tag_type [id] = SCRIPT
	end if
    --//
    --// Call event handler:
    --//=>
	if Start_tag_routine [id] != -1 then
	    assert (length (tag_name) != 0)
	    param_names = Start_tag_completing [id] [TAG_PARAM_NAMES]
	    param_values = Start_tag_completing [id] [TAG_PARAM_VALS]
	    ret_val = call_func (Start_tag_routine [id], {tag_name, param_names, param_values})
	end if
    --//
    --// Prepare variables for next word:
    --//=>
	Start_tag_completing [id] = {"", {}, {}}
    return ret_val
end function

--// Called when start tag tag name is got.
procedure end_start_tag_name (ID id)
    STRING tag_name
    assert (length (Word_completing) != 0)
    tag_name = Word_completing [id]
    Start_tag_completing [id] [TAGNAME] = tag_name
    --//
    --// Get 'Start_tag_type':
    --//=>
	assert (Start_tag_type [id] = 0)
	if length (tag_name) >= length ("!--")
	and equal (tag_name [1 .. length ("!--")], "!--") then
	--// <!--, html comment
	    Start_tag_type [id] = COMMENT
	    Word_completing [id] = Word_completing [id] [length ("!--") .. length (Word_completing [id])]
	end if 
    --//
    --// Prepare variables for next word:
    --//=>
	Word_completing [id] = ""
	Prev_word_type [id] = Word_completing_type [id]
	Word_completing_type [id] = WORD_PARAM_NAME
	Ignore_whitespace [id] = true
end procedure

--// Called when end tag tag name is got.
--// retruns true if to continue main parsing loop, false if to exit it
function end_end_tag_name (ID id)
    STRING end_tag_name
    BOOL ret_val
    assert (length (Word_completing) != 0)
    ret_val = true
    end_tag_name = Word_completing [id]
    --//
    --// Call event handler:
    --//=>
	if End_tag_routine [id] != -1 then
	    ret_val = call_func (End_tag_routine [id], {end_tag_name})
	end if
    --//
    --// Prepare variables for next word:
    --//=>
	Word_completing [id] = ""
	Prev_word_type [id] = Word_completing_type [id]
	Word_completing_type [id] = WORD_TEXT
	Ignore_whitespace [id] = true
    return ret_val
end function

--// Called when parameter name in start tag is got.
procedure end_param_name (ID id)
    assert (length (Word_completing [id]) != 0)
    Start_tag_completing [id] [TAG_PARAM_NAMES] = append (
	Start_tag_completing [id] [TAG_PARAM_NAMES], "")
    Start_tag_completing [id] [TAG_PARAM_VALS] = append (
	Start_tag_completing [id] [TAG_PARAM_VALS], "")
    Start_tag_completing [id] [TAG_PARAM_NAMES]
	[length (Start_tag_completing [id] [TAG_PARAM_NAMES])] = 
	    Word_completing [id]
    --//
    --// Prepare variables for next word:
    --//=>
	Word_completing [id] = ""
	Prev_word_type [id] = Word_completing_type [id]
	Word_completing_type [id] = WORD_PARAM_NAME
	Ignore_whitespace [id] = true
end procedure

--// Called when parameter value in start tag is got.
procedure end_param_value (ID id)
    assert (length (Word_completing [id]) != 0)
    Start_tag_completing [id] [TAG_PARAM_VALS]
	[length (Start_tag_completing [id] [TAG_PARAM_VALS])] = 
	    Word_completing [id]
    --//
    --// Prepare variables for next word:
    --//=>
	Word_completing [id] = ""
	Prev_word_type [id] = Word_completing_type [id]
	Word_completing_type [id] = WORD_PARAM_NAME
	Ignore_whitespace [id] = true
end procedure

--// Called when text between current and
--// previous tag is got. (start or end tags)
function end_text (ID id)
    BOOL ret_val
    STRING text
    ret_val = true
    text = Word_completing [id]
    --//
    --// Call event handler:
    --//=>
	if Text_routine [id] != -1 and length (text) then
	    ret_val = call_func (Text_routine [id], {text})
	end if
    --//
    --// Prepare variables for next word:
    --//=>
	Word_completing [id] = ""
	Prev_word_type [id] = Word_completing_type [id]
	Word_completing_type [id] = WORD_UNKNOWN
	Ignore_whitespace [id] = true
    return ret_val
end function

--// Called when unknown word is got, we find out what is this
--// word type from variable 'Word_completing_type [id]'.
--// retruns true if to continue main parsing loop, false if to exit it
function end_unknown_word (ID id)
    if length (Word_completing [id]) = 0 then
	return true
    end if
    if Word_completing_type [id] = WORD_START_TAG_NAME then
	end_start_tag_name (id)
    elsif Word_completing_type [id] = WORD_PARAM_NAME then
	end_param_name (id)
    elsif Word_completing_type [id] = WORD_PARAM_VAL then
	end_param_value (id)
    elsif Word_completing_type [id] = WORD_END_TAG_NAME then
	return end_end_tag_name  (id)
    elsif Word_completing_type [id] = WORD_TEXT then
	return end_text (id)
    end if
    return true
end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- new_html_parser [Created on 4. August 2002, 05:16]
-- The 'new_html_parser' function creates new HTML
-- parser object.
--
-- RETURN VALUES
-- Html parser id which you use as first parameter
-- in all global routines in this library.
--*/
global function new_html_parser ()
    ID id
    Num_html_parsers += 1
    id = Num_html_parsers
    --//
    --// Advance global sequences:
    --//=>
	Start_tag_routine = append (Start_tag_routine, -1)
	End_tag_routine = append (End_tag_routine, -1)
	Text_routine = append (Text_routine, -1)
	Word_completing = append (Word_completing, "")
	Word_completing_type = append (Word_completing_type, WORD_TEXT)
	Prev_word_type = append (Prev_word_type, WORD_UNKNOWN)
	Start_tag_completing = append (Start_tag_completing, {"", {}, {}})
	Previous_char = append (Previous_char, 0)
	Ignore_whitespace = append (Ignore_whitespace, false)
	String_quote_char = append (String_quote_char, 0)
	Start_tag_type = append (Start_tag_type, 0)
	Last_few_chars = append (Last_few_chars, "")
    return id
end function

--/*
-- set_start_tag_routine [Created on 4. August 2002, 05:08]
-- The 'set_start_tag_routine' procedure sets which
-- routine should be called when start tag is found
-- (<FONT>, <A>, ...)
-- Comment <!-- --> and <PRE> tag
-- have no parameters, allways.
--
-- PARAMETERS
-- 'id'
--    Id of Html parser, return value from 'new_html_parser ()'.
-- 'routineid'
--    Id of routine to be called.
--    It should have this format:
--    function on_start_tag (STRING tag_name, sequence param_names,
--         sequence param_values)
--    Should return true if to continue main parsing loop,
--    false if to stop it.
--    'tag_name' is the name of tag ("FONT", "A", "BR", ...)
--    'param_names' is sequence with strings, tag parameters names.
--                  ("face", "href", ...)
--    'param_values' is sequence with strings, tag parameters values,
--                   value for every  parameter in 'param_names'.
--                   ("Times New Roman", "http://www.cnn.com", ...)
---    For html comments <!-- --> tag name is !-- and it has only one
--     parameter with no value, first parameter name
--     is all text inside html comment.
--
--*/
global procedure set_start_tag_routine (ID id, integer routineid)
    Start_tag_routine [id] = routineid
end procedure

--/*
-- set_end_tag_routine [Created on 4. August 2002, 05:11]
-- The 'set_end_tag_routine' procedure sets which
-- routine should be called when end tag is found
-- (</FONT>, </A>, ...)
--
-- PARAMETERS
-- 'id'
--    Id of Html parser, return value from 'new_html_parser ()'.
-- 'routineid'
--    Id of routine to be called.
--    It should have this format:
--    function on_end_tag (STRING tag_name)
--    Should return true if to continue main parsing loop,
--    false if to stop it.
--   'tag_name' is the name of tag ("FONT", "A", ...)
--*/
global procedure set_end_tag_routine (ID id, integer routineid)
    End_tag_routine [id] = routineid
end procedure

--/*
-- set_text_routine [Created on 4. August 2002, 05:12]
-- The 'set_text_routine' procedure sets which
-- routine should be called when start or end tag is found,
-- to return data which was between that tag and previous tag,
-- excluding both tags.
--
-- PARAMETERS
-- 'id'
--    Id of Html parser, return value from 'new_html_parser ()'.
-- 'routineid'
--    Id of routine to be called.
--    It should have this format:
--    function on_data (STRING data)
--    Should return true if to continue main parsing loop,
--    false if to stop it.
--    'data' is data which was between current tag (start or end)
--    end previous tag (start or end).
--*/
global procedure set_text_routine (ID id, integer routineid)
    Text_routine [id] = routineid
end procedure

--/*
-- parse [Created on 4. August 2002, 05:26]
-- The 'parse' procedure parses part or all of html text.
-- You can call it in loop or just once with whole html text.
-- You can for example read very large html page by
-- 256 bytes and call this function with those bytes
-- in a loop and it would work.
-- Next call continues where previous call of this function left.
-- You have to call 'restart()' to start from fresh.
--
-- This function is synchronous and not asynchronous.
-- That means it doesn't return immedateley but
-- only when page was parsed.
--
-- PARAMETERS
-- 'id'
--    Id of Html parser, return value from 'new_html_parser ()'.
-- 'text'
--    Html text to parse.
--*/
global procedure parse (ID id, STRING text)
    char c, prevc --// current and previous character
    integer ignore_char_pos
    BOOL do_continue
    STRING comment_text
    prevc = Previous_char [id]
    --// The main loop of this library.
    for i = 1 to length (text) do
	c = text [i]
	if String_quote_char [id] != 0 then
	--// We are inside a string.
	--// String which needs to be completed, we are looking for
	--// """ or "'" character which ends string.
	    assert (Word_completing_type [id] = WORD_PARAM_NAME
		or Word_completing_type [id] = WORD_PARAM_VAL)
	    if c = String_quote_char [id] and prevc != '\\' then
	    --// Found end of string.
		if length(Word_completing[id]) = 0 then
		    Word_completing[id] = " "
		end if
		do_continue = end_unknown_word (id)
		String_quote_char [id] = 0
		if not do_continue then
		    exit
		end if
	    else
	    --// character inside of string
		Word_completing [id] &= c
	    end if
	elsif Start_tag_type [id] = COMMENT then
	--// Ignore everything inside html comment <!-- -->
	    if c = '>' then
		Start_tag_type [id] = 0
		comment_text = Word_completing [id]
		--// Remove characters if any.
		if equal (right_safe (comment_text, length ("--")), "--") then
		    comment_text = comment_text [1 .. length (comment_text) - length ("--")]
		end if
		Start_tag_completing [id] = {"!--", {comment_text}, {""}}
		do_continue  = end_start_tag (id)
		Word_completing_type [id] = WORD_TEXT
		Word_completing [id] = ""
		if not do_continue then
		    exit
		end if
	    else
		Word_completing [id] &= c
	    end if
	elsif Start_tag_type [id] = SCRIPT then
	--// Everything after <SCRIPT> tag is text
	--// until we find "</SCRIPT>".
	    if equal (lower (right_safe (Last_few_chars [id], length ("</script>"))), "</script>") then
	    --// We found "</script>", this is end of string.
	    --// There could a problem be if in javascript code
	    --// there is something like this: var myvar = "</script>".
	    --// This should be ignored but I didn't bother
	    --// as I saw Internet Explorer 6.0 didn't 
	    --// check that either.
		--// Remove "</script>" from end of 'Word_completing [id]'
		Word_completing [id] = Word_completing [id] [1 .. length (Word_completing [id]) - length ("</script>")]
		do_continue = end_text (id)
		Word_completing_type [id] = WORD_END_TAG_NAME
		Word_completing [id] = "script"
		do_continue = end_end_tag_name (id) and do_continue
		Start_tag_type [id] = 0
		if not do_continue then
		    exit
		end if
	    else
		Word_completing [id] &= c
	    end if
	elsif isspace (c) and
	Word_completing_type [id] != WORD_TEXT then
	    if Ignore_whitespace [id] = false then
		do_continue = end_unknown_word (id)
		if not do_continue then
		    exit
		end if
	    end if
	elsif c = '<' then
	    do_continue = end_unknown_word (id)
	    if not do_continue then
		exit
	    end if
	    Prev_word_type [id] = WORD_LEFT_HTML_BRACE
	    --// For now we assume it's start tag,
	    --// if we find "/" as next character
	    --// then it's end tag name
	    Word_completing_type [id] = WORD_START_TAG_NAME
	    Ignore_whitespace [id] = true
	elsif c = '>' then
	    do_continue = end_unknown_word (id)
	    Word_completing_type [id] = WORD_TEXT
	    if not do_continue then
		exit
	    end if
	    Prev_word_type [id] = WORD_RIGHT_HTML_BRACE
	    if length (Start_tag_completing [id] [TAGNAME]) > 0 then
	    --// We are inside start tag and it has ended now.
		do_continue = end_start_tag (id)
		if not do_continue then
		    exit
		end if
	    end if
	elsif c = '/'
	and Prev_word_type [id] = WORD_LEFT_HTML_BRACE then
	--// "</"
	    assert (Word_completing_type [id] = WORD_START_TAG_NAME)
	    do_continue = end_unknown_word (id)
	    if not do_continue then
		exit
	    end if
	    Prev_word_type [id] = WORD_SLASH
	    Word_completing_type [id] = WORD_END_TAG_NAME
	elsif Word_completing_type [id] = WORD_PARAM_NAME
	    and c = '=' then
	    if not isspace (Previous_char [id]) then
		end_param_name (id)
	    end if
	    Word_completing_type [id] = WORD_PARAM_VAL
	elsif Word_completing_type [id] = WORD_PARAM_VAL
	or Word_completing_type [id] = WORD_PARAM_NAME
	and (c ='"' or c = '\'') then
	--// Starting string character of parameter name or value.
	    String_quote_char [id] = c
	else --// this character is probably part of word we are completing
	    if Word_completing_type [id] = WORD_PARAM_VAL
	    and length (Word_completing [id]) = 0 and c = '=' then
	    --// this is first "=" character after parameter name, ignore it
		--// do nothing
	    else
	    --// this is NOT first "=" character after parameter name
		Ignore_whitespace [id] = false
		Word_completing [id] &= c
	    end if
	end if
	Last_few_chars [id] &= c
	Last_few_chars [id] = ensure_short_cut_front (Last_few_chars [id], NUM_LAST_FEW_CHARS)
	assert (length (Last_few_chars [id]) <= NUM_LAST_FEW_CHARS)
	Previous_char [id] = c
    end for    
end procedure

--/*
-- restart [Created on 4. August 2002, 05:29]
-- The 'restart' procedure restarts parser.
-- When you call 'parse()' it continues
-- where previous call to 'parse()'
-- left. After you call this function
-- you can start parsing new page for example.
-- When you come to end of page and want
-- to start parsing new page you have to call this
-- function else unpredictable results may happen.
--
-- PARAMETERS
-- 'id'
--    Id of Html parser, return value from 'new_html_parser ()'.
--*/
global procedure restart (ID id)
    Word_completing [id] = ""
    Word_completing_type [id] = WORD_TEXT
    Prev_word_type [id] = WORD_UNKNOWN
    Start_tag_completing [id] = {"", {}, {}}
    Previous_char [id] = 0
    Ignore_whitespace [id] = false
    String_quote_char [id] = 0
    Start_tag_type [id] = 0
    Last_few_chars [id] = ""
end procedure
