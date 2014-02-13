--include std/socket.e as slib
include ../oscar.e
include TSHtmPar.e
include euphoria/info.e

global object server

include bot_func.e

sequence res, user = "", pass = "", cmd = command_line()

--set_rate_limit(0)
set_profile(sprintf("AIMpedia running on %d.%d.%d", {version_major(), version_minor(), 
version_patch()}))
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
    message_loop() --res[2])

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
