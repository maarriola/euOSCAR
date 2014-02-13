




--// TSFile.e
--// Tone Škoda <tone.skoda@siol.net>
--// Created on 28. August 2002.
--// File manimulation routines and
--// file names and paths parsing routines.





--// TSLibrary include files:
include TSSeq.e
include TSDebug.e
include TSError.e
include TSCustom.e
include TSTypes.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ File handling routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- file_exists [Created on 30. September 2001, 11:48]
-- The 'file_exists' function tests if file exists.
-- It works for directories too.
--
-- PARAMETERS
-- 'file_name'
--    Name of the file.
--
-- RETURN VALUES
-- If file exists, true.
--
-- If file doesn't exist, false.
--
--*/
global function file_exists (sequence file_name)
    return sequence (dir (file_name))
	--// integer a
	--// a = open (file_name, "r")
	--// if a = -1 then
	--// 	return false
	--// else
	--// 	close(a)
	--// 	return true
	--// end if	
end function
--//
--// Tests for file_exists ():
--//=>
    --// assert (file_exists ("C:\\MyProj\\Euphoria\\TSLibrary Demos and Tests") = true)
    --// assert (file_exists ("C:\\MyProj\\Euphoria\\does not exist") = false)
    --// assert (file_exists ("C:\\MyProj\\Euphoria\\TSLibrary Demos and Tests\\Are You That Somebody - Lyrics.htm") = true)
    --// assert (file_exists ("C:\\MyProj\\Euphoria\\TSLibrary Demos and Tests\\Are You That Somebody - Lyrics.html") = false)

--/*
-- make_file_empty_if_it_exists [Created on 6. December 2001, 16:44]
-- The 'make_file_empty_if_it_exists' procedure empties file if it exists.
-- If it doesn't exists then nothing happens.
--
-- PARAMETERS
-- 'file_name'
--    Name of the file to be emptied.
--*/
global procedure make_file_empty_if_it_exists (STRING file_name)
    --// File number.
    integer fn
    fn = open (file_name, "w")
    if fn != -1 then --// File does exist.
        close (fn)
    end if
end procedure

--/*
-- read_file [Created on 21. December 2001, 14:25]
-- The 'read_file' function reads whole file and
-- returns string of file contents.
--
-- If file doens't exist {} is returned
-- and error is reported to user.
--
-- PARAMETERS
-- 'inFile'
--    Name of the file to read.
--
-- RETURN VALUES
-- String with all characters that were in file.
--*/
global function read_file (sequence inFile)
	sequence buffer
	integer fi,len,o

	fi = open(inFile, "rb")
	if fi = -1 then
	    error ("Couldn't open file \"" & inFile & "\".")
        return {}
	end if

	o = seek(fi,-1) 		-- go to end of input file
	len = where(fi) 		-- get length of input file in bytes
	o = seek(fi,0)			-- go back to beginning of input file
	buffer = repeat(0, len) -- initialize your buffer
	for i=1 to len do
	    buffer[i] = getc(fi)
	end for
	close(fi)

	return buffer
end function

--/*
-- write_file [Created on 21. December 2001, 15:54]
-- The 'write_file' procedure writes 'content' into file 'file_name'.
-- If file already exists it is deleted.
-- If it fails it dispalys error message.
--
-- PARAMETERS
-- 'file_name'
--    Name of the file to which to write.
-- 'content'
--    String to write into file.
--*/
global procedure write_file (STRING file_name, STRING content)
    --// File number.
    integer fn
    fn = open (file_name, "w")
    if fn = -1 then --// Couldn't open file.
        error ("Couldn't open file \"" & file_name & "\" for writing.")
        return
    end if
    puts (fn, content)
    close (fn)
end procedure

--// Same as builtin open(), if error it reports it to user.
global function open_safe (STRING fname, STRING mode)
	integer fn
	fn = open (fname, mode)
	if fn = -1 then
		error ("Couldn't open file " & fname & ".\n")
	end if
	return fn
end function

--/*
-- read_file_lines [Created on 26. August 2002, 08:33]
-- The 'read_file_lines' function reads whole file
-- into sequence with file lines.
-- '\n' are removed from end of lines.
-- If file doesn't exist or couln't 
-- be opened {} is returned.
--
-- PARAMETERS
-- 'filename'
--    Name of file to be read.
--
-- RETURN VALUES
-- sequence with strings.
--*/
global function read_file_lines (STRING filename)
    sequence file_lines
    object line
    integer fn
    fn = open (filename, "r")
    if fn = -1 then
        return {}
    end if
    file_lines = {}
    while 1 do
        line = gets(fn)
        if atom(line) then
            exit   -- -1 is returned at end of file
        end if
        if line [length (line)] = '\n' then
            line = line [1 .. length (line) - 1]
        end if
        file_lines = append(file_lines, line)
    end while
    close (fn)
    return file_lines
end function
--//
--// Test for 'read_file_lines()':
--//=>
    --// Tmp = read_file_lines ("C:\\MyProj\\Euphoria\\Internet_Files_Bot\\Plan.txt")
    --// for i = 1 to length (Tmp) do
    --//     puts (1, Tmp [i] & "\n")
    --// end for
    --// wait ()
    --// abort (0)





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ get_dir_files () function @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

sequence get_dir_files__result

--// This routine modified global variable 'get_dir_files__result'.
procedure get_dir_files__recursive (STRING directory,
    sequence wildcard_strings, BOOL do_include_subdirs)
    object dir_info, file_info
    STRING filename
    dir_info = dir (directory)
    if sequence (dir_info) then
        for i = 1 to length (dir_info) do
            file_info = dir_info [i]
            filename = file_info [D_NAME]
            if find ('d', file_info [D_ATTRIBUTES]) then
            --// this is directory
                if do_include_subdirs
                and equal (filename, ".") = false
                and equal (filename, "..") = false then
                    get_dir_files__recursive (directory & "\\" & filename,
                        wildcard_strings, do_include_subdirs)
                end if
            else
            --// this is not directory, it's file
                for j = 1 to length (wildcard_strings) do
                    if wildcard_file (wildcard_strings [j], filename) then
                        --// This file's name matched our criteria.
                        --// Append it to result sequence.
                            get_dir_files__result = append (
                                get_dir_files__result, 
                                directory & "\\" & filename)
                        exit
                    end if
                end for
            end if
        end for
    end if
end procedure

--/*
-- get_dir_files [Created on 14. August 2002, 17:08]
-- The 'get_dir_files' function returns a 
-- list of files in directory.
-- Files must match wildcard string 'wildcard_strings'.
--
-- PARAMETERS
-- 'directory'
--    Directory from which to get names of files.
-- 'wildcard_strings'
--    Sequence with strings.
--    All files in directory which match these
--    willdcard strings will be returned.
-- 'do_include_subdirs'
--    True if to include subdirectories of 'directory' and their files,
--    false if not.
--
-- EXAMPLE
-- 
-- mp3_files = get_dir_files ("C:\\dir",
--          {"*.MP3", "*.MP2", "*.MP1", "*.OGG", "*.WAV"}, true)
--
-- RETURN VALUES
-- sequence with strings, strings are full file names.
--*/
global function get_dir_files (STRING directory,
    sequence wildcard_strings, BOOL do_include_subdirs)
    get_dir_files__result = {}
    get_dir_files__recursive (directory,
        wildcard_strings, do_include_subdirs)
    return get_dir_files__result
end function

--// Tests for 'get_dir_files()':
--// Tmp = get_dir_files ("C:\\EUPHORIA\\BIN", {"*.bat", "*.ex"}, true)
--// show ("Tmp", Tmp)
--// assert (length (Tmp) = 19)
--// 
--// Tmp = get_dir_files ("C:\\EUPHORIA\\BIN", {"*.bat"}, true)
--// show ("Tmp", Tmp)
--// assert (length (Tmp) = 9)
--// 
--// Tmp = get_dir_files ("C:\\EUPHORIA\\BIN", {"*.*"}, true)
--// show ("Tmp", Tmp)
--// assert (length (Tmp) = 29)
--// 
--// Tmp = get_dir_files ("C:\\EUPHORIA\\DEMO", {"*.doc"}, true)
--// show ("Tmp", Tmp)
--// assert (length (Tmp) = 5)
--// 
--// Tmp = get_dir_files ("C:\\EUPHORIA\\DEMO", {"*.doc"}, false)
--// show ("Tmp", Tmp)
--// assert (length (Tmp) = 1)
--// 
--// puts (1, "success\n")
--// wait ()
--// abort (0)





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Routines for parsing file paths. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- returns file name
-- example: "C:\dir\file.txt" returns "file.txt"
global function get_file_name (sequence fname)
	for i = length (fname) to 1 by -1 do
		if fname [i] = '\\' or fname [i] = '/' then
			return fname [i + 1 .. length (fname)]
		end if
	end for
	return fname
end function

-- returns file title
-- example: "C:\dir\file.txt" returns "file"
global function get_file_title (sequence fname)
	integer c -- current char
	integer dot_pos, i
	-- find last dot position
	i = length (fname)
	while 1 do
		if i < 1 then
			dot_pos = length (fname) + 1
			exit
		end if
		c = fname [i]
		if c = '.' then
			dot_pos = i
			exit
		elsif c = '\\' or c = '/' then
			dot_pos = length (fname) + 1
			exit
		end if
		i -= 1
	end while
	--find last slash position
	for j = dot_pos - 1 to 1 by -1 do
		c = fname [j]
		if c = '\\' or c = '/' then
			return fname [j + 1 .. dot_pos - 1]
		end if
	end for
	return fname [1 .. dot_pos - 1]
end function

-- returns file extension
-- example: "C:\dir\file.txt" returns "txt"
global function get_file_ext (sequence fname)
	for i = length (fname) to 1 by -1 do
		if fname [i] = '.' then
			return fname [i + 1 .. length (fname)]
		elsif fname [i] = '\\' or fname [i] = '/' then
			return ""
		end if
	end for
	return ""
end function

-- returns file directory
-- example: "C:\dir\file.txt" returns "C:\dir"
global function get_file_directory (sequence fname)
	integer c -- current char
	for i = length (fname) to 1 by -1 do
		c = fname [i]
		if c = '\\' or c = '/' then
			return fname [1 .. i - 1]
		elsif c = '.' then
			for j = i - 1 to 1 by -1 do
				c = fname [j]
				if c = '\\' or c = '/' then
					return fname [1 .. j - 1]
				end if
			end for
			return ""
		end if
	end for
	return fname
end function

--// Only "\\" as separator, not "/".
global function get_file_directory_fast (sequence fname)
    for i = length (fname) to 1 by -1 do
        if fname [i] = '\\' then
            return fname [1 .. i - 1]
        end if
    end for
    return fname --// "justword"
end function

--/*
-- remove_last_filename_from_path [Created on 27. August 2002, 21:23]
-- The 'remove_last_filename_from_path' function removes
-- last file from path (if any).
-- It works this way:
-- If last dot is after last slash, then verything after last
-- slash is considered to be name of last file in path
-- and that is removed.
--
-- Difference between this function and 'get_file_directory()' is:
-- this functions from "C:\\dir" returns "C:\\dir",
-- 'get_file_directory()' returns "C:".
--
-- EXAMPLES
-- "C:\\my documents\\file.txt" returns
-- "C:\\my documents"
--
-- "C:\\my documents\\" returns
-- "C:\\my documents"
--
-- "C:\\my documents" returns
-- "C:\\my documents"
--
-- "C:\\my documents.txt" returns
-- "C:"
--
-- "" returns
-- ""
--
-- "C:" returns
-- "C:"
--
-- PARAMETERS
-- 'path'
--    Full or partial file name.
--
-- RETURN VALUES
-- Path without last filename in path.
--*/
global function remove_last_filename_from_path (STRING path)
    integer last_dot_pos
    integer last_slash_pos
    STRING path_without_last_fname
    last_dot_pos = find_ex ('.', path, {length (path), -1})
    if last_dot_pos then
    --// a dot was found in 'path'
        last_slash_pos = max (
            find_ex ('/', path, {length (path), -1}),
            find_ex ('\\', path, {length (path), -1}))
        if last_slash_pos = 0 then
            last_slash_pos = find (':', path)
        end if
        if last_slash_pos then
        --// at least one slash or ":" is in path
            if last_dot_pos > last_slash_pos then
            --// Is some dot after last slash, there IS filename in path
                path_without_last_fname = path [1 .. last_slash_pos]
            else
            --// NO dot after last slash, there is NO filename in path
                path_without_last_fname = path
            end if
        else
        --// NO slash or ":" in path
            path_without_last_fname = ""
        end if
    else --// no dot in 'path'
        path_without_last_fname = path
    end if
    path_without_last_fname = trim_back (path_without_last_fname, '/')
    path_without_last_fname = trim_back (path_without_last_fname, '\\')
    return path_without_last_fname
end function
--//
--// Tests for 'remove_last_filename_from_path()':
--//=>
    --// constant TEST_PATHS_AND_SOLUTIONS = {
    --//     {
    --//         "C:\\my documents\\file.txt",
    --//         "C:\\my documents"
    --//     },
    --//     {        
    --//         "C:\\my documents\\",
    --//         "C:\\my documents"
    --//     },
    --//     {
    --//         "C:\\my documents",
    --//         "C:\\my documents"
    --//     },
    --//     {
    --//         "C:\\my documents.txt",
    --//         "C:"
    --//     },
    --//     {
    --//         "",
    --//         ""
    --//     },
    --//     {
    --//         "C:",
    --//         "C:"
    --//     }
    --//     }
    --// sequence test_path, test_solution, solution
    --// for i = 1 to length (TEST_PATHS_AND_SOLUTIONS) do
    --//     test_path = TEST_PATHS_AND_SOLUTIONS [i] [1]
    --//     test_solution = TEST_PATHS_AND_SOLUTIONS [i] [2]
    --//     solution = remove_last_filename_from_path (test_path)
    --//     show ("test_path", test_path)
    --//     show ("test_solution", test_solution)
    --//     show ("solution", solution)
    --//     blankln ()
    --//     assert (equal (solution, test_solution))
    --// end for    
    --// wait ()
    --// abort (0)
--/*
-- get_program_directory [Created on 30. September 2001, 15:48]
-- The 'get_program_directory' function returns directory
-- where this program which is run is.
-- It gets it from parsing command line.
--
-- RETURN VALUES
-- Program directory, string. Like this: "C:\Directory"
--
--*/
global function get_program_directory ()
    --// Command line.
    sequence cmd
    --// Program path + name.
    STRING program_full_path
    --// Returned program directory
    STRING program_directory
    cmd = command_line ()
    if length  (cmd) >=  2 then --// Length of command line is long enough.
        program_full_path = cmd [2]
        program_directory = get_file_directory  (program_full_path)
    else                        --// Length of command line is too short.
        error ("Can't get program directory from command line.")
        program_directory = ""
    end if
    return program_directory
end function

--/*
-- get_unused_filename [Created on 6. August 2002, 03:40]
-- The 'get_unused_filename' function gets name for
-- file in directory which is not already used, no
-- file with that name in that directory has that name.
-- Added is some number to filename, like this
-- "filename[1].txt", "filename[2].txt" until
-- file is found that doesn't already exist.
-- If file with name of 'filename' doesn't exist in
-- 'directory' then 'filename' is returned.
--
-- PARAMETERS
-- 'directory'
--    Destination directory, should have this format:
--    "C:\\my directory"
--    It doesn't need to be full path.
--
-- 'filename'
--    Name of file, only file name, no
--    direcotry should be included.
--
-- RETURN VALUES
-- Unique (unused) file name.
--*/
global function get_unused_filename (STRING directory, STRING filename)
    STRING cur_filename, filetitle, fileext
    integer i
    cur_filename = filename
    filetitle= get_file_title (filename)
    fileext = get_file_ext (filename)
    i = 0
    while file_exists (directory & "\\" & cur_filename) = true do
        i += 1
        cur_filename = filetitle & "[" & sprintf ("%d", i) & "]" & "." & fileext
    end while
    return cur_filename
end function

--// Tests for get_unused_filename ():
--// Tmp = get_unused_filename ("C:\\MyProj\\Euphoria\\Internet_Files_Bot\\Pages", "file1.txt")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "file1.txt"))
--// Tmp = get_unused_filename ("C:\\MyProj\\Euphoria\\Internet_Files_Bot\\Pages", "file2.txt")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "file2[1].txt"))
--// Tmp = get_unused_filename ("C:\\MyProj\\Euphoria\\Internet_Files_Bot\\Pages", "file3.txt")
--// show ("Tmp", Tmp)
--// assert (equal (Tmp, "file3[2].txt"))

--/*
-- convert_to_valid_filename [Created on 28. August 2002, 02:37]
-- The 'convert_to_valid_filename' function converts a string
-- to string which is valid to be used as a filename.
-- Not allowed characters (?,\,: etc) are replaced with 
-- 'replacement_char'.
--
-- PARAMETERS
-- 'string'
--    .
-- 'replacement_char'
--    .
--
-- RETURN VALUES
-- String.
--*/
constant INVALID_FILENAME_CHARS = {'\\', '/', ':', '*', '?', '<', '>', '|'}
global function convert_to_valid_filename (STRING string, CHAR replacement_char)
    char c
    for i = 1 to length (string) do
        c = string [i]
        if find (c, INVALID_FILENAME_CHARS) then
            string [i] = replacement_char
        end if
    end for
    return string
end function
--//
--// Tests for 'convert_to_valid_filename()':
--//=>
    --// constant TEST_DATA = {
    --//     {
    --//         "my:makaveli",
    --//         "my_makaveli"
    --//     },
    --//     {
    --//         "search.smx?search=2pac&type=0",
    --//         "search.smx_search=2pac&type=0"
    --//     },
    --//     {
    --//         "?<>/\\|",
    --//         "______"
    --//     }
    --//     }
    --// STRING test_str, result_str, defined_result
    --// for i = 1 to length (TEST_DATA) do
    --//     test_str = TEST_DATA [i] [1]
    --//     defined_result = TEST_DATA [i] [2]
    --//     result_str = convert_to_valid_filename (test_str, '_')
    --//     show ("test_str", test_str)
    --//     show ("defined_result", defined_result)
    --//     show ("result_str", result_str)
    --//     blankln ()
    --//     assert (equal (result_str, defined_result))
    --// end for
    --// wait ()
    --// abort (0)
    
    
    
    
    
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Misc routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

global function bytes_to_megabytes (atom bytes)
    return bytes / (1024 * 1024)
end function

global function megabytes_to_bytes (atom megabytes)
    return megabytes * 1024 * 1024
end function

global function bytes_to_kilobytes (atom bytes)
    return bytes / (1024)
end function

global function kilobytes_to_megabytes (atom kilobytes)
    return kilobytes / 1024
end function

global function kilobytes_to_gigabytes (atom kilobytes)
    return kilobytes / (1024 * 1024)
end function

global function kilobytes_to_bytes (atom kilobytes)
    return kilobytes * 1024
end function

--/*
-- pretty_format_file_size [Created on 25. July 2002, 12:04]
-- The 'pretty_format_file_size' function 
-- returns file, drive etc size in pretty form
-- to be read by human.
-- If number is large enough size is displayed in gigabytes,
-- else megabytes, kilobytes or bytes.
--
-- PARAMETERS
-- 'bytes'
--    Size in bytes.
-- 'num_decimal_places'
--    Number of decimal places number to have after comma.
--    I would recomend 2 for default.
--
-- RETURN VALUES
-- String , "bytes", "KB" etc is added to end.
--*/
global function pretty_format_file_size (atom bytes, integer num_decimal_places)
    STRING ret, format
    format = "%." & sprintf ("%d", num_decimal_places) & "f"
    if bytes < 1024 then --// smaller than 1 kilobyte
        ret = commatize (sprintf ("%.0f",  (bytes)))
        if bytes != 1 then
            ret &= " bytes"
        else
            ret &= " byte"
        end if
        return ret
    elsif bytes < 1024 * 1024 then --// smaller than 1 megabyte        
        return commatize (sprintf (format, bytes / 1024)) & " KB"
    elsif bytes < 1024 * 1024 * 1024 then --// smaller than 1 gigabyte
        return commatize (sprintf (format, bytes / (1024 * 1024))) & " MB"
    else --// everything bigger than 1 gigabyte goes here
        return commatize (sprintf (format, (bytes / (1024 * 1024 * 1024)))) & " GB"
    end if
end function