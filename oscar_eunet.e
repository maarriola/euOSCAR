include std/stack.e
include std/net/dns.e
include md5.e
include eunet.e
include util.e as util
include hook.e

constant AIM_MD5_STRING = "AOL Instant Messenger (SM)",
         FLAP   = 1,
         SNAC   = 2,
         TLV    = 3,
         
         PK_CHANNEL = 1,
         PK_SEQ_ID  = 2,
         PK_DATA    = 3,
         
         SNAC_FAMILY    = 1,
         SNAC_SUBFAM    = 2,
         SNAC_FLAGS     = 3,
         SNAC_REQ_ID    = 4,
         SNAC_DATA      = 5,
         
         TLV_TYPE       = 1,
         TLV_DATA       = 2,
         
         RATE_WINDOW    = 1,
         RATE_CLEAR     = 2,
         RATE_ALERT     = 3,
         RATE_LIMIT     = 4,
         RATE_DISCONNECT= 5,
         RATE_CURRENT   = 6,
         RATE_MAX       = 7,
         RATE_LAST_TIME = 8,
         RATE_STATE     = 9,
         RATE_OLDLEVEL  = 10,

         MSG_TIMEOUT    = 15
         
global constant BUD_NAME       = 1,
                BUD_ONLINE     = 2,
                BUD_WARNING    = 3,
                BUD_CLASS      = 4,
                BUD_DCINFO     = 5,
                BUD_IP_ADDR    = 6,
                BUD_STATUS     = 7,
                BUD_CAPS       = 8,
                BUD_TIME       = 9,
                BUD_SIGNON     = 10,
                BUD_MEMBERSINCE = 11,
                BUD_ICON        = 12,
         
                STATUS_WEBAWARE    = #0001,
                STATUS_SHOWIP      = #0002,
                STATUS_BIRTHDAY    = #0008,
                STATUS_WEBFRONT    = #0020,
                STATUS_DCDISABLED  = #0100,
                STATUS_DCAUTH      = #1000,
                STATUS_DCCONT      = #2000,
         
                STATUS_ONLINE      = #0000,
                STATUS_AWAY        = #0001,
                STATUS_DND         = #0002,
                STATUS_NA          = #0004,
                STATUS_OCCUPIED    = #0010,
                STATUS_FREE4CHAT   = #0020,
                STATUS_INVISIBLE   = #0100,
         
                ERR_RESOLVE     = -1,
                ERR_CONNECT     = -2,
                ERR_AUTH        = -3,
                ERR_LOGIN       = -4,
                
                AUTH_MD5        = 1,
                AUTH_CHANNEL1   = 2,
                
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
                               "rate limit exceeded, try again in a few minutes",
                               "user too heavily warned",
                               "reservation timeout",
                               "", "",
                               "rate limit exceeded. try again in a few minutes",
                               "",
                               "invalid SecurID",
                               "account suspended because of age (< 13)"},
                rate_message = {"rate limit parameters changed",
                                "rate limit warning",
                                "rate limit hit",
                                "rate limit clear"}

global integer error_hook, msg_hook, max_message_size, current_seq
sequence waiting_msgs, buddy_list, rates, client_profile, buf
atom lastsnac, server
integer login_finished, verbose, rate_limit
object ret, BLEH
stack in_queue, out_queue

buf = ""
server = -1
client_profile = "euOSCAR"
in_queue = new(FILO)
out_queue = new(FIFO)
rate_limit = 1
buddy_list = {}
waiting_msgs = {}
max_message_size = 0
verbose = 1
login_finished = 0
lastsnac = 0
error_hook = -1
msg_hook = -1

global procedure set_rate_limit (integer i)
    rate_limit = i
end procedure

global procedure set_profile (sequence str)
    client_profile = str
end procedure

global function get_profile ()
    return client_profile
end function

-- opens a new connection and resets sequence ID
function new_connection (sequence host)
    object result
    atom sock

    sock = eunet_new_socket(AF_INET, SOCK_STREAM, 0)

    result = eunet_getaddrinfo(host, 5190, 0)
    if atom(result) then return ERR_RESOLVE end if

    result = eunet_connect(sock, result[1][5])
    
    if result = -1 then return ERR_CONNECT end if
    
    current_seq = 0
    rates = repeat(repeat(0, 10), #40)

    return sock
end function

-- sends a FLAP packet and increments the sequence ID
global procedure flap_send (sequence data)
    ret = eunet_send(server, data, 0)

    current_seq += 1
    if current_seq = #10000 then
        current_seq = 0
    end if
end procedure

-- calculates rate level and updates rate status for a given service
function rate_update (sequence rate)
    atom window, cur, old, t

    if not rate[RATE_WINDOW] then -- rate limits not set yet
        rate[RATE_STATE]= 3
        return rate
    end if
    
    t = time()

    -- if rate limits aren't set yet, then we can just assume our status is clear
    --if not window then
        --rate[RATE_STATE] = 3
        --return rate
    --end if

    -- save old level and calculate new level
    window = rate[RATE_WINDOW]
    old = rate[RATE_CURRENT]
    rate[RATE_CURRENT] = (window - 1) / window * old + 1 / window * (t * 1000 - rate[RATE_LAST_TIME])
    rate[RATE_OLDLEVEL] = old
    cur = rate[RATE_CURRENT]

    -- if our state was limited
    if rate[RATE_STATE] = 1 then
        -- and our level has exceeded the clear level
        if cur > rate[RATE_CLEAR] then
            -- then our status is now clear
            rate[RATE_STATE] = 3
        end if
    -- otherwise
    else
        -- if level is below the limit level
        if cur < rate[RATE_LIMIT] then
            -- status is limited
            rate[RATE_STATE] = 1
        -- if level is between limit and alert
        elsif cur > rate[RATE_LIMIT] and cur < rate[RATE_ALERT] then
            -- status is alert
            rate[RATE_STATE] = 2
        -- if level is above alert level
        elsif cur > rate[RATE_ALERT] then
            -- status is clear
            rate[RATE_STATE] = 3
        end if
    end if

    return rate
end function

-- sends a SNAC embedded in a FLAP
global function send_SNAC (integer fam, integer subfam, integer flag, integer reqID, sequence data)
    sequence rate, flap
    integer dL, dC

    if verbose then
        printf(1, ">> SNAC(%02x, %02x)\n", {fam, subfam})
    end if
    
    
    if rate_limit then
        rate = rates[fam + 1]
        rate = rate_update(rate)
    end if

    flap = make_FLAP(2, current_seq, make_SNAC(fam, subfam, flag, reqID, data))
    
    if rate_limit and rate[RATE_STATE] = 2 then
        dC = rate[RATE_CURRENT] - rate[RATE_CLEAR]
        dL = rate[RATE_LIMIT] - rate[RATE_CURRENT]
    end if
    
    --printf(1, "state %d\n", rate[RATE_STATE])
    -- keep sending packets if:
    --  we aren't rate limiting
    --  status is clear
    --  or status is alert, but closer to clear than limit
    if not rate_limit
    or rate[RATE_STATE] = 3
    or (rate[RATE_STATE] = 2 and dC < dL) then
        if rate_limit then rate[RATE_LAST_TIME] = time() end if
        flap_send(flap)
    -- otherwise shuffle off to the queue until our level goes down
    else
        push(out_queue, {fam, subfam, flag, reqID, data})
        return 0
    end if
    
    if rate_limit then rates[fam + 1] = rate end if
    return 1
end function

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
-- used by AIM_login and message_loop, which pass the channel ID of an incoming
-- FLAP packet. as they coincide, you can also pass the data type (SNAC, TLV)
-- contained in a packet in place of the channel ID
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

    if fmt = TLV then
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
                    pretty_print(1, out[$][2], {3})
                    puts(1, ") ")
                end if
            end while
            if verbose then puts(1,'\n') end if
        else
            if verbose then puts(1,"conn ack\n") end if
        end if
    elsif fmt = SNAC then
        out = {dat[c] * #100 + dat[c + 1],      -- family
               dat[c + 2] * #100 + dat[c + 3],  -- subfamily
               dat[c + 4] * #100 + dat[c + 5],  -- flags
               dat[c + 6] * #1000000 +          -- request ID
               dat[c + 7] * #10000 +
               dat[c + 8] * #100 +
               dat[c + 9],
               dat[c + 10..$]}                  -- data
        if verbose then printf(1, "SNAC(%02x, %02x)\n", out[1..2]) end if
    end if
    
    return out
end function

with trace
function net_bytes (atom sock, integer n_bytes)
    integer c
    object ret
    sequence dat
    c = 0
    
    trace(1)
    
    if length(buf) >= n_bytes then
        dat = buf[1..n_bytes]
        buf = buf[n_bytes + 1..$]
        return dat
    elsif length(buf) then
        dat = buf[1..$]
        c = length(dat)
    end if
    
    while c < n_bytes do
        --task_yield()
        ret = eunet_poll({sock, POLLIN}, 250)
        if sequence(ret) and ret[1] then
            dat &= eunet_recv(sock, 0)
            ret = eunet_poll({sock, 0}, 0)
            c += length(dat)
        end if
    end while
    
    if c > n_bytes then
        buf &= dat[n_bytes + 1..$]
        return dat[1..n_bytes]
    else
        return dat
    end if
end function

-- returns {channel, sequence #, parsed TLVs or SNAC}
global function get_packet ()
    object ret
    integer c, len
    sequence header, dat, pk
    
    c = 0
    dat = {}
    
    -- first receive the waiting FLAP header
    dat = net_bytes(server, 6)
    
    header = {dat[2], dat[3] * #100 + dat[4]}
    
    -- the length field is a word, bytes 5 and 6
    
    c = 0
    len = dat[5] * #100 + dat[6]
    dat = net_bytes(server, len)
    
    pk = parse_packet(header[1], dat)
    if length(pk) and header[1] = 2 and equal(pk[1..2], {1, #A}) then
        c = bytesto16(pk[SNAC_DATA][1..2])
        if c >= 1 and c <= 4 then
            puts(1, rate_message[c] & '\n')
        else
            printf(1, "unknown rate limit message 0x%04x\n", c)
        end if
    end if
    
    return {header[1], header[2], pk}
end function

-- returns:
-- {{class ID, window size, clear level, alert level, limit level, disconnect level, current level, max level,
--   last time, current state}, {...}, ...}
function parse_rate_limits (sequence s)
    sequence class, rate_limits
    integer n_classes, j
    
    rate_limits = {}
    
    n_classes = bytesto16(s[1..2])  s = s[3..$]
    j = 1

    for i = 1 to n_classes do
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

function auth_chan01(sequence uname, sequence pass)
    sequence auth, host, pk
    integer x
    object res, res2

    res = get_packet()    
    if atom(res) then return {ERR_CONNECT, 0, ""} end if
    
    flap_send(make_FLAP(1, current_seq, {0, 0, 0, 1} &
                         make_TLV(#01, uname) &
                         make_TLV(#02, roast(pass)) &
                         make_TLV(#03, "euOSCAR") &
                         make_TLV(#16, {#01, #0A}) &
                         make_TLV(#17, {#00, #01}) &
                         make_TLV(#18, {#00, #00}) &
                         make_TLV(#19, {#00, #00}) &
                         make_TLV(#1A, {#00, #01}) &
                         make_TLV(#14, {#BA, #AD, #F0, #0D}) &
                         make_TLV(#0F, "en") &
                         make_TLV(#0E, "us")))
    
    res2 = {}

    res = get_packet()
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

function auth_md5(sequence uname, sequence pass)
    sequence pk, key, host, auth, snac_data
    integer len
    object res, res2
    
    res = get_packet()
    if atom(res) then return {ERR_CONNECT, 0, ""} end if
    
    flap_send(make_FLAP(1, current_seq, {0, 0, 0, 1}))
    BLEH = send_SNAC(#17, 6, 0, 0, make_TLV(1, uname) &
                     make_TLV(#4B, "") &
                     make_TLV(#5A, ""))
    
    pk = get_packet()
    if atom(pk) then return {ERR_CONNECT, 0, ""} end if
    
    if equal(pk[PK_DATA][1..2], {#17, 7}) then
        len = bytesto16(pk[PK_DATA][SNAC_DATA][1..2])
        key = pk[PK_DATA][SNAC_DATA][3..2 + len]

        BLEH = send_SNAC(#17, 2, 0, 0, make_TLV(1, uname) &
                         make_TLV(#25, md5(key & pass & AIM_MD5_STRING)) &
                         make_TLV(3, "yourmother") &
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

    pk = get_packet()
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

global procedure send_message (sequence user, sequence msg, integer ack = 0)
    sequence flap
    atom msg_cookie
    
    msg_cookie = rand(#3FFFFFFF)

    --BLEH = send_SNAC(4, 6, 0, 0, {1, 2, 3, 4, 5, 6, 7, 8, 0, 1} & length(user) &
                                     --user &
                                     --make_TLV(2, make_fragment(5, 1, {1}) &
                                                 --{1, 1} & i16tobytes(length(msg) + 4) &
                                                 --{0, 0, #FF, #FF} & msg))

    flap = make_FLAP(2, current_seq, make_SNAC(4, 6, 0, 0, {0, 0, 0, 0} &
                                        i32tobytes(msg_cookie) & {0, 1} &
                                        length(user) & user &
                                       make_TLV(2, make_fragment(5, 1, {1}) &
                                                 {1, 1} & i16tobytes(length(msg) + 4) &
                                                 {0, 0, #FF, #FF} & msg) &
                                        make_TLV(3, {})))

    flap_send(flap)

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

function buddy_status (sequence buddy)
    sequence status, tstr
    integer t

    t = buddy[BUD_TIME]

    tstr = ""
    if t then
        if t > 604800 then
            tstr &= sprintf("%dw ", floor(t / 604800))
            t -= floor(t / 604800) * 604800
        end if
        if t > 86400 then
            tstr &= sprintf("%dd ", floor(t / 86400))
            t -= floor(t / 86400) * 86400
        end if
        if t > 3600 then
            tstr &= sprintf("%dh ", floor(t / 3600))
            t -= floor(t / 3600) * 3600
        end if
        if t > 60 then
            tstr &= sprintf("%dm ", floor(t / 60))
            t -= floor(t / 60) * 60
        end if
    else
        t = -1
    end if
    
    if length(tstr) then tstr = tstr[1..$ - 1] end if
    
    status = ""
    if and_bits(buddy[BUD_STATUS], STATUS_AWAY) then status = "away, " end if
    if and_bits(buddy[BUD_STATUS], STATUS_DND) then status &= "do not disturb, " end if
    if and_bits(buddy[BUD_STATUS], STATUS_NA) then status &= "not available, " end if
    if and_bits(buddy[BUD_STATUS], STATUS_OCCUPIED) then status &= "busy, " end if
    if and_bits(buddy[BUD_STATUS], STATUS_FREE4CHAT) then status &= "free for chat " end if
    
    if t = -1 then
        return sprintf("%s has signed on", {buddy[BUD_NAME]})
    else
        if not length(status) then
            status = "online"
        else
            status = status[1..$ - 2]
        end if
        return sprintf("%s is %s (%s)", {buddy[BUD_NAME], status, tstr})
    end if
end function

procedure buddy_online (sequence snac)
    sequence user, buddy, tlvlist
    object tlv

    snac = snac[SNAC_DATA]
    buddy = repeat(0, BUD_MEMBERSINCE) & {{0, 0, 0}}
    user = snac[2..1 + snac[1]]
    
    snac = snac[2 + snac[1]..$]
    
    buddy[BUD_NAME] = user
    buddy[BUD_ONLINE] = 1
    buddy[BUD_WARNING] = bytesto16(snac[1..2])
    tlvlist = parse_packet(TLV, snac[5..$])
    
    tlv = get_TLV(tlvlist, 1)
    if sequence(tlv) then buddy[BUD_CLASS] = tlv end if
    tlv = get_TLV(tlvlist, #C)
    if sequence(tlv) then buddy[BUD_DCINFO] = tlv end if
    tlv = get_TLV(tlvlist, #A)
    if sequence(tlv) then buddy[BUD_IP_ADDR] = tlv end if
    tlv = get_TLV(tlvlist, 6)
    if sequence(tlv) then buddy[BUD_STATUS] = bytesto32(tlv) end if
    tlv = get_TLV(tlvlist, #D)
    if sequence(tlv) then buddy[BUD_CAPS] = tlv end if
    tlv = get_TLV(tlvlist, #F)
    if sequence(tlv) then buddy[BUD_TIME] = bytesto32(tlv) end if
    tlv = get_TLV(tlvlist, 3)
    if sequence(tlv) then buddy[BUD_SIGNON] = tlv end if
    tlv = get_TLV(tlvlist, 5)
    if sequence(tlv) then buddy[BUD_MEMBERSINCE] = tlv end if
    tlv = get_TLV(tlvlist, #1D)
    if sequence(tlv) then
        buddy[BUD_ICON] = {bytesto16(tlv[1..2]), tlv[3], tlv[5..20]}
    end if
    
    puts(1, buddy_status(buddy) & '\n')
    
    for i = 1 to length(buddy_list) do
        if compare_name(buddy_list[i][BUD_NAME], user) then
            buddy_list[i] = buddy
            buddy = {}
            exit
        end if
    end for
    
    if length(buddy) then
        buddy_list = append(buddy_list, buddy)
    end if
end procedure
hook_SNAC(3, #B, routine_id("buddy_online"))

procedure buddy_offline (sequence snac)
    sequence user
    
    snac = snac[SNAC_DATA]
    user = snac[2..1 + snac[1]]
    printf(1, "%s is offline\n", {user})

    for i = 1 to length(buddy_list) do
        if compare_name(buddy_list[i][BUD_NAME], user) then
            buddy_list[i][BUD_ONLINE] = 0
        end if
    end for
end procedure
hook_SNAC(3, #C, routine_id("buddy_offline"))

function find_buddy (sequence name)
    for i = 1 to length(buddy_list) do
        if compare_name(buddy_list[i][BUD_NAME], name) then
            return buddy_list[i]
        end if
    end for
    
    return -1
end function

global procedure add_buddies (sequence list)
    sequence out

    for i = 1 to length(list) do
        list[i] = strip_name(list[i])
        out &= length(list[i]) & list[i]
    end for
    
    BLEH = send_SNAC(3, 4, 0, 0, out)
end procedure

global procedure remove_buddies (sequence list)
    sequence out

    for i = 1 to length(list) do
        list[i] = strip_name(list[i])
        out &= length(list[i]) & list[i]
    end for
    
    BLEH = send_SNAC(3, 5, 0, 0, out)
end procedure

global function AIM_login (sequence uname, sequence pass, integer auth_method = AUTH_MD5)
    object res, res2
    integer sock, stage
    sequence auth, host
    
    stage = 0
    host = ""
    sock = new_connection("login.oscar.aol.com")
    
    if sock < 0 then
        return {sock}
    end if
    
    puts(1, "authenticating\n")
    server = sock
    
    if auth_method = AUTH_MD5 then
        res = auth_md5(uname, pass)
    else
        res = auth_chan01(uname, pass)
    end if

    if res[1] >= 0 then
        puts(1, "logging in\n")

        host = res[2]
        auth = res[3]
        stage += 1
        res = eunet_shutdown_socket(sock, 2)
        sock = new_connection(host)
        server = sock
        
        if sock then
            flap_send(make_FLAP(1, current_seq, {0, 0, 0, 1} & make_TLV(6, auth)))
        end if  
    elsif res[1] = ERR_AUTH then
        return res
    else
        return {ERR_LOGIN, 0, "unknown error"}
    end if

    return {0, sock}
end function

global procedure message_loop ()
    sequence families, hex, snac_data
    atom cookie, t
    object res
    
    families = {}

    while 1 do
        t = time()
        -- find messages that are awaiting acknowledgement but have
        -- timed out, and resend them
        for i = 1 to length(waiting_msgs) do
            if t > waiting_msgs[i][3] then
                waiting_msgs[i][3] = time() + MSG_TIMEOUT
                flap_send(waiting_msgs[i][2])
            end if
        end for

        -- excecute idle hooks
        for i = 1 to length(idle_hooks) do
            safe_proc(idle_hooks[i], {})
        end for
        
        -- if got too close to being limited and had to queue packets,
        -- try to send them again
        if not is_empty(out_queue) then
            hex = top(out_queue)
            if send_SNAC(hex[1], hex[2], hex[3], hex[4], hex[5]) then --, hex[6]) then
                BLEH = pop(out_queue)
            end if
        end if
    
        -- if another function intercepted a bunch of SNACs while waiting
        -- for the desired one, this is where it will put them
        if not is_empty(in_queue) then
            res = pop(in_queue)
        else
            -- get the next packet
            res = get_packet()
            if atom(res) then
                puts(1, "disconnected")
                return
            end if
        end if

        if length(res[3]) then
            snac_data = res[PK_DATA][SNAC_DATA]
        
            if res[PK_CHANNEL] = 2 and res[PK_DATA][2] = 1 then
                safe_proc(error_hook, {snac_data})
            elsif res[PK_CHANNEL] = 2 then
                switch sprintf("%04x", bytesto16(res[PK_DATA][1..2])) do
                    -- receive supported services
                    case "0103" then
                        -- request service versions
                        BLEH = send_SNAC(1, #17, 0, 0, {0, 1, 0, 4, 0, #13, 0, 3,
                                                           0, 2, 0, 1, 0, 3, 0, 1,
                                                           0, 4, 0, 1, 0, 6, 0, 1,
                                                           0, 8, 0, 1, 0, 9, 0, 1,
                                                           0, #A, 0, 1, 0, #B, 0, 1})

                    -- receive service versions
                    case "0118" then
                        -- save for SNAC(01,02) later
                        families = {}
                        for i = 1 to length(snac_data) by 4 do
                            families &= snac_data[i..i+3]   -- family # and version
                                     &  {1, #10, 8, #D6}    -- tool ID and tool version (#0110, #08D6)
                        end for
                
                        -- request rate limits
                        BLEH = send_SNAC(1, 6, 0, 0, {})

                    -- receive rate limits
                    case "0107" then
                        snac_data = parse_rate_limits(snac_data)
                        ? snac_data

                        hex = {}
                        for i = 1 to length(snac_data) do
                            --if verbose then printf(1, "family %02x ", snac_data[i][1]) ? snac_data[i][2..$] end if
                            rates[snac_data[i][1] + 1] = snac_data[i][2..$] & 0
                            hex &= i16tobytes(snac_data[i][1])
                        end for

                        -- accept rate limits
                        BLEH = send_SNAC(1, 8, 0, 0, hex)
                        -- request family 0x0002 (location services) limitations
                        BLEH = send_SNAC(2, 2, 0, 0, {})

                    -- receive family 0x0002 limitations
                    case "0203" then
                        snac_data = parse_packet(TLV, snac_data)

                        -- set profile and capabilities
                        BLEH = send_SNAC(2, 4, 0, 0, make_TLV(1, "text/x-aolrtf; charset=\"us-ascii\"") &
                                                        make_TLV(2, client_profile) &
                                                        make_TLV(3, "text/x-aolrtf; charset=\"us-ascii\"") &
                                                        make_TLV(4, "") &
                                                        make_TLV(5, {#74,#8F,#24,#20,#62,#87,#11,#D1,
                                                                     #82,#22,#44,#45,#53,#54,0,0,
                                                                     #09,#46,#13,#46,#4C,#7F,#11,#D1,
                                                                     #82,#22,#44,#45,#53,#54,0,0}))
                        -- request family 0x0003 (buddy list) limitations
                        BLEH = send_SNAC(3, 2, 0, 0, {})

                    -- rexeive family 0x0003 limitations
                    case "0303" then
                        -- request family 0x0004 (messages) parameters
                        BLEH = send_SNAC(4, 4, 0, 0, {})

                    -- receive family 0x0004 parameters
                    case "0405" then
                        max_message_size = bytesto16(snac_data[7..8]) - 16
                        -- set parameters
                        BLEH = send_SNAC(4, 2, 0, 0, snac_data)
                        -- request family 0x0009 (privacy) parameters
                        BLEH = send_SNAC(9, 2, 0, 0, {})
            
                    -- receive family 0x0009 parameters
                    case "0903" then
                        -- request SSI parameters
                        BLEH = send_SNAC(#13, 2, 0, 0, {})
                        BLEH = send_SNAC(1, #E, 0, 0, {})
                        -- check if local SSI up to date
                        BLEH = send_SNAC(#13, 5, 0, 0, {0, 0, 0, 0, 0, 0})
                        BLEH = send_SNAC(#13, 4, 0, 0, {})

                    -- receive SSI up to date or SSI update
                    case "130F", "1306" then
                        if not login_finished then
                            -- activate SSI data
                            BLEH = send_SNAC(#13, 7, 0, 0, {})
                            -- signal client ready
                            BLEH = send_SNAC(1, 2, 0, 0, families)
                            login_finished = 1
                        end if
                    
                    -- receive server message ack
                    case "040C" then
                        cookie = bytesto32(snac_data[5..8])
    
                        -- match cookie with a message and remove from list
                        for i = 1 to length(waiting_msgs) do
                            if equal(waiting_msgs[i][1], cookie) then
                                waiting_msgs = waiting_msgs[1..i - 1] & waiting_msgs[i + 1..$]
                                exit
                            end if
                        end for

                    case else
                        for i = 1 to length(snac_hooks) do
                            if equal(res[PK_DATA][1..2],
                                    snac_hooks[i][1..2]) then
                                safe_proc(snac_hooks[i][3], {res[PK_DATA]})
                            end if
                        end for
                end switch
            end if
        end if
        
        task_yield()
    end while
end procedure
