




--// TSDebug.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 6. December 2001.
--// Debugging.
--// Results are written to:
--// - Console
--// - Text file
--// - EDS file for comfortable viewing with EDSGUI.

--// Suggested namespace: debug




--// TSLibrary include files:
--include TSTypes.e
--include TSCustom.e
--include TSError.e
--// Standard include files:
include database.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Local variables. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

integer Text_File_Number
--// Name of the the EDS debug file.
STRING Eds_File_Name
--//
--// These integers tell where will results be written/shown when you call show()
--// You can modify them in your program
--// but you have to do it before you call initialize():
--//=>
    global integer Show_On_Screen --// Show in console window.
    global integer Write_To_File --// Write to text file.
    global integer Write_To_Database --// Write to edb file.
    Show_On_Screen = true
    Write_To_File = false
    Write_To_Database = false
    
    
    
    
    
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Local routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function print_format( object o )

    -- returns object formatted for wPrint
    sequence s

    if integer( o ) then
        -- number
		if o >= ' ' and o <= '}' then
			return sprintf( "%d'%s'", {o,o} )
			--return sprintf( "%s", o )
		else			
			return sprintf( "%d", o )
		end if
    elsif atom (o) then --// floating point number
        return sprintf ("%f", o)
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
function is_letter (atom a)
    if integer (a) = false or (a < ' ' or a > '}') then --// Not letter.
    --// if integer (a) = false then
        return false
    else                                        --// It is letter!
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
function is_string (object s)
    if not sequence (s) then
        return false
    end if
    for i = 1 to length (s) do
        if sequence (s [i]) = true or is_letter (s [i]) = false then --// Current member of 's' is not atom or letter.
            return false
        end if
    end for
    return true
end function

--// If string it doesn't display ascii characters for it.
function print_format_smart( object o )

    -- returns object formatted for wPrint
    sequence s

    if integer( o ) then
        -- number
		if o >= ' ' and o <= '}' then
			return sprintf( "%d'%s'", {o,o} )
			--return sprintf( "%s", o )
		else			
			return sprintf( "%d", o )
		end if
    elsif atom (o) then --// floating point number
        return sprintf ("%f", o)
    else
        if is_string (o) then
            return "\"" & o & "\""
        else
            -- list
            s = "{"
            for i = 1 to length( o ) do
                s = s & print_format_smart( o[i] )
                if i < length( o ) then
                    s = s & ","
                end if
            end for
            s = s & "}"        
            return s
        end if
    end if

end function


--/*
-- db_create_or_open_safe [Created on 29. December 2001, 01:22]
-- The 'db_create_or_open_safe' function opens database file if it exists.
-- If it doesn't exist it tries to create new file.
-- If that also fails error message box is displayed.
--
-- PARAMETERS
-- 'filename'
--    File name of database to open.
-- 'lock'
--    Same as with 'db_create ()'.
--
--*/
procedure db_create_or_open_safe (STRING filename, integer lock)
    --// Result of 'db_open ()'.
    integer fn_open
    --// Result of 'db_create ()'.
    integer fn_create
    fn_open = db_open (filename, lock)
    if fn_open != DB_OK then --// Couldn't open
        fn_create = db_create (filename, lock)
        if fn_create != DB_OK then --// Couldn't create.
            error ("Couldn't open or create database file \"" & filename & "\".")
        end if
    end if
end procedure

procedure db_insert_safe (object key, object data)
    --// Return value of 'db_insert ()'.
    integer success 
    success = db_insert (key, data)
    if success != DB_OK then
        if success = DB_EXISTS_ALREADY then
            error ("Inserting new record into database failed. Key " & print_format (key) & " already exists in current table.")
        else
            error ("Inserting new record into database failed.")
        end if
    end if
end procedure

global procedure db_select_safe (STRING name)
    if db_select (name) != DB_OK then
        error ("Selecting database " & name & " failed.")
    end if
end procedure

global procedure db_select_table_safe (STRING name)
    if db_select_table (name) != DB_OK then
        error ("Selecting table " & name & " in database failed.")
    end if
end procedure

global procedure puts1 (sequence s)
    puts (1, s & "\n")
end procedure

global procedure wait ()
    integer key
    key = wait_key ()
    if key = 27 then --// escape character
        abort (0)
    end if
    puts1 ("")
end procedure

--// wait and tell user to press a key
global procedure wait_tell ()
    puts (1, "Press any key to continue, ESC to exit...\n")
    wait ()
end procedure





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- show [Created on 6. December 2001, 16:01]
-- The 'show' procedure shows Euphoria object in console window.
--
-- PARAMETERS
-- 'name'
--    Name for variable.
-- 'o'
--    Value of variable, euphoria object to be shown.
--
-- EXAMPLE
--
-- Ussualy you would use this routine like this:
-- show ("var_name", var_name)
-- so it's good to automate this process in 
-- you editor with macro so that you just press one hotkey
-- and it displays you inputbox where you input name of your 
-- variable and then it automatically generates call for this function.
--*/
global procedure show (STRING name, object o)
    STRING prev_database_name
    --//
    --// Show on screen :
    --//=>
        if Show_On_Screen then    
            printf (1, "%s = %s\n", {name, print_format_smart (o)})
        end if
    --//
    --// Write to text file:
    --//=>
        if Write_To_File then
            printf (Text_File_Number, "%s = %s\n", {name, print_format_smart (o)})
        end if
    --//
    --// Write to database:
    --//=>
        if Write_To_Database then
            prev_database_name = db_current ()
            db_select_safe (Eds_File_Name)
            db_select_table_safe ("Misc")
            db_insert_safe (name & " (id=" & sprintf ("%f", time ()) & ")" , o)
            --// Void = db_insert (name, o)
            if length (prev_database_name) then
            --// There was previous database which we need to select back.
                db_select_safe (prev_database_name)
            end if
        end if
end procedure

--// show () and wait ()
global procedure showw (STRING name, object o)
    show (name, o)
    wait ()
end procedure

--/*
-- blankln [Created on 6. December 2001, 16:24]
-- The 'blankln' procedure puts one blank on console screen.
--*/
global procedure blankln ()
    if Show_On_Screen then
        printf (1, "%s", "\n")
    end if
    if Write_To_File then
        printf (Text_File_Number, "%s", "\n")
    end if
end procedure

--/*
-- assert_if_members_not_equal [Created on 6. December 2001, 14:37]
-- The 'assert_if_members_not_equal' procedure checks if members of a sequence 
-- are all same. If they are not error message is displayed.
--
-- PARAMETERS
-- 's'
--    Sequence with members which should all be the same.
--*/
global procedure assert_if_members_not_equal (sequence s)
    --// Compare each member with each member.
    --// This is rather slow but it's perfect.
    for i = 1 to length (s) do
        for j = 1 to length (s) do
            if equal (s [i], s [j]) = false then
                error ("Members of sequence " & print_format_smart (s) & " are not equal.\n" &
                    print_format_smart (s [i]) & " is not " & print_format_smart (s [j]) & ".")
            end if
        end for
    end for
end procedure

--/*
-- test_function [Created on 28. August 2002, 05:01]
-- The 'test_function' procedure is used to test new functions
-- you write.
-- 
-- You tell it for what parameters
-- passed to tested functions should return what
-- results, and this function evaluates that.
-- It shows you results and alerts if result
-- is not equal to what you told it it must be.
--
-- At end it aborts program.
--
-- Put this function directly under newly
-- written routine. When you know newly written
-- routine works comment this function.
--
-- PARAMETERS
-- 'routineid'
--    Id of routine.
-- 'params_and_results'
--    Parameters and results for those parameters
--    for tested function.
--    Each member should have this format:
--    1. sequence with parameters, should have lenght 
--       equal to number of arguments
--       that tested function takes.
--    2. object, result you expect for given parameters.
--
-- EXAMPLE
-- test_function (routine_id ("power"),
--     {
--         -- arguments and result 1
--          {
--              -- arguments
--              {
--                  -- argument 1
--                  3,
--                  -- argument 2
--                  2
--              },
--              -- result
--              9
--           },
--         -- arguments and result 2
--          {
--              -- arguments
--              {
--                  -- argument 1
--                  8,
--                  -- argument 2
--                  2
--              },
--              -- result
--              64
--           }
--     })
--*/
global procedure test_function (integer routineid, sequence params_and_results)
    sequence params
    object expected_result, real_result
    for i = 1 to length (params_and_results) do
        params = params_and_results [i] [1]
        expected_result = params_and_results [i] [2]
        real_result = call_func (routineid, params)
        show ("params", params)
        show ("expected_result", expected_result)
        show ("real_result", real_result)
        blankln ()
        if (equal (real_result, expected_result) = 0) then
            error ("function failed at member "
                & sprintf ("%d", i))
        end if
    end for
    puts (1, "Function works correct.\nPress any key to quit...\n")
    wait ()
    abort (0)
end procedure
--//
--// Test for 'test_function()':
--//=>
    --// function test_sum (integer a, integer b)
    --//     return a + b
    --// end function
    --// test_function (routine_id ("test_sum"), 
    --//     {
    --//         {
    --//             {1, 2},
    --//             3
    --//         },
    --//         {
    --//             {10, 5},
    --//             15
    --//         },
    --//         {
    --//             {4, 8},
    --//             12
    --//         },
    --//         {
    --//             {1, 1}, --// intentionally make it wrong
    --//             2
    --//         }
    --//     }
    --//     )
--/*
-- initialize [Created on 29. December 2001, 00:39]
-- The 'initialize' procedure initializes this lbrary.
-- You have to call it if you want to use any its functions succesfuly.
--
-- PARAMETERS
-- 'application_name'
--    Title of your application.
-- 'program_directory'
--    directory in which is your application.
--*/
global procedure initialize (STRING application_name, STRING program_directory)
    --//
    --// Text file:
    --//=>
        if Write_To_File then
            Text_File_Number = open (program_directory & "\\" & application_name & "_Debug.txt", "w")
        end if
    --//
    --// Database file:
    --//=>
        if Write_To_Database then
            Eds_File_Name = program_directory & "\\" & application_name & "_Debug.edb"
            db_create_or_open_safe (Eds_File_Name, DB_LOCK_NO)
            db_delete_table ("Misc")
            Void = db_create_table ("Misc")
        end if
    --//
    --// Display warnings:
    --//=>
        if Show_On_Screen = false then
            puts (1, "Debug Library Warning: debug variables won't be shown on screen, only written to files.\n")
        end if
end procedure
