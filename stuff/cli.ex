--include std/socket.e as slib
include oscar_eunet.e
include TSHtmPar.e
include win32lib.ew
--include ..\win32\thread.ew

global object server

include cli_func.e

constant win = create(Window, "simple AIM client", 0, 0, 0, 640, 480, WS_DLGFRAME+WS_SYSMENU+WS_MINIMIZEBOX),
         lbl1 = create(LText, "user:", 0, 5, 5, 48, 25, 0),
         box1 = create(EditText, "", 0, 58, 5, 577, 25, 0),
         box2 = create(MleText, "", 0, 5, 35, 625, 355, 0),
         box3 = create(EditText, "", 0, 5, 390, 625, 25, 0),
         btn1 = create(Button, "send", 0, 587, 425, 48, 25, 0)

sequence res, user = "", pass = "", cmd = command_line()
atom mlTask

procedure btn1_click ()
    sequence msg, user
    msg = getText(box3)
    user = getText(box1)
    setText(box2, getText(box2) & sprintf("%s: %s\n", {user, msg}))
    send_message(user, msg)
end procedure

--set_rate_limit(0)
set_profile("simple AIM client using oscar.e")
for i = 3 to length(cmd) do
    if equal(cmd[i], "-u") then
        user = cmd[i + 1]
    elsif equal(cmd[i], "-p") then
        pass = cmd[i + 1]
    elsif equal(cmd[i], "-P") then
        set_profile(cmd[i + 1])
    end if
end for

if not length(user) then user = prompt_string("username: ") end if
if not length(pass) then pass = prompt_string("password: ") end if

res = AIM_login(user, pass)

if res[1] = 0 then
    server = res
--  mlTask = createThread(routine_id("message_loop"), 0)
    --setHandler(win, w32HTimer, routine_id("message_loop"))
    setHandler(btn1, w32HClick, routine_id("btn1_click"))
    --setTimer(win, 1337, 250)
    --setHandler(win, w32HIdle, routine_id("message_loop"))
    mlTask = task_create(routine_id("message_loop"), {})
    task_schedule(mlTask, {.05, .1})

elsif res[1] = ERR_RESOLVE then
    puts(1, "couldn't resolve host\n")
    abort(1)

elsif res[1] = ERR_CONNECT then
    puts(1, "couldn't connect\n")
    abort(1)

elsif res[1] = ERR_AUTH then
    puts(1, res[3])
    abort(1)
end if

WinMain(win, Normal)
