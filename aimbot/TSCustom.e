





--// TSCustom.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 17. August 2002.
--// Miscalenous global variables which
--// should be set different for every program.
--// You should set each variable 
--// at start of your program.





include TSTypes.e





--// True if application is in debug mode.
global BOOL Debug
--// True if some extra checks should be done,
--// speed may be greatly reduced.
global BOOL Extra_check
--// Name of your program.
global STRING Application_name
--// Release date of your application.
global STRING Release_date
--// Application version.
global STRING Version
--// Directory in which is you program.
--// You can get this with function
--// 'get_program_directory ()' which is in
--// TSLibrary.Misc.e.
global STRING Program_directory

--/*
-- get_program_file_full_name [Created on 30. September 2001, 15:51]
-- The 'get_program_file_full_name' function joins
-- 'Program_directory' and 'file_name', so that it returns absolute file name.
--
-- PARAMETERS
-- 'file_name'
--    Only file name.
--    This file is assumed to be in directory where program is.
--
-- RETURN VALUES
-- Full absolute file name, with whole path.
--
--*/
global function get_program_file_full_name (STRING file_name)
    if equal (Program_directory, "") = true then --// Program_directory is "".
        return file_name
    else                                    --// Program_directory is NOT {}.
        return Program_directory & "\\" & file_name
    end if
end function





--// Initialize default variables:
Debug = true
Extra_check = false
Application_name = "Untitled Application"
Release_date = "Unknown"
Version = "Unknown"
Program_directory = ""





