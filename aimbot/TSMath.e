




--// TSMath.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 23. May 2002.
--// Miscalenous math and geometry routines.

--// Suggested namespace: math





--// TSLibrary include files:
include TSPack.e as pack
include TSDebug.e as debug
include TSError.e
include TSTypes.e as types
--// Standard include files:







--//--//--//--//--//--//--//--//--//-- Variables and constants. --//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//





--//--//--//--//--//--//--//--//--//-- Routines. --//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//




--// Converts angle in degrees to angle in radians.
global function deg_to_rad (atom x)
	return x * PI / 180
end function

--// Converts angle in radians to angle in degrees.
global function rad_to_deg (atom x)
	return x * 180 / PI
end function

--/*
-- atan2 [Created on 23. May 2002, 18:44]
-- The 'atan2' function is equal to C's atan2().
--
-- PARAMETERS
-- 'x'
--    .
-- 'y'
--    .
--
-- RETURN VALUES
-- .
--*/
global function atan2 (atom x, atom y)
    return arctan (x / y)
end function

--// Returns true if points are equal else false.
global function are_points_equal (POINT point1, POINT point2)
    return equal (point1, point2)
end function

--/*
-- get_points_distance [Created on 23. May 2002, 18:12]
-- The 'get_points_distance' function gets distance between two points.
--
-- PARAMETERS
-- 'x1'
--    .
-- 'y1'
--    .
-- 'x2'
--    .
-- 'y2'
--    .
--
-- RETURN VALUES
-- atom, distance.
--*/
global function get_points_distance (atom x1, atom y1, atom x2, atom y2)
    return sqrt (power (x1 - x2, 2) + power (y1 - y2, 2))
end function


--// Function name         : get_angle_between_two_points
--// Time                                :4.9.99 21:47:53
--// Description                : gets angle between 2 points
--//                                                        it does matter which point is first and second
--//                                                        returns angle in radians
--//                                                        angle is always positive and between
--//                                                        0 and 2*PI (0-359 degrees)
--// Return type           : double - RADIANS
--// Argument           : int x1
--// Argument           : int y1
--// Argument           : int x2
--// Argument           : int y2
global function get_angle_between_two_points (atom x1, atom y1, atom x2, atom y2)
	atom angle
    if y2 - y1 = 0 then --// line is horizontal, find out in which direction is it going, right or left
	if x2 > x1 then
	    return 0
	else
	    return PI
	end if
    end if
    if x2 = x1 then --// line is vertical, find out in which direction is it going, up or down
	if y2 > y1 then --// up
	    return PI / 2
	else --// down
	    return PI + PI / 2
	end if
    end if
	angle = atan2 (y2 - y1, x2 - x1)
	--// Put it in range 0 - 359 degrees.
    if (angle >= PI * 2) then
	angle = angle - PI * 2
    end if
    if (angle < 0) then
	angle = PI * 2 + angle
    end if
    assert (angle <= PI * 2)
    assert (angle >= 0)
	return angle
end function

--/**
-- get_angle_between_two_lines [Created on 26. January 2002, 19:19]
-- The 'get_angle_between_two_lines' function calculates angle between two lines.
-- Where line 1 ends second line should begin.
--
-- PARAMETERS
-- 'first_line_start_point'
--    First point of first line.
-- 'first_line_end_point'
--    Last point of first line.
-- 'second_line_start_point'
--    First point of second line.
-- 'second_line_end_point'
--    Last point of second line.
--
-- TEMPLATE PARAMETERS
-- 'POINT_TYPE'
--    It should have these members: x and y.
--
-- RETURN VALUES
-- Angle in radians. It is allways positive, put in range between 0 and 359 degrees.
--*/
global function get_angle_between_two_lines (
    atom first_line_start_point_x, atom first_line_start_point_y,
    atom first_line_end_point_x, atom first_line_end_point_y,
    atom second_line_start_point_x, atom second_line_start_point_y,
    atom second_line_end_point_x, atom second_line_end_point_y)

    atom first_line_angle, second_line_angle, angle

    assert (first_line_end_point_x = second_line_start_point_x and
	first_line_end_point_y = second_line_start_point_y)
    first_line_angle = get_angle_between_two_points (
	first_line_start_point_x, first_line_start_point_y,
	first_line_end_point_x, first_line_end_point_y)
    second_line_angle = get_angle_between_two_points (
	second_line_start_point_x, second_line_start_point_y,
	second_line_end_point_x, second_line_end_point_y)
    --// This is returned.
    angle = PI + second_line_angle - first_line_angle
    --// Put it in range 0 - 359 degrees.
    if (angle >= PI * 2) then
	angle = angle - PI * 2
    end if
    if (angle < 0) then
	angle = PI * 2 + angle
    end if
    assert (angle < PI * 2)
    assert (angle >= 0)
    return angle
end function

--/*
-- number_sign [Created on 29. December 2001, 18:57]
-- The 'number_sign' function gets sign of number
--
-- PARAMETERS
-- 'num'
--    Of this number we get sign.
--
-- RETURN VALUES
-- If 'a' is positive 1 is returned.
--
-- If 'a' is negative -1 is returned.
--*/
global function number_sign (atom num)
	if num > 0 then
	return 1
	else
	return -1
    end if
end function

--/*
-- ceil [Created on 29. December 2001, 18:58]
-- The 'ceil' function calculates the ceiling of a value.
--
-- PARAMETERS
-- 'a'
--    atom or integer.
--
-- RETURN VALUES
-- The ceil function returns a double value representing the smallest integer
-- that is greater than or equal to x. There is no error return.
--*/
global function ceil (atom a)
    if floor (a) = a then   --// A is not floating value.
	return a
    else                    --// A is floating value.
	return floor (a + 1)
    end if
end function

--/*
-- abs [Created on 30. December 2001, 01:00]
-- The 'abs' function calculates absolute value of argument.
--
-- PARAMETERS
-- 'a'
--    integer or atom.
--
-- RETURN VALUES
-- Absolute value of 'a'.
--*/
global function abs (atom a)
    if a < 0 then
	return -a
    else
	return a
    end if
end function

--/*
-- round [Created on 29. December 2001, 19:00]
-- The 'round' function returns the closest integer to the argument.
--
-- PARAMETERS
-- 'a'
--    atom or integer.
--
-- RETURN VALUES
-- The value of the argument rounded to the nearest integer value.
--*/
global function round (atom a)
    --// A floored.
	atom a_floor
    if floor (a) = a then   --// A is not floating value.
	return a
    else                    --// A is floating value.
	    a_floor = floor (a)
	    if abs (a - a_floor) < 0.5 then --// 'a' is closer to floor (a) than to ceil (a).
	    return a_floor
	    else                            --// 'a' is closer to ceil (a) than to floor (a).
	    return ceil (a)
	    end if
    end if
end function

--/*
-- max [Created on 12. December 2001, 21:11]
-- The 'max' function is regualr max number.
-- It returns the one of two numbers that is bigger.
--
-- PARAMETERS
-- 'a1'
--    Number 1.
-- 'a2'
--    Number 2.
--
-- RETURN VALUES
-- 'a1' or 'a2'.
--
--*/
global function max (atom a1, atom a2)
    if a1 > a2 then
	return a1
    else
	return a2
    end if
end function

--/*
-- max_inseq [Created on 24. May 2002, 17:55]
-- The 'max_inseq' function finds the biggest number in sequence.
--
-- PARAMETERS
-- 's'
--    Sould not be empty and should have only numbers.
--
-- RETURN VALUES
-- Value of biggest number.
--*/
global function max_inseq (sequence s)
    atom max_till_now
    max_till_now = s [1]
    for i = 2 to length (s) do
	if s [i] > max_till_now then
	    max_till_now = s [i]
	end if
    end for
    return max_till_now
end function

--/*
-- min_inseq [Created on 24. May 2002, 17:55]
-- The 'min_inseq' function finds the smallest number in sequence.
--
-- PARAMETERS
-- 's'
--    Sould not be empty and should have only numbers.
--
-- RETURN VALUES
-- Value of smallest number.
--*/
global function min_inseq (sequence s)
    atom min_till_now
    min_till_now = s [1]
    for i = 2 to length (s) do
	if s [i] < min_till_now then
	    min_till_now = s [i]
	end if
    end for
    return min_till_now
end function

global function min (atom a, atom b)
    if a < b then
	return a
    else
	return b
    end if
end function

--/*
-- put_numbers_into_range_0_1 [Created on 24. May 2002, 18:00]
-- The 'put_numbers_into_range_0_1' function puts each number in sequence in
-- range between 0 and 1. Maximal number has value 1, minimal number has value 0, others
-- something in between.
--
-- PARAMETERS
-- 'numbers'
--    Sequence with numbers, shold not be empty.
--
-- RETURN VALUES
-- Sequence with numbers between 0 and 1.
--*/
global function put_numbers_into_range_0_1 (sequence numbers)
    sequence res --// returned
    atom max_num
    atom min_num
    atom range --// difference between minimal and maximal importance

    res = repeat (0, length (numbers))
    max_num = max_inseq (numbers)
    min_num = min_inseq (numbers)
    range = max_num - min_num
    if range = 0 then
	return res
    end if
    for i = 1 to length (numbers) do
	res [i] = (numbers [i] - min_num) / range
    end for
    return res
end function

--/*
-- set_advanced_rand [Created on 25. May 2002, 03:41]
-- The 'set_advanced_rand' function sets parameters
-- for 'advanced_rand ()' function:
-- advanced random number generator.
--
-- PARAMETERS
-- 'min_val'
--    minimal value returned, inclusive.
-- 'max_val'
--    maximal value to be returned by rand (), inclusive.
-- 'equation_to_perform'
--    Formula to perform on number we get by 'rand()'.
--    This can be "" and no equation will be performed.
--    If this parameter is given then
--    result may not be betwen 'min_val' and 'max_val'
--    It should be in this format:
--    "2+x*4", x will be replaced by value
--    we get from 'rand ()'.
-- 'possibility_for_whole_number'
--    In how much percents should returned number be whole number
--    (integer) (5 for example)
--    and not floating point (5.5 for example).
--
-- RETURN VALUES
-- Id of advanced random generator which you will use in function 'advanced_rand'.
--*/
global function set_advanced_rand (integer min_val, integer max_val,
				   STRING equation_to_perform,
				   PERCENT possibility_for_whole_number)
    return UNDEFINED
end function

--/*
-- advanced_rand [Created on 25. May 2002, 03:46]
-- The 'advanced_rand' function is advanced random numbers generator.
-- Returned value will be affected by what numbers were already returned
-- in the past you called this function with this id.
--
-- PARAMETERS
-- 'id'
--    Id you get with 'set_advanced_rand()'.
--
-- RETURN VALUES
-- Random number.
--*/
global function advanced_rand (integer id)
    return UNDEFINED
end function

--/*
-- multiply_all [Created on 26. May 2002, 23:58]
-- The 'multiply_all' function multiplies all
-- numbers in sequence together. Example:
-- With {1,2,3} it returns 1*2*3.
--
-- PARAMETERS
-- 'numbers'
--    sequence with numers, should have at least one member.
--
-- RETURN VALUES
-- number, result of multiplication.
--*/
global function multiply_all (sequence numbers)
    atom res
    res = numbers [1]
    for i = 2 to length (numbers) do
	res *= numbers [i]
    end for
    return res
end function

global function log_general (atom b, object x)
-- general log() function
-- logarithm for base b and number (or sequence) x

-- in : b: positive real number, != 1
--      x: positive real number (or sequence of those numbers)
-- out: real number
--      (x = 1  -->  function returns 0 for any base b)

   return log (x) / log (b)
end function

--/*
-- safe_power_2 [Created on 2. June 2002, 11:10]
-- The 'safe_power_2' function is translation of C++ function.
-- It does exacly same thing as builting Euphoria power()
-- only slower and safer.
-- Advantage over builting power(): Program doesn't crash with message:
-- "math function overflow error"
-- if you do something like this: power (24, 576) but
-- this function returns infinity.
--
-- PARAMETERS
-- 'x'
--    Same as in built in 'power()'.
-- 'y'
--    Same as in built in 'power()'.
--
-- RETURN VALUES
-- power() or error if >= HIGHEST_ATOM or <= LOWEST_ATOM.
--
-- EXAMPLE USE
-- if safe_power_2 (10, 100000) > HIGHEST_ATOM then
--     puts (1, "overflow")
-- end if
--*/
global function safe_power_2 (atom x, atom y)
    atom n, z
    if (y >= 0) then
	n = y
    else
	n = -y
    end if
    z = 1
    while 1 do
	if (and_bits (n, 1) != 0) then
	    z *= x
	end if
	n = shift_right (n, 1)
	if n = 0 then
	    if y < 0 then
		return 1 / z
	    else
		return z
	    end if
	end if
	x *= x
    end while
end function

--/*
-- safe_power [Created on 3. June 2002, 17:59]
-- The 'safe_power' function does same thing as Euphoria builtin 'power()'
-- with this difference: if return value of 'power()' is too big
-- interpreter crashes with error mesage math overflow.
-- If in this function returned value would be too big
-- then error 'HIGHEST_ATOM' is returned.
--
-- PARAMETERS
-- 'a'
--    Same as in built in 'power()'.
-- 'b'
--    Same as in built in 'power()'.
--
-- RETURN VALUES
-- The value of power(), or error value 'HIGHEST_ATOM'
--*/
--// global function safe_power (atom a, atom b)
--//     atom b_max --// if 'b' is bigger or equal than this then overflow
--//     atom a_max --// if 'a' is bigger or equal than this then overflow
--//     if a = 0 or b = 0 then --// log (0) crashes
--//         return power (a ,b)
--//     end if
--//     b_max = log_general (a, HIGHEST_ATOM)
--//     if b >= b_max then
--//         return HIGHEST_ATOM
--//     end if
--//     a_max = power (HIGHEST_ATOM, 1 / b)
--//     if a >= a_max then
--//         return HIGHEST_ATOM
--//     end if
--//     return power (a, b)
--// end function
global function safe_power (atom a, atom b)
    atom a_max --// if 'a' is bigger or equal than this then overflow

    --// if b = 0 then
    --//    if a != 0 then
    --//       return 1
    --//    end if
    --//    return HIGHEST_ATOM
    --// end if
    if a = 0 then
	if b > 0 then
	    return 0
	else
	    return HIGHEST_ATOM
	end if
    elsif a < 0 and not integer (b) then
    --// can't raise negative number to non integer power
	return HIGHEST_ATOM
    end if

    if b > 1 then
       -- if b < 1, then the overflow can be here!
       a_max = power (HIGHEST_ATOM, 1 / b)
       if abs(a) >= a_max then
	   return HIGHEST_ATOM
       end if
    end if
    return power (a, b)
end function

