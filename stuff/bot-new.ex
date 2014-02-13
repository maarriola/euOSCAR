without warning
include std/socket.e as slib
include TSHtmPar.e
include oscar.e as oscar

sequence pk, res
global socket server

include bot_func.e

--res = AIM_login(prompt_string("username: "), prompt_string("password: "), AUTH_MD5)
res = AIM_login("timecubeinc", "bloodworm", AUTH_MD5)
if res[1] = 0 then
    puts(1, "logged in\n")
elsif res[1] = ERR_CONNECT then
    puts(1, "connection error\n")
    if getc(0) then end if
    abort(1)
elsif res[1] = ERR_AUTH then
    puts(1, res[3])
    if getc(0) then end if
    abort(1)
end if

server = res[2]
message_loop(res[2])

if getc(0) then end if

