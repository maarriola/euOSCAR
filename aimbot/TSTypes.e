





--// TSTypes.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 6. October 2001.
--// This file contains some global euphoria types.
--// It has no includes.





include CType.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global constants. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

global constant false = 0, true = 1
global constant FALSE = 0, TRUE = 1
--// Lowest/highest possible integer in Euphoria.
global constant LOWEST_INTEGER = -1073741824
global constant HIGHEST_INTEGER = 1073741823
--// Lowest/hieghest possible atom in Euporia.
global constant LOWEST_ATOM = -1e300
global constant HIGHEST_ATOM = +1e300
global constant LOWEST_ATOM_HALF = -1e300 / 2
global constant HIGHEST_ATOM_HALF = +1e300 / 2
--// Default value.
global constant DEFAULT = LOWEST_INTEGER
--// Something that is not defined, whatever you want to use it for...
global constant UNDEFINED = LOWEST_INTEGER
--// Unneeded return values of functions go into this variable.
--// It should be used for nothing else.
global object Void
global object Tmp, Tmp1
global constant TODO = 0





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global Types @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

global function is_undefined (object o)
    if integer (o) and o = UNDEFINED then
        return true
    else
        return false
    end if
end function

global function is_default (object o)
    if integer (o) and o = DEFAULT then
        return true
    else
        return false
    end if
end function 

--/*
-- UNIQUE_STRICT [Created on 6. October 2001, 17:00]
-- The 'UNIQUE_STRICT' type is sequence which has members which are all different.
--
-- PARAMETERS
-- 's'
--    sequence.
--*/
global type UNIQUE_STRICT (sequence s)
    --// Current member, we're comparing each other member with this one.
    object cur_member

    --// Loop every member of 's', every time change 'cur_member'.
    for i = 1 to length (s) do
        cur_member = s [i]
        for j = 1 to length (s) do --// Loop every member of 's' again to compare ti against 'cur_member'.
            if i != j and equal (cur_member, s [j]) = true then --// Error: two member are equal.
                return false
            end if
        end for
    end for

    return true
end type

--/*
-- UNIQUE [Created on 6. October 2001, 17:00]
-- The 'UNIQUE' type is sequence which has members which are all different,
-- except if they are 0 or "" or {}.
--
-- PARAMETERS
-- 's'
--    sequence.
--*/
global type UNIQUE (sequence s)
    --// Current member, we're comparing each other member with this one.
    object cur_member

    --// Loop every member of 's', every time change 'cur_member'.
    for i = 1 to length (s) do
        cur_member = s [i]
        if equal (cur_member, {}) = false and equal (cur_member, 0) = false then --// Not 0 or {}.
            --// Loop every member of 's' again to compare it against 'cur_member'.
            for j = 1 to length (s) do
                if i != j then --// Not to compare member to itself.                
                        if equal (cur_member, s [j]) = true then --// Error: two members are equal.
                            return false
                        end if
                end if
            end for
        end if
    end for

    return true
end type

--/*
-- bool [Created on 6. October 2001, 17:10]
-- The 'bool' type: type should be 'false' or 'true'.
--
-- PARAMETERS
-- 'i'
--    integer.
--*/
global type bool (integer i)
    if i = true or i = false then
        return true
    else
        return false
    end if
end type

--/*
-- BOOL [Created on 27. December 2001, 20:14]
-- The 'BOOL' type.
--
-- PARAMETERS
-- 'i'
--    true or false.
--*/
global type BOOL (integer i)
    return bool (i)
end type

--/*
-- is_letter [Created on 22. November 2001, 03:03]
-- The 'is_letter' function returns true if integer is a letter.
--
-- PARAMETERS
-- 'i'
--    Numer to test.
--
-- RETURN VALUES
-- True - It is letter.
--
-- False - It is not letter.
--
--*/
global function is_letter (atom a)
    if integer (a) = false
    --// or (a < ' ' or a > '}') and a != 10 then --// Not letter.
    or a < 0 and a > 256 then
        return false
    else --// It is letter!
        return true
    end if
end function

--/*
-- is_string [Created on 9. December 2001, 02:43]
-- The 'is_string' function checks if sequence is string.
--
-- PARAMETERS
-- 's'
--    Sequence to be checked.
--
-- RETURN VALUES
-- If it is string true is returned.
--
-- If it is not string false is returned.
--
--*/
global function is_string (object s)
    if not sequence (s) then
        return false
    end if
    for i = 1 to length (s) do
        if sequence (s [i]) = true
        or is_letter (s [i]) = false then
        --// Current member of 's' is not atom or letter.
            return false
        end if
    end for
    return true
end function

global function is_char (object i)
    if not integer (i) then
        return false
    end if
    return i >= -1 and i <= 255
end function

--/*
-- char [Created on 8. October 2001, 22:28]
-- The 'CHAR' type is character (letter) type.
--
-- PARAMETERS
-- 'i'
--    Integer.
--*/
global type CHAR (integer i)
    return is_char (i)
end type

--/*
-- char [Created on 8. October 2001, 22:28]
-- The 'char' type is character (letter) type.
--
-- PARAMETERS
-- 'i'
--    Integer.
--*/
global type char (integer i)
    return CHAR (i)
end type

--/*
-- STRING [Created on 6. October 2001, 17:13]
-- The 'STRING' type: every member should be a letter (integer in range 0-255).
--
-- PARAMETERS
-- 's'
--    sequence.
--*/
global type STRING (sequence s)
    return is_string (s)
end type

--// sequence with strings
global type STRING_LIST (sequence s)
    for i = 1 to length (s) do
        if not STRING (s [i]) then
            return false
        end if
    end for
    return true
end type

--// returns true is 'o' is sequence with only atoms
global function is_flat_sequence (object o)
    if not sequence (o) then
        return false
    end if
    for i = 1 to length (o) do
        if not atom (o [i]) then --// Not!
            return false
        end if
    end for
    return true
end function

--/*
-- FLAT_SEQ [Created on 23. November 2001, 05:31]
-- The 'FLAT_SEQ' type: sequence which has only atoms.
--
-- PARAMETERS
-- 'o'
--   .
--*/
global type FLAT_SEQ (object o)
    return is_flat_sequence (o)
end type

--/*
-- FLAT_SEQS [Created on 6. December 2001, 15:20]
-- The 'FLAT_SEQS' type:
-- Members are flat sequences.
--
-- PARAMETERS
-- 's'
--    Sequence.
--*/
global type FLAT_SEQS (sequence s)
    for i = 1 to length (s) do
        if FLAT_SEQ (s [i]) = false then --// Member is not flat sequence.
            return false
        end if
    end for
    return true
end type

--/*
-- ASC_SORTED [Created on 6. December 2001, 03:56]
-- The 'ASC_SORTED' type: sequence 's' must be sorted in ascending order.
--
-- PARAMETERS
-- 's'
--    ascending sorted sequence.
--*/
global type ASC_SORTED (sequence s)    
    for i = 1 to length (s) - 1 do
	if compare (s [i], s [i + 1]) > 0 then --// Next member is bigger than previous member.
	    return false
	end if
    end for
    return true
end type

--/*
-- ASC_SORTED_SEQS [Created on 6. December 2001, 16:29]
-- The 'ASC_SORTED_SEQS' type:
-- sequence which has sequences which should be sorted ascending (A-Z).
--
-- PARAMETERS
-- 's'
--    Sequence.
--*/
global type ASC_SORTED_SEQS (sequence s)
    for i = 1 to length (s) do
        if ASC_SORTED (s [i]) = false then --// Member is not ascending sorted sequence.
            return false
        end if
    end for
    return true
end type

--/*
-- BOOLEANS [Created on 12. December 2001, 00:14]
-- The 'BOOLEANS' type: all members should be integers which are 0 or 1 (false or true).
--
-- PARAMETERS
-- 's'
--    sequence with booleans.
--*/
global type BOOLEANS (sequence s)
    for i = 1 to length (s) do
        if bool (s [i]) = false then --// Current member is not bool, this type is not right.
            return false
        end if
    end for
    return true
end type

--// Rectangle type.

global constant
    RECT_LEFT = 1,
    RECT_TOP = 2,
    RECT_RIGHT = 3,
    RECT_BOTTOM = 4,
    RECT_SIZE = 4

global function new_rect ()
    return repeat (UNDEFINED, RECT_SIZE)
end function

global type RECT (sequence rect)
    if length (rect) != RECT_SIZE then
        return false
    end if
    if not atom (rect [RECT_LEFT]) then
        return false
    end if
    if not atom (rect [RECT_TOP]) then
        return false
    end if
    if not atom (rect [RECT_RIGHT]) then
        return false
    end if
    if not atom (rect [RECT_BOTTOM]) then
        return false
    end if
    return true
end type

--/*
-- COLOR [Created on 28. December 2001, 19:14]
-- The 'COLOR' type.
--
-- PARAMETERS
-- 'color'
--    RGB color (0, 0, 0) - (255, 255, 255) .
--*/
global type COLOR (integer color)
    if color < 0 or color > 16777215 then
        return false
    else
        return true
    end if
end type

global type USHORT (integer i)
    return i >= 0 and i < 65535
end type

global constant POINT_X = 1, POINT_Y = 2
global type POINT (sequence s)
    return length (s) = 2 and atom (s [1]) and atom (s [2])
end type

--/*
-- PERCENT [Created on 25. May 2002, 03:40]
-- The 'PERCENT' type:
-- Atom must be between 0 and 1 (inclusive).
--*/
global type PERCENT (atom a)
    return a >= 0 and a <= 1
end type

--/*
-- is_null [Created on 12. January 2002, 23:33]
-- The 'is_null' function finds out if an object is 
-- integer and 0.
--
-- PARAMETERS
-- 'o'
--    object to be checked.
--
-- RETURN VALUES
-- If object is integer 0 then true is returned.
-- Else false is returned.
--*/
global function is_null (object o)
    if integer (o) and o = 0 then
        return true
    else
        return false
    end if
end function

--/*
-- is_str_number [Created on 22. June 2002, 18:30]
-- The 'is_str_number' function returns true
-- if there are ony digit characters inside string,
-- dot is also allowed and # at first place.
-- "#1.234" returns true.
-- "12a3" return false.
--
-- PARAMETERS
-- 's'
--    .
--
-- RETURN VALUES
-- BOOL.
--*/
global function is_str_number (STRING s)
    char c
    for i = 1 to length (s) do
        c = s [i]
        if c < '0' or c > '9' and c != '.' and c != '-' then
            if c != '#' and i != 1 then
                return false
            end if
        end if
    end for
    return true
end function

--// Returns true if only digits (0-9) are in string.
global function are_only_digits (STRING s)
    for i = 1 to length (s) do
        if not isdigit (s [i]) then
            return false
        end if
    end for
    if length (s) = 0 then
        return false
    end if
    return true
end function 

--/*
-- any_too_high_numbers [Created on 24. June 2002, 03:50]
-- The 'any_too_high_numbers' function returns true if
-- there are any numbers in sequence which are too
-- high or too low than Euphoria atom can handle.
--
-- PARAMETERS
-- 's'
--    .
--
-- RETURN VALUES
-- true if not ok, false if ok.
--*/
global function any_too_high_numbers (sequence s)
    for i = 1 to length (s) do
        if s [i] >= HIGHEST_ATOM or s [i] <= LOWEST_ATOM then
            return true
        end if
    end for
    return false
end function

global type POSITIVE (atom a)
    return a >= 0
end type

global type NEGATIVE (atom a)
    return a <= 0
end type