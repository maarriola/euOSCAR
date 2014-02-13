





--// TSLibrary_Pack.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 29. March 2002.
--// Library to pack small numbers into integer type, for example,
--// or to compress string etc.

--// Suggested namespace: pack





--// TSLibrary include files:
include TSDebug.e as debug
include TSError.e
include TSTypes.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Local routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--// Simplest way to resolve namespace conflict
--// to just copy this routine.
function or_all(sequence s)
-- or together all elements of a sequence
    atom result
    
    result = 0
    for i = 1 to length(s) do
        result = or_bits(result, s[i])
    end for
    return result
end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- shift_right [Created on 30. December 2001, 07:16]
-- The 'shift_right' function does same thing as C's >>.
--
-- PARAMETERS
-- 'x'
--    ?.
-- 'count'
--    ?.
--
-- RETURN VALUES
-- ?.
--*/
global function shift_right (atom x, integer count)
  return floor (x / power (2, count))
end function

--/*
-- shift_left [Created on 30. December 2001, 07:16]
-- The 'shift_left' function does same thing as C's <<.
--
-- PARAMETERS
-- 'x'
--    .
-- 'count'
--    ?.
--
-- RETURN VALUES
-- ?.
--
-- ALGORITHM
-- (WORD (a)) | ((DWORD) ((WORD) (b))) << 16
--*/
global function shift_left (atom x, integer count)
  return x * power (2, count)  
end function

global function MAKELONG (atom a, atom b)
	return or_bits (a, shift_left (b, 16))
end function

global function makelong (atom a, atom b)
    return MAKELONG (a, b)
end function

global function MAKELPARAM (atom a, atom b)
	return MAKELONG (a, b)
end function

global function makelparam (atom a, atom b)
	return MAKELPARAM (a, b)
end function

--/*
-- LOWORD [Created on 12. December 2001, 21:57]
-- The 'LOWORD' function is equal to C's LOWORD ()'.
--
-- PARAMETERS
-- 'long'
--    Same as C's LOWORD ()'.
--
-- RETURN VALUES
--    Same as C's LOWORD ()'.
--
--*/
global function LOWORD (atom long)
    return remainder (long, 65536)
end function

--/*
-- HIWORD [Created on 12. December 2001, 21:58]
-- The 'HIWORD' function is equal to C's HIWORD ()'.
--
-- PARAMETERS
-- 'long'
--    Same as C's HIWORD ()'.
--
-- RETURN VALUES
--    Same as C's HIWORD ()'.
--
--*/
global function HIWORD (atom long)
    return floor (long / 65536)
end function

-- {1,2,3,4,5,6,7,8} = {#,#,#}
function compress_string (sequence string)
    sequence compressed
    integer compressed_len
    integer rounded_string_size
    atom compressed_len_atom
    -- ceil it
    compressed_len_atom = length (string) / 3
    compressed_len = floor (compressed_len_atom)
    if compressed_len_atom > compressed_len then
        compressed_len += 1
    end if
    rounded_string_size = length (string) - remainder (length (string), 3)
    compressed = repeat (0, compressed_len)    
    for i = 1 to rounded_string_size by 3 do
        compressed [(i + 2) / 3] = bytes_to_int (string [i .. i + 2] & 0)
    end for
    if length (string) > rounded_string_size then
        compressed [compressed_len] = bytes_to_int (string [rounded_string_size + 1.. length (string)] & repeat (0, 4 - (length (string) - rounded_string_size)))
    end if
    return compressed
end function

-- 0's at end are not yet removed
function decompress_string (sequence compressed)
    sequence de_compressed
    sequence one_decompresed -- three leters decompressed
    de_compressed = repeat (0, length (compressed) * 3)
    for i = 1 to length (compressed) do
        one_decompresed = int_to_bytes (compressed [i])
        -- ? one_decompresed
        -- if wait_key () then end if
        de_compressed [1 + (i - 1) * 3 .. 1 + (i - 1) * 3 + 2] = one_decompresed [1 .. 3]
    end for
    return de_compressed
end function





--//--//--//--//--//--//--//--//--//-- Sequence with types "short". --//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//
--// "short" is C type. It takes 16 bits. Two shorts can be in one Euphoria integer because
--// Euphoria integer takes 32 bits.
--// Unsigned short is in range 0 to 65,535.

global function shorts_seq_set (sequence seq, integer index, USHORT value)
    integer real_index
    if remainder (index, 2) = 1 then
        real_index = floor (index / 2) + 1
        seq [real_index] = MAKELONG (LOWORD (seq [real_index]), value)
    else
        real_index = index / 2
        seq [real_index] = MAKELONG (value, HIWORD (seq [real_index]))
    end if
    return seq
end function

global function shorts_seq_get (sequence seq, integer index)
    integer real_index
    if remainder (index, 2) = 1 then
        real_index = floor (index / 2) + 1
        return HIWORD (seq [real_index])
    else
        real_index = index / 2
        return LOWORD (seq [real_index])
    end if
end function

function bytes_needed(object x)
-- estimates the number of bytes of storage needed for any
-- Euphoria 2.0 data object (atom or sequence).
    integer space

    if integer(x) then
        return 4
    elsif atom(x) then
        return 16
    else
        -- sequence
        space = 24 -- overhead
        for i = 1 to length(x) do
            space = space + bytes_needed(x[i])
        end for
        return space
    end if
end function

--// #define HRESULT_FACILITY(hr) (((hr) >> 16) & 0x1fff)
global function HRESULT_FACILITY (atom hr)
    return and_bits (shift_right (hr, 16), #1FFF)
end function

--// #define HRESULT_CODE(hr) ((hr) & 0xFFFF)
global function HRESULT_CODE (atom hr)
    return and_bits (hr, #FFFF)
end function
 
--// #define MAKELANGID(p, s) ((((WORD) (s)) << 10) | (WORD) (p)) 
global function MAKELANGID (atom p, atom s)
    return or_all ({shift_left (s, 10), p})
end function