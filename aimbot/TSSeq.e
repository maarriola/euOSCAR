




--// TSLibrary_Sequence.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 28. August 2002.
--// This is library which has miscalenous
--// routines for manipulating and parsing
--// sequences and strings.





--// TSLibrary include files:
include TSMath.e
include TSDebug.e
include TSError.e
include TSCustom.e
include TSTypes.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global constants. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// Search direction.    
global constant
    SEARCH_RIGHT = 1,
    SEARCH_LEFT = -1
    
    
    
    
    
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global Routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- get_member_default [Created on 2. August 2002, 02:32]
-- The 'get_member_default' function tries to get member from sequence
-- at specified position. If position is out of bounds
-- it returns default value which you specified.
-- Also, if value as position in sequence is equal to
-- value of 'must_not_be' then 'default_value' is returned.
--
-- PARAMETERS
-- 's'
--    sequence to get one member from.
-- 'pos'
--    At this position in sequence is member we will get.
-- 'must_not_be'
--    If value which would be returned is equal to this then
--    default value is returned.
--    This can be UNDEFINED, then it's ignored.
-- 'default_value'
--    Default value to return if no member is at that position
--    in sequence or if member value is not right.
--
-- RETURN VALUES
-- Member at position or default value.
--*/
global function get_member_default (sequence s, integer pos,
    object must_not_be, object default_value)
    if pos >= 1 and pos <= length (s) then
        if not equal (s [pos], must_not_be) then
            return s [pos]
        else
            return default_value
        end if
    else
        return default_value
    end if
end function

--/*
-- find_ex [Created on 27. November 2001, 15:45]
-- The 'find_ex' function find an object in sequence 
-- starting from a given position.
--
-- PARAMETERS
-- 'x'
--    This object finding.
-- 's'
--    Searching in this sequence.
-- 'params'
--    Additional advanced parameters.
--    Can be {} to use default value.
--    It can be partially filled.
--    Any value can be 'DEFAULT' to use default value.
--    Structure is:
--    1. Start position.
--       At this position starting search (including).
--       Default is 1.
--    2. Search direction.
--       In which direction to search.
--       Should be one of following constants:
--       - SEARCH_RIGHT
--         Searches from left to right.
--       - SEARCH_LEFT
--         Searches from right to left.
--       Default is SEARCH_RIGHT.
--     3. Which occurance of 'x'
--        should we find in 's'.
--        Default is 1 (first occurance). 
--
-- RETURN VALUES
-- Position of 'x' is 's' if found.
--
-- 0 if not found.
--*/
global function find_ex (object x, sequence s, sequence params)
    --// Current position in 's'.
    integer current_pos
    integer from_pos, direction, occurance
    integer num_found
    --//
    --// Get params:
    --//=>
        from_pos = get_member_default (params, 1, DEFAULT, 1)
        direction = get_member_default (params, 2, DEFAULT, SEARCH_RIGHT)
        occurance = get_member_default (params, 3, DEFAULT, 1)
    current_pos = from_pos
    num_found = 0
    --// Loop until 'x' is found or we get to end of sequence 's'.
    while 1 do
        if current_pos > length (s) or current_pos < 1 then --// We have searched whole string.
            exit
        end if
        if equal (s [current_pos], x) then
            num_found += 1
            if num_found = occurance then
            --// This is the occurance of 'x' in 's' we were searching.
                return current_pos
            end if
        end if
        current_pos += direction
    end while
    return 0
end function
--//
--// Tests for 'find_ex()':
--//=>
    --// Tmp = find_ex ('c', "abcdefgh", {})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 3)

    --// Tmp = find_ex ('c', "abcdefgh", {4})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 0)

    --// Tmp = find_ex ('c', "abcdefgh", {3})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 3)

    --// Tmp = find_ex ('c', "abcdefgh", {length ("abcdefgh"), SEARCH_LEFT})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 3)

    --// Tmp = find_ex ('c', "abcdcfgh", {DEFAULT, DEFAULT, 2})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 5)

    --// Tmp = find_ex ('c', "abcdcfgh", {DEFAULT, DEFAULT, 1})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 3)

    --// Tmp = find_ex ('c', "abcdcfgh", {length ("abcdefgh"), SEARCH_LEFT, 2})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 3)

    --// Tmp = find_ex ('c', "abccccc", {DEFAULT, DEFAULT, 4})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 6)

    --// Tmp = find_ex ('c', "abccccc", {length ("abccccc"), SEARCH_LEFT, 1})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 7)

    --// Tmp = find_ex ('c', "c", {})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 1)

    --// Tmp = find_ex ('c', "cc", {3})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 0)

    --// Tmp = find_ex ('c', "", {3})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 0)

    --// Tmp = find_ex ('c', "", {})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 0)

    --// Tmp = find_ex ('c', "ab", {})
    --// show ("Tmp", Tmp)
    --// assert (Tmp = 0)

    --// wait ()
    --// abort (0)

--/*
-- match_from_pos [Created on 26. July 2002, 13:32]
-- The 'match_from_pos' function matches string from positon.
-- This function is only useful for very long strings,
-- for shorter built-in match() is faster.
--
-- PARAMETERS
-- 'what'
--    This finding.
-- 'in'
--    In this string.
-- 'start_pos'
--    Start position, going only forward.
--
-- RETURN VALUES
-- Position or 0 if not found.
--*/
global function match_from_pos (sequence what, sequence in, integer start_pos)
    integer j
    for i = start_pos to length (in) do
        j = 1
        while true do
            --// if not equal (what [j], in [i + j - 1]) then
            if what [j] != in [i + j - 1] then
                exit
            end if
            if j = length (what) then
            --// All members do match, we found match.
                return i
            end if
            j += 1
        end while
    end for
    return 0
end function

--/*
-- trim_char_front [Created on 7. July 2002, 00:56]
-- The 'trim_char_front' function removes character at
-- front if it is equal to the one you specified.
--
-- PARAMETERS
-- 's'
--    .
-- 'c'
--    .
--
-- RETURN VALUES
-- String.
--*/
global function trim_char_front (STRING s, CHAR c)
    if s [1] = c then
        return s [2 .. length (s)]
    end if
end function

--/*
-- trim_front [Created on 7. August 2002, 06:35]
-- The 'trim_front' function removes all characters
-- at front of string if they match character you specify.
--
-- Example:
-- "//string//" returns "string//"
--
-- PARAMETERS
-- 's'
--    .
-- 'c'
--    .
--
-- RETURN VALUES
-- .
--*/
global function trim_front (STRING s, CHAR c)
    integer i
    i = 1
    while s [i] = c do
        i += 1
    end while
    return s [i .. length (s)]
end function

--// Tests for trim_front():
--// Tmp = trim_front ("//string//", '/')
--// assert (equal (Tmp, "string//"))
--// Tmp = trim_front ("///////string//", '/')
--// assert (equal (Tmp, "string//"))
--// Tmp = trim_front ("string//", '/')
--// assert (equal (Tmp, "string//"))

--/*
-- trim_front [Created on 7. August 2002, 06:35]
-- The 'trim_front' function removes all characters
-- at back of string if they match character you specify.
--
-- Example:
-- "//string//" returns "//string"
--
-- PARAMETERS
-- 's'
--    .
-- 'c'
--    .
--
-- RETURN VALUES
-- .
--*/
global function trim_back (STRING s, CHAR c)
    integer i
    i = length (s)
    while 1 do
        if i < 1 then
            exit
        end if
        if s [i] != c then
            exit
        end if
        i -= 1
    end while
    return s [1 .. i]
end function

--/*
-- remove_member [Created on 4. October 2001, 16:36]
-- The 'remove_member' function removes a member with index 'index' from sequence 's'.
--
-- PARAMETERS
-- 'index'
--    Index of the member to be removed.
--
-- 's'
--    Sequence from which to remove one member.
--
-- RETURN VALUES
-- Sequence 's' with one element removed.
--
-- REMRAKS
-- If index is out of range, the original sequence is returned. This functiion never fails.
--
--*/
global function remove_member (integer index, sequence s)
    if index < 1 or index > length (s) then --// Index is out of range.
        return s
    end if
    if index = length (s) then  --// Trying to remove last member from sequence.
        return s  [1 .. length (s) - 1]
    else                        --// Not trying to remove last member from sequence.
        return s  [1 .. index - 1] & s  [index + 1 .. length (s)]
    end if
end function

--/*
-- remove_last_member [Created on 23. November 2001, 18:32]
-- The 'remove_last_member' function removes last member of a sequence.
--
-- PARAMETERS
-- 's'
--    Sequence from which to remove last member.
--
-- RETURN VALUES
-- Sequence with removed last member.
-- If sequence was empty then empty sequence is returned.
--
--*/
global function remove_last_member (sequence s)
    if length (s) != 0 then --// Sequence is not empty.
        return s [1 .. length (s) - 1]
    else                    --// Sequence is empty.
        return {}
    end if
end function

--/*
-- insert_member [Created on 23. November 2001, 14:56]
-- The 'insert_member' function insert an object into sequence.
--
-- PARAMETERS
-- 'x'
--    This object is inserted.
-- 's'
--    In this sequence inserted.
-- 'after'
--    Index after which member in sequence to insert.
--
-- RETURN VALUES
-- Sequence with inserted object.
--
--*/
global function insert_member (object x, sequence s, integer after)
    if after >= length (s) then
        return append (s, x)
    else
        return append (s [1 .. after], x) & s [after + 1 .. length (s)]
    end if
end function

--// finds string in sequence with strings,  case is irrelavant
--// returns index where in s found or 0 if not found
global function findstr_nocase (sequence str, STRING_LIST s, integer from)
    sequence str_lower
    str_lower = lower (str)
    for i = from to length (s) do
	    if equal (str_lower, lower (s [i])) then            
	        return i
	    end if
    end for
    return 0
end function

--/*
-- ensure_short_cut_front [Created on 7. October 2001, 01:35]
-- The 'ensure_short_cut_front' function ensures that sequence 's' is not longer that 'how_short'.
-- If it is longer than some excessive members are cut from the front.
-- PARAMETERS
-- 's'
--    Sequence to be checked for length and cut if necessary.
-- 'how_short'
--    How short should sequence be. If it is same long or shorter than this number it's ok.
--
-- RETURN VALUES
-- Cut or unchanged sequence.
--
--*/
global function ensure_short_cut_front (sequence s, integer how_short)
    if length (s) > how_short then --// Sequence is too big.
        return s[length (s) - how_short + 1 .. length (s)]
    end if
    return s
end function

--/*
-- sequence_to_string [Created on 8. October 2001, 22:06]
-- The 'sequence_to_string' function converts Euphoria sequence to string.
--
-- PARAMETERS
-- 's'
--    Sequence to be convereted to string.
--
-- RETURN VALUES
-- Sequence 's' converted to string. Curly braces mark sequences within sequences.
--
-- REMARKS
-- sequence {"string", 1, 2, 3, 4, {5, 6}, {}}
-- is converted to string:
-- "{{115, 116, 114, 105, 110, 103}, 1, 2, 3, 4, {5, 6}, {}}"
--
--*/
global function sequence_to_string (sequence s)
    --// One member of sequence.
    object member
    --// String returned.
    STRING string
    string = "{"
    --// Loop each member of sequence.
    for i = 1 to length (s) do
        member = s [i]
        if atom (member) then   --// Member is atom (number).
            string &= sprintf ("%d", member)
        else                    --// Member is sequence.
            string &= sequence_to_string (member)
        end if
        if i < length (s) then --// This is not last member, so add comma, to separate this member from next member.
            string &= ", "
        end if
    end for
    string &= "}"
    return string
end function

--/*
-- string_to_sequence [Created on 8. October 2001, 22:20]
-- The 'string_to_sequence' function converts string to Euphoria sequence.
-- Everywhere where there are curly braces {} in string, content inside them is considered as
-- one sequence.
--
-- PARAMETERS
-- 'string'
--    String to be converted to sequence.
--
-- RETURN VALUES
-- If success, euphoria sequence.
--
-- If failure, atom.
--
--*/
global function string_to_sequence (STRING string)
    --// Result of 'value ()'.
    sequence value_result
    value_result = value (string)
    if value_result [1] != GET_SUCCESS then --// Error.
        error ("Converting string \"" & string & "\" to sequence failed.")
        return 0
    else                                    --// Success.
        return value_result [2]
    end if
end function

--/*
-- is_sequence_mixed_string [Created on 14. October 2001, 23:57]
-- The 'is_sequence_mixed_string' function finds out if sequence is a mixed string.
-- Mmixed string is a string which has both characters and non-characters inside itself.
-- It has no sequences.
--
-- PARAMETERS
-- 's'
--    Sequence to be checked.
--
-- RETURN VALUES
-- 0 if not string at all.
--
-- 1 if it is mixed sequence.
--
-- 2 if it is not mixed sequence, but pure string.
--
-- 3 if it is not mixed sequence, but there are only non-letters in it.
--
--*/
global function is_sequence_mixed_string (sequence s)
    --// One member of 's'.
    object member
    --// Was a character fonud inside sequence 's'?
    bool was_char_found
    --// Was non-character found inside sequence 's'?
    bool was_non_char_found
    was_char_found = false
    was_non_char_found = false
    --// Check each member of 's'.
    for i = 1 to length (s) do
        member = s [i]
        if atom (member) = false then    --// Sequence found inside sequence. This sequence is not string.
            return 0
        else                            --// Member is atom. Ok.
            if is_letter (member) = false then    --// Not character (letter).
                was_non_char_found = true
                if was_char_found = true then --// Both character and non-character were found inside sequence 's'.
                    --// Now just make sure till the end of the sequence 's' there are no sequences, but only atoms.
                    --// It doesn't matter if those atomes are number or letters.
                    for j = 1 to length (s) do
                        if sequence (s [j]) = true then --// Sequence found inside sequence. This sequence is not string.
                            return 0
                        end if
                    end for
                    --// Sequence 's' IS string!
                    return 1
                end if
            else                                    --// It is character (letter).
                was_char_found = true
                if was_non_char_found = true then --// Both character and non-character were found inside sequence 's'.
                    --// Now just make sure till the end of the sequence 's' there are no sequences, but only atoms.
                    --// It doesn't matter if those atomes are number or letters.
                    for j = 1 to length (s) do
                        if sequence (s [j]) = true then --// Sequence found inside sequence. This sequence is not string.
                            return 0
                        end if
                    end for
                    --// Sequence 's' IS string!
                    return 1
                end if
            end if
        end if
    end for
    --//
    --// A little debugging precaution:
    --//=>
        if Debug = true then --// In debug mode.
            if was_char_found = true and was_non_char_found = true then     --// both can't be true either.
                error ("Program error: Both character and non-character can't be found, because we are at end of the function.")
            end if
        end if
    if was_char_found = true then           --// Pure string.
        return 2
    elsif was_non_char_found = true then    --// Pure non-string.
        return 3
    elsif was_char_found = false and was_non_char_found = false then --// No atom at all was found. Sequence must be emptz.
        --// Let's consider emptz sequence as pure string, shall we? :)
        return 2
    end if
end function


--/*
-- convert_mixed_string_to_pure [Created on 15. October 2001, 00:23]
-- The 'convert_mixed_string_to_pure' function converts mixed string to pure string.
-- Mimxed string is a string which has letters and numbers.
-- Pure string has only letters.
--
-- PARAMETERS
-- 'mixed_string'
--    Mixed string to be converted.
-- 'replacement_character'
--    Character to be put at place where non-character atoms are in 'mixed_string'.
--
-- RETURN VALUES
-- Converted 'pure' string.
--
--*/
global function convert_mixed_string_to_pure (sequence mixed_string, CHAR replacement_character)
    --// One member of 'mixed_string'.
    atom member
    --// This will be returned.
    STRING converted_string
    converted_string = repeat (0, length (mixed_string))
    --// Check each member of 'mixed_string'.
    for i = 1 to length (mixed_string) do
        member = mixed_string [i]
        if is_letter (member) = false then    --// Not character (letter).
            converted_string [i] = replacement_character
        else                                    --// It is letter.
            converted_string [i] = mixed_string [i]
        end if
    end for
    return converted_string
end function

-- finds x in s, which is assumed to be sorted
-- if x is not found returns the negative of the position where it would be
-- inserted (like EDS)
global function find_sorted(object x,sequence s)
    integer min,max,mid,test
    min=1
    max=length(s)
    while min<=max do
         mid=floor((min+max)/2)
         test=compare(x,s[mid])
         if test=0 then return mid end if
         if test>0 then
             min=mid+1
         else
             max=mid-1
         end if
   end while
   return -min
end function

--/*
-- get_sequence_member [Created on 29. November 2001, 18:55]
-- The 'get_sequence_member' function returns one member of a sequence.
-- Member is defined by a path.
--
-- PARAMETERS
-- 's'
--    This is sequence from which to get a member.
-- 'member_path'
--    Path to member. This is a sequence with just numbers.
--    It can be empty, then the whole sequence 's' is returned.
--    Example: if s = {1, {2, {3, 4}, 5}, 6, 7}
--             and member_path = {2}
--             {2, {3, 4} is returned.
--             , or member_path = {2, 2}
--             {3, 4} is returned.
--             , or member_path = {2, 2, 1}
--             3 is returned.
--             , or member_path = {2, 2, 2}
--             4 is returned.
--             , or member_path = {1}
--             1 is returned.
--             , or member_path = {2, 3}
--             5 is returned.
--             etc ...
--
-- RETURN VALUES
-- Euphoria object, a member of the sequence 's', or the whole sequence 's'.
--
--*/
global function get_sequence_member (sequence s, sequence member_path)
    --// Current sequence. It shrinks down till we get the member we want.
    sequence current_sequence
    if equal (member_path, {}) = true then --// Path to member is empty. Simply return whole sequence.
        return s
    end if
    current_sequence = s
    --// All members excpect last which we get by help of 'member_path' must be sequence.
    for i = 1 to length (member_path) - 1 do
        current_sequence = current_sequence [member_path [i]]
    end for
    --// Last member doesn't need to be sequence. We get it here and return it.
    return current_sequence [member_path [length (member_path)]]
end function

global function remove_last (sequence s)
    return s [1 .. length (s) - 1]
end function

global function print_format( object o )

    -- returns object formatted for wPrint
    sequence s

    if atom( o ) then
        -- number
		if o >= ' ' and o <= '}' then
			return sprintf( "%d'%s'", {o,o} )
			--return sprintf( "%s", o )
		else			
			return sprintf( "%d", o )
		end if
    else
        -- list
        s = "{"
        for i = 1 to length( o ) do
            s = s & print_format( o[i] )
            if i < length( o ) then
                s = s & ","
            end if
        end for
        s = s & "}"
        return s
    end if

end function

--/*
-- get_number_of_digits [Created on 8. December 2001, 02:20]
-- The 'get_number_of_digits' function returns how many digits are there in
-- decimal number 'num'
--
-- PARAMETERS
-- 'num'
--    Decimal number for which to get number of digits.
--
-- RETURN VALUES
-- Number of digits in 'num'.
--
--*/
global function get_number_of_digits (integer num)
    return length (sprintf ("%d", num))
end function

--/*
-- string_to_number [Created on 12. December 2001, 00:00]
-- The 'string_to_number' function converts string to integer.
-- If it could not be converted error message box is displayed.
--
-- PARAMETERS
-- 'string'
--    String to convert.
--
-- RETURN VALUES
-- 'sstring' converted to integer.
--
--*/
global function string_to_number (STRING string)
    --// Result of 'value ()'.
    sequence val
    val = value (string)
    if val [1] != GET_SUCCESS then --// Value could not be gotten.
        error ("Couldn't get value for \"" & string & "\".")
        return 0
    end if
    return val [2]
end function

--/*
-- number_to_string [Created on 22. June 2002, 16:55]
-- The 'number_to_string' function converts number (atom or integer)
-- to string.
--
-- PARAMETERS
-- 'number'
--    .
--
-- RETURN VALUES
-- STRING.
--*/
global function number_to_string (atom number)
    if integer (number) then --// whole number
        return sprintf ("%d", number)
    else --// floating point number
        return sprintf ("%f", number)
    end if
end function

--/*
-- is_any_lowest_integer_inside [Created on 21. December 2001, 03:47]
-- The 'is_any_lowest_integer_inside' function finds is sequence has any
-- 'LOWEST_INTEGER' constant inside itself.
--
-- PARAMETERS
-- 's'
--    Sequence to be searched.
--
-- RETURN VALUES
-- If 'LOWEST_INTEGER' is inside sequence true is returned.
-- 
-- If 'LOWEST_INTEGER' is not inside sequence false is returned.
--*/
global function is_any_lowest_integer_inside (sequence s)
    for i = 1 to length (s) do
        if atom (s [i]) and s [i] = LOWEST_INTEGER then
            return true
        end if
    end for
    return false
end function

--// By Brian Broker.
--// Replaces all occurances of substrings in string with new substring.
--// replace ("AA bb CC AA", "AA", "XX") returns "XX bb CC XX".
global function replace_str( sequence target, sequence old, sequence new )
  integer len, loc

  len = length( old )
  loc = match( old, target )

  if loc then
    return target[1..(loc - 1) ] &
           new &
           -- recursive call on remainder of string --
           replace_str( target[(loc + len)..length( target )], old, new )
  else
    return target
  end if

end function

--/*
-- replace_seq [Created on 23. June 2002, 17:13]
-- The 'replace_seq' function replaces all
-- elements of 'target' which are equal to 'new'
-- with 'old'.
-- It only replaces non-nested members.
--
-- PARAMETERS
-- 'target'
--    .
-- 'old'
--    .
-- 'new'
--    .
--
-- RETURN VALUES
-- sequence.
--
-- EXAMPLE
-- replace_seq ({1,2,3,1}, 1, 5) returns {5,2,3,5}.
--*/
global function replace_seq (sequence target, object old, object new)
    integer len, loc

    loc = find( old, target )

    if loc then
        target [loc] = new
        for i = loc + 1 to length (target) do
            if equal (target [i], old) then
                target [i] = new
            end if
        end for
    end if
    return target
end function

--/*
-- match_in_members [Created on 29. December 2001, 02:49]
-- The 'match_in_members' function performs 'match ()'
-- on every member of 's'.
--
-- PARAMETERS
-- 'find_me'
--    This searching.
-- 's'
--    On members in this sequence is 'match ()' used.
--
-- RETURN VALUES
-- If found it returns index of first member that contained 'find_me'.
-- 
-- If not found 0 is returned.
--*/
global function match_in_members (sequence find_me, sequence s)
    --// Index where in current member was 'find_me'.
    integer index
    for i = 1 to length (s) do
        index = match (find_me, s [i])
        if index != 0 then --// Bingo! Found!
            return i
        end if
    end for
    return 0
end function

global function get_first_member (sequence s)
    if length (s) >= 1 then
        return s [1]
    else
        error ("Length of sequence is 0, can't get first member.")
    end if
end function

global function get_last_member (sequence s)
    if length (s) != 0 then
        return s [length (s)]
    else
        error ("Length of sequence is 0, can't get last member.")
    end if
end function

global function get_member (sequence s, integer index)
    if index <= length (s) then
        return s [index]
    else
        error ("There is no element at that position in sequence.")
    end if
end function





--//--//--//--//--//--//--//--//--//-- Safe members retrival from sequences. --//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//
--// Functions to safe retreive a meber from sequence.
--// If member is not found at the position then integer 'UNDEFINED' is returned.

global function get_first_member_safe (sequence s)
    if length (s) >= 1 then
        return s [1]
    else
        return UNDEFINED
    end if
end function

global function get_last_member_safe (sequence s)
    if length (s) != 0 then
        return s [length (s)]
    else
        return UNDEFINED
    end if
end function

global function get_member_safe (sequence s, integer index)
    if index <= length (s) then
        return s [index]
    else
        return UNDEFINED
    end if
end function

------------------------------------------------------------------------------
-- get_num_digits_in_integer [Created on 11. August 2002, 08:21, Sunday]
-- The 'get_num_digits_in_integer' function gets
-- number of whole digits that are in integer,
-- digits which are before dot if number is floating point number.
--
-- Examples:
-- get_num_digits_in_integer (10) returns 2
-- get_num_digits_in_integer (1000) returns 4
-- get_num_digits_in_integer (999) returns 3
-- get_num_digits_in_integer (2) returns 1
-- get_num_digits_in_integer (5.32121121) returns 1
-- get_num_digits_in_integer (0) returns 1
-- get_num_digits_in_integer (-9) returns 1
-- get_num_digits_in_integer (-445.6789) returns 3
-- 
-- PARAMETERS
-- 'number'
--    Atom or integer.
-- 
-- RETURN VALUES
-- Integer.
------------------------------------------------------------------------------
global function get_num_digits_in_integer (atom number)
    atom ret
    if number = 0 then
        return 1
    elsif number < 0 then
        number = -number
    end if
    ret = floor (log (number) / log (10)) + 1
    if ret = 0 then
        ret = 1
    end if
    return ret
end function

--Tests for 'get_num_digits_in_integer()':
--Tmp = get_num_digits_in_integer (0)
--show ("Tmp", Tmp)
--assert (Tmp = 1)

--Tmp = get_num_digits_in_integer (10)
--show ("Tmp", Tmp)
--assert (Tmp = 2)
--
--Tmp = get_num_digits_in_integer (100)
--show ("Tmp", Tmp)
--assert (Tmp = 3)
--
--Tmp = get_num_digits_in_integer (4)
--show ("Tmp", Tmp)
--assert (Tmp = 1)
--
--Tmp = get_num_digits_in_integer (988)
--show ("Tmp", Tmp)
--assert (Tmp = 3)
--
--Tmp = get_num_digits_in_integer (12345678)
--show ("Tmp", Tmp)
--assert (Tmp = 8)
--
--Tmp = get_num_digits_in_integer (9)
--show ("Tmp", Tmp)
--assert (Tmp = 1)
--
--Tmp = get_num_digits_in_integer (1001)
--show ("Tmp", Tmp)
--assert (Tmp = 4)
--
--Tmp = get_num_digits_in_integer (3.21243545)
--show ("Tmp", Tmp)
--assert (Tmp = 1)
--
--Tmp = get_num_digits_in_integer (-11)
--show ("Tmp", Tmp)
--assert (Tmp = 2)
--
--Tmp = get_num_digits_in_integer (-123456789)
--show ("Tmp", Tmp)
--assert (Tmp = 9)
--
--Tmp = get_num_digits_in_integer (-0.321)
--show ("Tmp", Tmp)
--assert (Tmp = 1)
--
--for i = 1 to 1000 do
--    Tmp1 = rand (10000000)
--    Tmp = get_num_digits_in_integer (Tmp1)
--    assert (Tmp = length (sprintf ("%d", Tmp1)))
--end for

------------------------------------------------------------------------------
-- number_to_str_places [Created on 10. August 2002, 19:19, Saturday]
-- The 'number_to_str_places' function converts
-- a number to string.
-- Resulting number has at least that many digits
-- before dot as number 'places'.
-- 0's are added if not enough.
--
-- Example:
-- number_to_str_places (1, 3) returns "001"
-- number_to_str_places (1000, 3) returns "1000"
-- number_to_str_places (2.5, 3) returns "02.5"
-- 
-- PARAMETERS
-- 'number'
--    Number to convert to string.
-- 'places'
--    How many digits before dot should there be, at least,
--    in returned value.
-- 
-- RETURN VALUES
-- String.
------------------------------------------------------------------------------
global function number_to_str_places (atom number, integer places)
    integer dot_pos
    STRING ret
    if integer (number) then --// whole number
        ret = sprintf ("%d", number)
        ret = repeat ('0', max (0, places - length (ret))) & ret
    else --// floating point number
        ret = sprintf ("%f", number)
        dot_pos = find ('.', ret)
        ret = repeat ('0', max (0, places - dot_pos)) & ret
    end if
    return ret
end function

-- Tests for number_to_str_places():
--Tmp = number_to_str_places (1, 3)
--show ("Tmp", Tmp)
--assert (equal ("001", Tmp))
--Tmp = number_to_str_places (1000, 3)
--show ("Tmp", Tmp)
--assert (equal ("1000", Tmp))
--Tmp = number_to_str_places (2.5, 3)
--show ("Tmp", Tmp)
--assert (match ("02.5", Tmp))

--/*
-- right_safe [Created on 5. August 2002, 03:03]
-- The 'right_safe' function returns characters from
-- right of string.
-- It is safe routine, if string is too short
-- then whole string is returned.
--
-- PARAMETERS
-- 's'
--    .
-- 'how_many'
--    .
--
-- RETURN VALUES
-- String.
--*/
global function right_safe (sequence s, integer how_many)
    if how_many >= length (s) then
        return s
    else
        return s [length (s) -  how_many + 1 .. length (s)]
    end if
end function

--/*
-- starts_with [Created on 26. August 2002, 01:14]
-- The 'starts_with' function finds out if strings starts with
-- string.
--
-- PARAMETERS
-- 'string'
--    String which is evaluated if it starts with.
-- 'starts'
--    Start of 'string' and this should be equal.
-- 'case_sensitive'
--    If comparison should be case sensitive or not.
--
-- RETURN VALUES
-- True if 'string' starts with 'starts', false otherwise.
--*/
global function starts_with (STRING string, STRING starts, bool case_sensitive)
    if length (starts) > length (string) then
        return false
    end if
    if case_sensitive then
        return equal (string [1 .. length (starts)], starts)
    else
        return equal (lower (string [1 .. length (starts)]), lower (starts))
    end if
end function
--//
--// Tests for 'starts_with()':
--//=>
    --// assert (starts_with ("abcde", "ab", true) = true)
    --// assert (starts_with ("abcde", "aB", true) = false)
    --// assert (starts_with ("abcde", "aB", false) = true)
    --// assert (starts_with ("abcde", "abcde", true) = true)
    --// assert (starts_with ("", "", true) = true)
    --// assert (starts_with ("a", "abcd", true) = false)
    --// wait ()
    --// abort (0)


--/*
-- split [Created on 7. July 2002, 00:49]
-- The 'split' function splits strings into parts, 
-- split is at each place where character you specify is.
--
-- PARAMETERS
-- 's'
--    String to split.
-- 'split_char'
--    Character which if found in string it splits it.
--
-- EXAMPLE
-- parts = split ("c:\\my documents\\audio/video files\\", '\\')
-- parts is:
-- {
-- "c:",
-- "my documents",
-- "audio/video files"
-- ""
-- }
--
-- RETURN VALUES
-- Sequence with strings.
--*/
global function split (STRING s, CHAR split_char)
    integer i, prev_i
    sequence parts --// returned
    i = find (split_char, s)
    if i then
        parts = {s [1 .. i - 1]}
    else
        return {s}
    end if
    i += 1
    prev_i = i
    while i <= length (s) do
        if s [i] = split_char then
            parts = append (parts, s [prev_i .. i - 1])
            prev_i = i + 1
        end if
        i += 1
    end while
    parts = append (parts, s [prev_i .. length (s)])
    return parts
end function

--// Tests for trim_back():
--// Tmp = trim_back ("//string//", '/')
--// assert (equal (Tmp, "//string"))
--// 
--// Tmp = trim_back ("//string///////", '/')
--// assert (equal (Tmp, "//string"))
--// 
--// Tmp = trim_back ("//string", '/')
--// assert (equal (Tmp, "//string"))
--// 
--// Tmp = trim_back ("", '/')
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, ""))
--// 
--// wait ()
--// abort (0)

--/*
-- join_with [Created on 7. July 2002, 01:56]
-- The 'join_with' function joins sequence with strings
-- and puts string 'between' betwen them
--
-- PARAMETERS
-- 'strings'
--    .
-- 'between'
--    .
--
-- RETURN VALUES
-- String.
--*/
global function join_with (sequence strings, STRING between)
    STRING res --// returned
    res = ""
    for i = 1 to length (strings) - 1 do
        res &= strings [i] & between
    end for
    res &= strings [length (strings)]
    return res
end function

-- takes an number and makes a sequence with commas every 3 digits:
-- by Dan Moyer
global function PrettyNumbers(object aNumber)
sequence PrettyNumber, Temp, decPart
integer TriCounter, decPos
PrettyNumber = {}
Temp = {}
decPart = {}
decPos = 0


TriCounter = 0
Temp = sprint(aNumber)

decPos = find('.', Temp)
if decPos then
   decPart = Temp[decPos..length(Temp)]
   Temp = Temp[1..decPos -1]
end if

for n = length(Temp) to 1 by -1 do
PrettyNumber = prepend(PrettyNumber,Temp[n])
TriCounter += 1
if TriCounter = 3 and n != 1 then
PrettyNumber = prepend(PrettyNumber,',')
end if
if TriCounter = 3 then
TriCounter = 0
end if
end for

if not atom(decPart) then
  PrettyNumber = PrettyNumber & decPart
end if

return PrettyNumber
end function

--// By Kat.
global function commatize(sequence number)
sequence result, deci,int
result = ""

if match(".",number)
  then int = number[1..match(".",number)-1]
       deci = number[match(".",number)+1..length(number)]
  else int = number
       deci = ""
end if

while length(int) do
  if length(int) >= 3
    then result = int[length(int)-2..length(int)] & "," & result
         int = int[1..length(int)-3]
    else result = int & "," & result
         int = ""
  end if
end while
result = result[1..length(result)-1]
--// Start Tone Skoda
--// result = result & "." & deci
if length (deci) then
    result = result & "." & deci
end if
--// End Tone Skoda
if result[1] = ',' then result = result[2..length(result)] end if
return result
end function -- commatize(sequence number)

--/*
-- trim_alphas [Created on 7. July 2002, 09:11]
-- The 'trim_alphas' function removes any alpha
-- characters from start and end of strings.
--
-- EXAMPLE:
-- "abc123zi" returns "123"
--
-- PARAMETERS
-- 's'
--    .
--
-- RETURN VALUES
-- String.
--*/
global function trim_alphas (STRING s)
    integer starti, endi
    if length (s) = 0 then
        return ""
    end if
    starti = 1
    while isalpha (s [starti]) and starti < length (s) do
        starti += 1
    end while
    endi = length (s)
    while isalpha (s [endi]) do
        endi -= 1
    end while
    return s [starti .. endi]
end function

--/*
-- trim [Created on 3. August 2002, 21:58]
-- The 'trim' function removes space characters
-- from start and edn of string.
--
-- PARAMETERS
-- 's'
--    .
--
-- RETURN VALUES
-- .
--*/
global function trim (STRING s)
    integer starti, endi
    if length (s) = 0 then
        return ""
    end if
    starti = 1
    while 1 do
        if starti > length (s) then
        --// all spaces
            return ""
        end if
        if not isspace (s [starti]) then
            exit
        end if
        starti += 1
    end while
    endi = length (s)
    while 1 do
        if not isspace (s [endi]) then
            exit
        end if
        endi -= 1
    end while
    return s [starti .. endi]
end function

--// Tests for trim():
--// Tmp = trim ("  ja     ")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "ja"))
--// 
--// Tmp = trim ("  ja")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "ja"))
--// 
--// Tmp = trim ("ja     ")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "ja"))
--// 
--// Tmp = trim ("ja")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "ja"))
--// 
--// Tmp = trim ("       ")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, ""))
--// 
--// 
--// Tmp = trim ("  \tj\n     ")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "j"))
--// 
--// wait ()
--// abort (0)

--/*
-- count_if [Created on 29. May 2002, 08:00]
-- The 'count_if' function returns integer how many times
-- is 'o' found in 's'. Looked are only non-nested members.
--
-- PARAMETERS
-- 's'
--    sequence searched thru.
-- 'o'
--    this element is being counted.
--
-- RETURN VALUES
-- Number of times 'o' is in 's'.
--*/
global function count_if (sequence s, object o)
    integer count
    count = 0 
    for i = 1 to length (s) do
        if equal (s [i], o) then
            count += 1
        end if
    end for
    return count
end function

--/*
-- convert_numbers_to_string [Created on 2. June 2002, 07:56]
-- The 'convert_numbers_to_string' function converts numbers in
-- sequence to one stering, separated by comma.
--
-- PARAMETERS
-- 'numbers'
--    Sequence with numbers.
--
-- RETURN VALUES
-- STRING, numbers separated by comma.
--*/
global function convert_numbers_to_string (sequence numbers)
    STRING res
    res = ""
    for i = 1 to length (numbers) do
        if integer (numbers [i]) then
            res &= sprintf ("%d,", numbers [i])
        elsif atom (numbers [i]) then
            res &= sprintf ("%.2f,", numbers [i])
        else
            assert (false) --// non-numbers not allowed in sequence
        end if
    end for
    return res [1 .. length (res) - 1] --// remove last comma
end function

--/*
-- convert_object_to_string [Created on 5. June 2002, 01:38]
-- The 'convert_object_to_string' function converts any Eu object into string.
--
-- PARAMETERS
-- 'o'
--    object.
--
-- RETURN VALUES
-- STRING.
--*/
global function convert_object_to_string (object o)
    if integer (o) then
        return sprintf ("%d", o)
    elsif atom (o) then
        return sprintf ("%f", o)
    elsif is_string (o) then
        return o
    else
        return print_format (o)
    end if
end function

--/*
-- count_atoms [Created on 5. June 2002, 19:00]
-- The 'count_atoms' function counts how many
-- atoms are in nested etc sequences. 
--
-- PARAMETERS
-- 'o'
--    object.
--
-- RETURN VALUES
-- Number of atoms in Euphoria object 'o'.
--*/
global function count_atoms (object o)
    integer num
    num = 0
    if not sequence (o) then    
        return 1
    else
        for i = 1 to length (o) do
            num += count_atoms (o [i])
        end for
    end if
    return num
end function

--/*
-- split_text_into_lines [Created on 9. June 2002, 00:46]
-- The 'split_text_into_lines' function split text into
-- lines of text.
--
-- PARAMETERS
-- 'text'
--    To be split.
--
-- RETURN VALUES
-- Sequence with strings.
--*/
global function split_text_into_lines (STRING text)
    sequence lines
    integer prev_nl, i
    lines = {}
    prev_nl = 0
    i = 1
    while i <= length (text) do
        if text [i] = '\n' then
            if i > 2 and text [i - 1] = 13 then
                lines = append (lines, text [prev_nl + 1 .. i - 2])
            else
                lines = append (lines, text [prev_nl + 1 .. i - 1])
            end if
            prev_nl = i
        end if
        i += 1
    end while
    if i > 2 and text [i - 1] = 13 then
        lines = append (lines, text [prev_nl + 1 .. i - 2])
    else
        lines = append (lines, text [prev_nl + 1 .. i - 1])
    end if
    return lines
end function

global function join_text_lines (sequence lines)
    STRING res
    res = ""
    for i = 1 to length (lines) do
        res &= lines [i] & "\n"
    end for
    res = res [1 .. length (res) - 1] --// remove last '\n'
    return res
end function

--/*
-- find_largest_member_seq [Created on 9. June 2002, 07:52]
-- The 'find_largest_member_seq' function finds 
-- non-nested member sequence which 
-- is largest.
--
-- PARAMETERS
-- 's'
--    Sequence with sequences.
--
-- RETURN VALUES
-- Index of sequence or 0 if no sequences.
--*/
global function find_largest_member_seq (sequence s)
    integer res
    res = 0
    for i = 1 to length (s) do
        if sequence (s [i]) then
            if res = 0 then
                res = i
            else
                if length (s [i]) > length (s [res]) then
                    res = i
                end if
            end if
        end if
    end for
    return res
end function

--/*
-- find_from_pos [Created on 10. November 2002, 23:36]
-- The 'find_from_pos' function is equal to 
-- builtin 'find ()' except that
-- it searches from defined position.
--
-- PARAMETERS
-- 'find_me'
--    .
-- 's'
--    .
-- 'frompos'
--    .
--
-- RETURN VALUES
-- .
--*/
global function find_from_pos (object find_me, sequence s, integer frompos)
    for i = frompos to length (s) do
        if equal (find_me, s [i]) then
            return i
        end if
    end for
    return 0
end function

--/*
-- repeat_add [Created on 11. November 2002, 00:21]
-- The 'repeat_add' function is similar to builtin
-- 'repeat ()', this is difference:
-- 
-- repeat ("ABC", 3) returns {"ABC", "ABC", "ABC"}
--
-- repeat_add ("ABC", 3) returns "ABCABCABC"
--
-- PARAMETERS
-- 'o'
--    .
-- 'count'
--    .
--
-- RETURN VALUES
-- .
--*/
global function repeat_add (object o, integer count)
    sequence res
    res = ""
    for i = 1 to count do
        res &= o
    end for
    return res
end function

--/*
-- are_all_spaces [Created on 11. November 2002, 00:29]
-- The 'are_all_spaces' function returns true
-- if all spaces in string are white space characters
-- ('\n', '', or tab).
-- If "" true is also returned.
--
-- PARAMETERS
-- 's'
--    .
--
-- RETURN VALUES
-- .
--*/
global function are_all_spaces (STRING s)
    for i = 1 to length (s) do
        if not isspace (s [i]) then
            return false
        end if
    end for
    return true
end function