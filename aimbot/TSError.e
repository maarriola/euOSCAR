





--// TSError.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 27. December 2001.
--// Windows and DOS error handling library.





--// TSLibrary include files.
include TSTypes.e
include TSCustom.e
--// Standard include files.
--// include msgbox.e as win32msgbox --// Once it caused name collision with win32lib.
include get.e
include misc.e
include wildcard.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Local variables. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--// True if to report errors to user, false if not.
BOOL Do_report_errors
Do_report_errors = true
--// Used by 'restore_error_reporting ()'.
BOOL Prev_do_report_errors
Prev_do_report_errors = Do_report_errors





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ message_box.e inlined @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- message_box() function

include dll.e
include machine.e
include misc.e

without warning

-- Possible style values for message_box() style sequence
constant 
    MB_ABORTRETRYIGNORE = #02, --  Abort, Retry, Ignore
    MB_APPLMODAL = #00,       -- User must respond before doing something else
    MB_DEFAULT_DESKTOP_ONLY = #20000,    
    MB_DEFBUTTON1 = #00,      -- First button is default button
    MB_DEFBUTTON2 = #100,      -- Second button is default button
    MB_DEFBUTTON3 = #200,      -- Third button is default button
    MB_DEFBUTTON4 = #300,   -- Fourth button is default button
    MB_HELP = #4000,            -- Windows 95: Help button generates help event
    MB_ICONASTERISK = #40,
    MB_ICONERROR = #10, 
    MB_ICONEXCLAMATION = #30, -- Exclamation-point appears in the box
    MB_ICONHAND = MB_ICONERROR,        -- A hand appears
    MB_ICONINFORMATION = MB_ICONASTERISK,-- Lowercase letter i in a circle appears
    MB_ICONQUESTION = #20,    -- A question-mark icon appears
    MB_ICONSTOP = MB_ICONHAND,
    MB_ICONWARNING = MB_ICONEXCLAMATION,
    MB_OK = #00,              -- Message box contains one push button: OK
    MB_OKCANCEL = #01,        -- Message box contains OK and Cancel
    MB_RETRYCANCEL = #05,     -- Message box contains Retry and Cancel
    MB_RIGHT = #80000,        -- Windows 95: The text is right-justified
    MB_RTLREADING = #100000,   -- Windows 95: For Hebrew and Arabic systems
    MB_SERVICE_NOTIFICATION = #40000, -- Windows NT: The caller is a service 
    MB_SETFOREGROUND = #10000,   -- Message box becomes the foreground window 
    MB_SYSTEMMODAL  = #1000,    -- All applications suspended until user responds
    MB_TASKMODAL = #2000,       -- Similar to MB_APPLMODAL 
    MB_YESNO = #04,           -- Message box contains Yes and No
    MB_YESNOCANCEL = #03      -- Message box contains Yes, No, and Cancel

-- possible values returned by MessageBox() 
-- 0 means failure
constant IDABORT = 3,  -- Abort button was selected.
		IDCANCEL = 2, -- Cancel button was selected.
		IDIGNORE = 5, -- Ignore button was selected.
		IDNO = 7,     -- No button was selected.
		IDOK = 1,     -- OK button was selected.
		IDRETRY = 4,  -- Retry button was selected.
		IDYES = 6    -- Yes button was selected.

atom lib
integer msgbox_id, get_active_id

if platform() = WIN32 then
    lib = open_dll("user32.dll")
    msgbox_id = define_c_func(lib, "MessageBoxA", {C_POINTER, C_POINTER, 
						   C_POINTER, C_INT}, C_INT)
    if msgbox_id = -1 then
	puts(2, "couldn't find MessageBoxA\n")
	abort(1)
    end if

    get_active_id = define_c_func(lib, "GetActiveWindow", {}, C_LONG)
    if get_active_id = -1 then
	puts(2, "couldn't find GetActiveWindow\n")
	abort(1)
    end if
end if

function message_box(sequence text, sequence title, object style)
    integer or_style
    atom text_ptr, title_ptr, ret
    
    text_ptr = allocate_string(text)
    if not text_ptr then
	return 0
    end if
    title_ptr = allocate_string(title)
    if not title_ptr then
	free(text_ptr)
	return 0
    end if
    if atom(style) then
	or_style = style
    else
	or_style = 0
	for i = 1 to length(style) do
	    or_style = or_bits(or_style, style[i])
	end for
    end if
    ret = c_func(msgbox_id, {c_func(get_active_id, {}), 
			     text_ptr, title_ptr, or_style})
    free(text_ptr)
    free(title_ptr)
    return ret
end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Local routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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
-- error [Created on 30. September 2001, 12:56]
-- The 'error' procedure tells to the user an error which happended in the program.
--
-- PARAMETERS
-- 'in_routine'
--    Name of the Euphoria routine in which error happened. Without braces: ().
-- 'message'
--    Message string to tell.
--*/
global procedure error (STRING message)
    --// Message shown in message box. Different in Debug versus Release mode.
    STRING built_message
    --// Title of error message box.
    STRING message_box_title
    --// User response.
    integer response
    if Do_report_errors = false then
        return
    end if
    built_message = message
    if equal (Application_name, "") = true then --// 'Application_name' is "".
        message_box_title = "Error"
    else                                        --// 'Application_name' is NOT "".
        message_box_title = Application_name & " Error"
    end if
    if platform () = DOS32 then
        puts (1, "\n" & message_box_title & ": \n" & built_message & "\n")
        if Debug = true then    --//  In debug mode.
            puts (1, "\nPress ESCAPE to abort application,\n    'D' key to debug\n    or any other key to continue.\n")
        else                    --// In release mode.
            puts (1, "\nPress ESCAPE to abort application or any other key to continue.\n")
        end if
        response = wait_key ()
        if response = 27 then                                           --// User wants to abort program.
            puts (1, "Aborting...\n")
            sleep (1)
            abort (0)
        elsif Debug = true and response = 'd' or response = 'D' then    --// In debug mode and user wants to debug program.
            --// trace (1)  --// If you have full Euphoria then use trace
            ?1/0            --// Use this if you have poublic domain of Euphoria.
        else                                                            --// User wants to continue program.
            puts (1, "Continuing...")
            sleep (1)
            puts (1, "\n")
        end if
        --// TODO:
    elsif platform () = WIN32 then
        if Debug = true then    --// In debug mode.    
            response = message_box (built_message &
                "\n\n" &
                "Press\n" &
                "  [ YES ]  to continue,\n" &
                "  [ NO ] to debug, or\n" &
                "  [ Cancel ]  to quit.",
                message_box_title, or_all ({MB_ICONEXCLAMATION, MB_YESNOCANCEL}))
            if response = IDCANCEL then --// Exit program.
                --// w32Proc (xExitProcess, {0})
                abort (0)
            elsif response = IDNO then  --// Debug program.
                --// trace (1)  --// If you have full Euphoria then use trace
                ?1/0            --// Use this if you have poublic domain of Euphoria.
            end if
        else                    --// Not in debug mode.
            response = message_box (built_message & "\n\nPress Yes to continue, Cancel to abort application.", message_box_title, or_all ({MB_ICONEXCLAMATION, MB_OKCANCEL}))
            if response = IDCANCEL then --// Exit program.
                --// w32Proc (xExitProcess, {0})
                abort (0)
            end if
        end if
    end if
end procedure

--/*
-- fatal_error [Created on 26. August 2002, 00:57]
-- The 'fatal_error' procedure should be called when
-- fatal program error happens and program can't continue.
-- Program is terminated.
--
-- PARAMETERS
-- 'message'
--    Message to tell to user.
--*/
global procedure fatal_error (STRING message)
    --// Title of error message box.
    STRING message_box_title
    --// User response.
    integer response
    if equal (Application_name, "") = true then --// 'Application_name' is "".
        message_box_title = "Fatal Error"
    else                                        --// 'Application_name' is NOT "".
        message_box_title = Application_name & " Fatal Error"
    end if
    if platform () = DOS32 then
        puts (1, "\n" & message_box_title & ": \n" & message & "\n")
        if Debug then
            puts (1, "Press 'D' to debug, any other key to exit...\n")
        else
            puts (1, "Press any key to exit...\n")
        end if
        response = wait_key ()
        if Debug and upper (response) = 'D' then
            ? 1 / 0
        else
            abort (0)
        end if
    elsif platform () = WIN32 then
        if Debug then
            response = message_box (message &
                "\n\n" &
                "Press\n" &
                "  [ YES ]  to quit, or\n" &
                "  [ NO ] to debug.",
                message_box_title, or_all ({MB_ICONEXCLAMATION, MB_YESNO}))
            if response = IDYES then --// Exit program.
                --// w32Proc (xExitProcess, {0})
                abort (0)
            elsif response = IDNO then  --// Debug program.
                --// trace (1)  --// If you have full Euphoria then use trace
                ?1/0            --// Use this if you have poublic domain of Euphoria.
            end if
        else --// Release mode.
            Void = message_box (message &
                "\n\nPress OK to quit.",
                message_box_title, or_all ({MB_ICONEXCLAMATION}))
            abort (0)
        end if
    end if
end procedure

--/*
-- assert [Created on 29. November 2001, 19:35]
-- The 'assert' procedure is similar to C's assert ().
-- If its parameter is not true error message box is displayed.
-- Use it to test for program errors.
--
-- PARAMETERS
-- 'better_be_true'
--    If it is true nothing happens.
--    If it is false then error message box is displayed.
--*/
global procedure assert (integer better_be_true)    
	if better_be_true = false then --// Program error.
        error ("ASSERT!!! Program error. Assert was called.")
	end if
end procedure

--/*
-- turn_error_reporting_off [Created on 27. August 2002, 06:33]
-- The 'turn_error_reporting_off' procedure
-- turns error reporting off.
-- It can be called as many times as you want,
-- to turn off error reporting temporary,
-- for example.
--*/
global procedure turn_error_reporting_off ()
    Prev_do_report_errors = Do_report_errors
    Do_report_errors = false
end procedure

--/*
-- restore_error_reporting [Created on 27. August 2002, 06:38]
-- The 'restore_error_reporting' procedure resets
-- error reporting to the state it was before
-- last call to 'turn_error_reporting_off ()'
-- or 'turn_error_reporting_on ()'.
--*/
global procedure restore_error_reporting ()
    Do_report_errors = Prev_do_report_errors
end procedure

--/*
-- turn_error_reporting_on [Created on 27. August 2002, 06:33]
-- The 'turn_error_reporting_on' procedure 
-- turns error reporting on.
-- It can be called as many times as you want.
--*/
global procedure turn_error_reporting_on ()
    Prev_do_report_errors = Do_report_errors
    Do_report_errors = true
end procedure