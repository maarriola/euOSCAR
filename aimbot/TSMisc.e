




--// TSMisc.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 30. September 2001.
--// Miscalenous general stuff.

--// Suggested namespace: misc




--// Other people's include files:
include DateTime.e
--// TSLibrary include files:
include TSMath.e as math
include TSDebug.e as debug
include TSError.e
include TSTypes.e as types
--// Standard include files.
include CType.e
include get.e
include database.e
include wildcard.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- random_between [Created on 10. August 2002, 18:56, Saturday]
-- The 'random_between' function gets a random
-- value which will be betwen two values.
-- Values can be negative.
--
-- PARAMETERS
-- 'min_val'
--    Minimal allowed value, exceluding.
-- 'max_val'
--    Maximal allowed value, including.
--
-- RETURN VALUES
-- Atom, random value.
--*/
global function random_between (atom min_val, atom max_val)
    atom diff
    diff = max_val - min_val
    assert (diff >= 0)
    if diff < 1 then
        return 1
    elsif diff = 1 then
        return rand (2) - 1
    end if
    return min_val + rand (diff)
end function
--//
--// Tests for random_between ():
--//=>
    --// integer r, rsum
    --// atom average
    --// rsum = 0
    --// for i = 1 to 100 do
    --//     r = random_between (2, 8)
    --//     rsum += r
    --//     average = rsum / i
    --//     show ("r", r)
    --//     show ("average", average)
    --//     blankln ()
    --// end for
    --// wait ()
    --// Tmp = random_between (1, 3)
    --// Tmp = random_between (1, 3)
    --// assert (Tmp >= 1 and Tmp <= 3)
    --// Tmp = random_between (2, 10) 
    --// assert (Tmp >= 2 and Tmp <= 10)
    --// Tmp = random_between (1.1, 100) 
    --// assert (Tmp >= 1.1 and Tmp <= 100)
    --// Tmp = random_between (5.753, 7.43) 
    --// assert (Tmp >= 5.753 and Tmp <= 7.43)
    --// Tmp = random_between (-10, -5) 
    --// show ("Tmp", Tmp)
    --// assert (Tmp >= -10 and Tmp <= -5)
    --// wait ()

--/*
-- random_between_two [Created on 13. November 2002, 20:26]
-- The 'random_between_two' function returns either value 1 or value 2,
-- no value between.
--
-- PARAMETERS
-- 'val1'
--    .
-- 'val2'
--    .
--
-- RETURN VALUES
-- .
--*/
global function random_between_two (integer val1, integer val2)
    integer one_or_two
    one_or_two = rand (2)
    if one_or_two = 1 then
        return val1
    elsif one_or_two = 2 then
        return val2
    end if
end function

--/*
-- join [Created on 17. November 2002, 15:57]
-- The 'join' function "ands" (&=) together members of sequence.
--
-- PARAMETERS
-- 's'
--    .
-- 'add_between'
--    What to add between each member.
--
-- RETURN VALUES
-- sequence.
--*/
global function join (sequence s, object add_between)
    sequence res
    res = {}
    for i = 1 to length (s) do
        res &= s [i] & add_between
    end for
    return res
end function
