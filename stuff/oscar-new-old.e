include std/socket.e as slib
include std/net/dns.e
include md5.e
include util.e as util

constant AIM_MD5_STRING = "AOL Instant Messenger (SM)",
	 FLAP   = 1,
	 SNAC   = 2,
	 TLV    = 3,
	 
	 PK_CHAN_ID = 1,
	 PK_SEQ_ID  = 2,
	 PK_DATA    = 3,
	 
	 SNAC_FAMILY    = 1,
	 SNAC_SUBFAM    = 2,
	 SNAC_FLAGS     = 3,
	 SNAC_REQ_ID    = 4,
	 SNAC_DATA      = 5,
	 
	 TLV_TYPE       = 1,
	 TLV_DATA       = 2,
	 
	 MSG_TIMEOUT    = 15
	 
global constant ERR_CONNECT     = -1,
		ERR_AUTH        = -2,
		ERR_LOGIN       = -3,
		
		AUTH_MD5        = 1,
		AUTH_CH01       = 2,
		
		error_codes = {"invalid SNAC header",
				"rate limit exceeded",
				"rate limit exceeded",
				"recipient is not logged in",
				"requested service unavailable",
				"requested service not defined",
				"obsolete SNAC",
				"not supported",
				"not supported",
				"refused by client",
				"reply too big",
				"responses lost",
				"request denied",
				"incorrect SNAC format",
				"insufficient rights",
				"in local permit/deny (recipient blocked)",                     
				"sender too evil",
				"receiver too evil",
				"user temporarily unavailable",
				"no match",
				"list overflow",
				"request ambiguous",
				"server queue full",
				"not while on AOL"},
		auth_errors = {"invalid nick/pass",
			       "service temporarily unavailable",
			       "all other errors",
			       "incorrect nick/pass, re-enter",
			       "mismatch nick/pass, re-enter",
			       "bad input to authorizer",
			       "invalid account",
			       "deleted account",
			       "expired account",
			       "no access to DB",
			       "no access to resolver",
			       "invalid DB fields",
			       "bad DB status",
			       "bad resolver status",
			       "internal error",
			       "service temporarily offline",
			       "suspended account",
			       "DB send error",
			       "DB link error",
			       "reservation map error",
			       "reservation link error",
			       "too many users from this IP",
			       "too many users from this IP (reservation)",
			       "rate limit exceeded, try to reconnect in a few minutes",
			       "user too heavily warned",
			       "reservation timeout",
			       "", "",
			       "rate limit exceeded. try to reconnect in a few minutes",
			       "",
			       "invalid SecurID",
			       "account suspended because of age (< 13)"}

global integer error_hook, msg_hook, max_message_size
sequence snac_hooks, waiting_msgs, idle_hooks, queue
atom seq, lastsnac
integer npackets, login_finished, verbose
object ret

queue = {}
waiting_msgs = {}
max_message_size = 0
verbose = 1
login_finished = 0
snac_hooks = {}
lastsnac = 0
error_hook = -1
msg_hook = -1
idle_hooks = {}

-- opens a new connection and resets sequence ID
function new_connection (sequence host)
    socket sock
    object res
    
    res = create(AF_INET, SOCK_STREAM, 0)
    if atom(res) then
	return -1
    else
	sock = res
	set_option(sock, SOL_SOCKET, SO_RCVBUF, 0)
    end if

    res = connect(sock, host, 5190)
    
    if res = -1 then return -1 end if
    
    seq = #8000
    npackets = 0

    return sock
end function

global procedure hook_idle (integer id)
    if not find(id, idle_hooks) and id > -1 then
	idle_hooks &= id
    end if
end procedure

global procedure unhook_idle (integer id)
    integer i
    
    i = find(id, idle_hooks)
    if i then
	idle_hooks = idle_hooks[1..i - 1] & idle_hooks[i + 1..$]
    end if
end procedure

global procedure hook_SNAC (integer fam, integer subfam, integer id)
    snac_hooks = append(snac_hooks, {fam, subfam, id})
end procedure

global procedure unhook_SNAC (integer fam, integer subfam, integer id)
    integer i
    
    i = find({fam, subfam, id}, snac_hooks)
    if i then
	snac_hooks = snac_hooks[1..i - 1] & snac_hooks[i + 1..$]
    end if
end procedure

-- sends a FLAP packet and increments the sequence ID
global procedure send (socket sock, sequence data)
    send(sock, data)

    seq += 1
    if seq = #10000 then
	seq = 0
    end if
end procedure

-- sends a SNAC embedded in a FLAP
global procedure send_SNAC (socket sock, integer fam, integer subfam, integer flag, integer reqID, sequence data)
    if verbose then
	printf(1, ">> SNAC(%02x, %02x)\n", {fam, subfam})
    end if
    send(sock, make_FLAP(2, seq,
	       make_SNAC(fam, subfam, flag, reqID, data)))
end procedure

-- describes the error if possible
-- default behavior is just to print the error to the screen. you can use
-- your own function instead
procedure oscar_error (sequence dat)
    integer code

    code = dat[1] * #100 + dat[2]
    
    puts(1, "ERROR(")
    if code < 1 or code > #18 then
	printf(1, "%d, unknown)\n", code)
    else
	printf(1, "%d, %s)\n", {code, error_codes[code]})
    end if
end procedure
error_hook = routine_id("oscar_error")

global function get_TLV (sequence pk, integer id)
    for i = 1 to length(pk) do
	if pk[i][1] = id then
	    return pk[i][2]
	end if
    end for
    
    return -1
end function

-- parses incoming packets
global function parse_packet (integer chan, sequence dat)
    integer c, len, fmt
    sequence out
    
    
    if chan = 2 then
	-- packets coming from channel 2 always contain a SNAC
	fmt = SNAC
    else
	-- packets coming from other channels are assumed to contain TLVs
	fmt = TLV
    end if
    
    c = 1
    out = {}
    
    if verbose then puts(1, "<< ") end if

    switch fmt do
    case TLV then
	-- we've been given a packet to parse and not coming from channel 2
	-- we assume it contains TLVs
	-- first check to see that what we received isn't in fact a conn ack
	if not equal(dat, {0, 0, 0, 1}) then
	    -- extract TLVs
	    while c <= length(dat) do
		len = dat[c + 2] * #100 + dat[c + 3]            -- TLV length
		out = append(out, {dat[c] * #100 + dat[c + 1],  -- TLV type
				   dat[c + 4..c + 3 + len]})    -- data
		c += 4 + len
		if verbose then
		    printf(1, "TLV(%02x, ", out[$][1])
		    pretty_print(1, out[$][2], {2})
		    puts(1, ") ")
		end if
	    end while
	    if verbose then puts(1,'\n') end if
	else
	    if verbose then puts(1,"conn ack\n") end if
	end if

    case SNAC then
	out = {dat[c] * #100 + dat[c + 1],      -- family
	       dat[c + 2] * #100 + dat[c + 3],  -- subfamily
	       dat[c + 4] * #100 + dat[c + 5],  -- flags
	       dat[c + 6] * #1000000 +          -- request ID
	       dat[c + 7] * #10000 +
	       dat[c + 8] * #100 +
	       dat[c + 9],
	       dat[c + 10..$]}                  -- data
	if verbose then printf(1, "SNAC(%02x, %02x)\n", out[1..2]) end if
    end switch
    
    return out
end function

with trace
function receive_bytes (socket sock, integer nbytes)
    sequence dat
    object ret

    trace(1)
    dat = {}
    
    -- first receive the waiting FLAP header
    ret = select(sock, {}, {})
    if not ret[1][SELECT_IS_READABLE] and not length(queue) then
	return -1
    end if

    --ret = receive(sock)
    --if sequence(ret) then
	if length(queue) then
	    if length(queue) >= nbytes then
		dat = queue[1..nbytes]
		queue = queue[nbytes + 1..$]
	    else
		dat = queue
		queue = {}
	    end if
	end if

	if length(dat) < nbytes then
	    --dat &= ret
	    --if length(dat) > nbytes then
		--queue &= dat[nbytes + 1..$]
		--dat = dat[1..nbytes]
	    --end if
	    while length(dat) < nbytes do
		dat &= receive(sock)
	    end while
	end if
	return dat
    --else
	--return -1
    --end if
end function

-- returns {channel, sequence #, parsed TLVs or SNAC}
global function get_packet (socket sock)
    object ret
    integer c, len
    sequence header, dat
    
    c = 0
    
    ret = receive_bytes(sock, 6)
    if atom(ret) then
	return {}
    else
	dat = ret
    end if
    header = {dat[2], dat[3] * #100 + dat[4]}
    
    -- the length field is a word, bytes 5 and 6
    
    c = 0
    len = dat[5] * #100 + dat[6]
    ret = -1
    while atom(ret) do
	ret = receive_bytes(sock, len)
    end while
    
    npackets += 1
    
    return {header[1], header[2], parse_packet(header[1], ret)}
end function

function parse_rate_limits (sequence s)
    sequence class, rate_limits
    integer n_classes, j
    
    rate_limits = {}
    
    n_classes = bytesto16(s[1..2])  s = s[3..$]
    for i = 1 to n_classes do
	j = 1
	class = {bytesto16(s[j..j + 1])}
	j += 2
	
	for k = 1 to 8 do
	    class &= bytesto32(s[j..j + 3])
	    j += 4
	end for
	
	class &= s[j]
	j += 1
	
	rate_limits = append(rate_limits, class)
    end for
    
    return rate_limits
end function

function auth_chan01(socket sock, sequence uname, sequence pass)
    sequence auth, host, pk
    integer x
    object res, res2

    res = get_packet(sock)    
    if atom(res) then return {ERR_CONNECT, 0, ""} end if
    
    send(sock, make_FLAP(1, seq, {0, 0, 0, 1} &
		make_TLV(#01, uname) &
		make_TLV(#02, roast(pass)) &
		make_TLV(#03, "oscar.e") &
		make_TLV(#16, {#01, #0A}) &
		make_TLV(#17, {#00, #01}) &
		make_TLV(#18, {#00, #00}) &
		make_TLV(#19, {#00, #00}) &
		make_TLV(#1A, {#00, #01}) &
		make_TLV(#14, {#BA, #AD, #F0, #0D}) &
		make_TLV(#0F, "en") &
		make_TLV(#0E, "us")))
    
    res2 = {}

    res = get_packet(sock)
    if atom(res) then
	return {ERR_CONNECT, 0, ""}
    else
	pk = res
    end if  

    -- TLV 0x0005 has the IP address for the BOS server
    res = get_TLV(pk[PK_DATA], 5)
    if sequence(res) then
	host = res
	if find(':', host) then
	    host = host[1..find(':', host) - 1]
	end if
    end if

    -- TLV 0x0006 has the authorization cookie
    res = get_TLV(pk[PK_DATA], 6)
    if sequence(res) then auth = res end if

    -- TLV 0x0008 has the error code
    res = get_TLV(pk[PK_DATA], 8)
    if sequence(res) then
	res2 = bytesto16(res[2])
	return {ERR_AUTH, res2, auth_errors[res2]}
    end if

    return {0, host, auth}
end function

function auth_md5(socket sock, sequence uname, sequence pass)
    sequence pk, key, host, auth, snac_data
    integer len
    object res, res2
    
    res = get_packet(sock)
    if atom(res) then return {ERR_CONNECT, 0, ""} end if
    
    send(sock, make_FLAP(1, seq, {0, 0, 0, 1}))
    send_SNAC(sock, #17, 6, 0, 0, make_TLV(#01, uname) &
				  make_TLV(#4B, "") &
				  make_TLV(#5A, ""))
    
    pk = get_packet(sock)
    if atom(pk) then return {ERR_CONNECT, 0, ""} end if
    
    if equal(pk[PK_DATA][1..2], {#17, 7}) then
	len = bytesto16(pk[PK_DATA][SNAC_DATA][1..2])
	key = pk[PK_DATA][SNAC_DATA][3..2 + len]
	
	send_SNAC(sock, #17, 2, 0, 0, make_TLV(#01, uname) &
				      make_TLV(#25, md5(key & pass & AIM_MD5_STRING)) &
				      make_TLV(#03, "oscar.e") &
				      make_TLV(#16, {#01, #0A}) &
				      make_TLV(#17, {#00, #01}) &
				      make_TLV(#18, {#00, #00}) &
				      make_TLV(#19, {#00, #01}) &
				      make_TLV(#1A, {#12, #34}) &
				      make_TLV(#14, {#BA, #AD, #F0, #0D}) &
				      make_TLV(#0F, "en") &
				      make_TLV(#0E, "us") &
				      make_TLV(#0F, {1}))
    end if

    pk = get_packet(sock)
    if atom(pk) then return {ERR_CONNECT, 0, ""} end if
    
    if equal(pk[PK_DATA][1..2], {#17, 3}) then
	snac_data = parse_packet(TLV, pk[PK_DATA][SNAC_DATA])

	-- TLV 0x0005 has the IP address for the BOS server
	res = get_TLV(snac_data, 5)
	if sequence(res) then
	    host = res
	    if find(':', host) then
		host = host[1..find(':', host) - 1]
	    end if
	end if

	-- TLV 0x0006 has the authorization cookie
	res = get_TLV(snac_data, 6)
	if sequence(res) then auth = res end if

	-- TLV 0x0008 has the error code
	res = get_TLV(snac_data, 8)
	if sequence(res) then
	    res2 = bytesto16(res)
	    return {ERR_AUTH, res2, auth_errors[res2]}
	end if

	return {0, host, auth}
    end if
    
    return {ERR_AUTH, 0, ""}
end function

global procedure send_message (socket sock, sequence user, sequence msg, integer ack = 0)
    sequence flap
    atom msg_cookie

    --send_SNAC(sock, 4, 6, 0, 0, {1, 2, 3, 4, 5, 6, 7, 8, 0, 1} & length(user) &
				 --user &
				 --make_TLV(2, make_fragment(5, 1, {1}) &
					     --{1, 1} & i16tobytes(length(msg) + 4) &
					     --{0, 0, #FF, #FF} & msg))

    msg_cookie = rand(#3FFFFFFF)
    
    flap = make_FLAP(2, seq, make_SNAC(4, 6, 0, 0, {0, 0, 0, 0} &
			     i32tobytes(msg_cookie) & {0, 1} &
			     length(user) & user &
			     make_TLV(2, make_fragment(5, 1, {1}) &
					 {1, 1} & i16tobytes(length(msg) + 4) &
					 {0, 0, #FF, #FF} & msg) &
			     make_TLV(3, {})))

    send(sock, flap)
    
    if ack then
	waiting_msgs = append(waiting_msgs, {msg_cookie, flap, time() + MSG_TIMEOUT})
    end if
end procedure

procedure get_message (sequence pk)
    sequence from, tlv5, clsID
    object msg
    
    pk = pk[5]
    
    from = pk[12..11 + pk[11]]
    
    pk = parse_packet(TLV, pk[16 + pk[11]..$])
    msg = get_TLV(pk, 2)
    if sequence (msg) then
	msg = msg[5 + bytesto16(msg[3..4])..$]
    
	safe_proc(msg_hook, {from, msg[9..$]})
    end if
end procedure
hook_SNAC(4, 7, routine_id("get_message"))

global function AIM_login (sequence uname, sequence pass, integer auth_method)
    object res, res2
    socket sock
    sequence auth, host
    
    host = ""
    res = host_by_name("login.oscar.aol.com")
    if atom(res) then return -1 end if
    res = new_connection(res[3][1])
    
    if atom(res) then
	return {ERR_CONNECT}
    else
	sock = res
    end if
    
    puts(1, "authenticating\n")
    
    if auth_method = AUTH_MD5 then
	res = auth_md5(sock, uname, pass)
    else
	res = auth_chan01(sock, uname, pass)
    end if

    if res[1] >= 0 then
	puts(1, "logging in\n")

	host = res[2]
	auth = res[3]
	res = slib:close(sock)
	sock = new_connection(host)
	
	send(sock, make_FLAP(1, seq, {0, 0, 0, 1} & make_TLV(6, auth)))
    elsif res[1] = ERR_AUTH then
	return res
    else
	return {ERR_LOGIN, 0, "unknown error"}
    end if

    return {0, sock}
end function

global procedure message_loop (socket sock)       
    sequence families, hex, snac_data
    atom cookie, t
    object res

    while 1 do
	t = time()
	-- find messages that are awaiting acknowledgement but have
	-- timed out, and resend them
	for i = 1 to length(waiting_msgs) do
	    if t > waiting_msgs[i][3] then
		waiting_msgs[i][3] = time() + MSG_TIMEOUT
		send(sock, waiting_msgs[i][2])
	    end if
	end for

	for i = 1 to length(idle_hooks) do
	    safe_proc(idle_hooks[i], {})
	end for
    
	res = get_packet(sock)  -- get the next packet
	if atom(res) then
	    puts(1, "disconnected")
	    return
	end if

	if length(res[3]) then
	    snac_data = res[PK_DATA][SNAC_DATA]
	
	    if res[PK_CHAN_ID] = 1 then
		safe_proc(error_hook, {snac_data})

	    elsif equal(res[PK_DATA][1..2], {1, 3}) then
		send_SNAC(sock, 1, #17, 0, 0, {0, 1, 0, 4, 0, #13, 0, 3,
					       0, 2, 0, 1, 0, 3, 0, 1,
					       0, 4, 0, 1, 0, 6, 0, 1,
					       0, 8, 0, 1, 0, 9, 0, 1,
					       0, #A, 0, 1, 0, #B, 0, 1})

	    elsif equal(res[PK_DATA][1..2], {1, #18}) then
		families = {}
		for i = 1 to length(snac_data) by 4 do
		    families &= snac_data[i..i+3] & {1, #10, 8, #D6}
		end for
		
		send_SNAC(sock, 1, 6, 0, 0, {})

	    elsif equal(res[PK_DATA][1..2], {1, 7}) then
		snac_data = parse_rate_limits(snac_data)
		    
		hex = {}
		for i = 1 to length(snac_data) do
		    hex &= i16tobytes(snac_data[i][1])
		end for

		send_SNAC(sock, 1, 8, 0, 0, hex)
		send_SNAC(sock, 2, 2, 0, 0, {})

	    elsif equal(res[PK_DATA][1..2], {2, 3}) then
		snac_data = parse_packet(TLV, snac_data)

		send_SNAC(sock, 2, 4, 0, 0, make_TLV(1, "text/x-aolrtf; charset=\"us-ascii\"") &
					    make_TLV(2, "bastid") &
					    make_TLV(3, "text/x-aolrtf; charset=\"us-ascii\"") &
					    make_TLV(4, "") &
					    make_TLV(5, {#74,#8F,#24,#20,#62,#87,#11,#D1,
							 #82,#22,#44,#45,#53,#54,0,0}))
		send_SNAC(sock, 3, 2, 0, 0, {})

	    elsif equal(res[PK_DATA][1..2], {3, 3}) then
		send_SNAC(sock, 4, 4, 0, 0, {})

	    elsif equal(res[PK_DATA][1..2], {4, 5}) then
		max_message_size = bytesto16(snac_data[7..8]) - 10
		send_SNAC(sock, 4, 2, 0, 0, snac_data)
		send_SNAC(sock, 9, 2, 0, 0, {})
	    
	    elsif equal(res[PK_DATA][1..2], {4, #C}) then
		cookie = bytesto32(snac_data[5..8])

		for i = 1 to length(waiting_msgs) do
		    if equal(waiting_msgs[i][1], cookie) then
			waiting_msgs = waiting_msgs[1..i - 1] & waiting_msgs[i + 1..$]
			exit
		    end if
		end for

	    elsif equal(res[PK_DATA][1..2], {9, 3}) then
		send_SNAC(sock, #13, 2, 0, 0, {})
		send_SNAC(sock, 1, #E, 0, 0, {})
		send_SNAC(sock, #13, 5, 0, 0, {0, 0, 0, 0, 0, 0})
		send_SNAC(sock, #13, 4, 0, 0, {})

	    elsif equal(res[PK_DATA][1..2], {#13, #0F}) or
		  equal(res[PK_DATA][1..2], {#13, #06}) and
		  not login_finished then
		send_SNAC(sock, #13, 7, 0, 0, {})
		send_SNAC(sock, 1, 2, 0, 0, families)
		login_finished = 1

	    else
		for i = 1 to length(snac_hooks) do
		    if equal(res[PK_DATA][1..2],
			     snac_hooks[i][1..2]) then
			safe_proc(snac_hooks[i][3], {res[PK_DATA]})
		    end if
		end for
	    end if
	end if
    end while
end procedure
