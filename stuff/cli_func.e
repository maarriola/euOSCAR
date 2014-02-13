include html.e

sequence msg
integer msg_parser

msg = {}

function msg_text (sequence str)
    msg &= str

    return 1
end function

procedure bot_msg(sequence from, sequence text)
    printf(1, "%s: '%s'\n", {from, text})

    if equal("kebert xela", lower(msg)) then
        ? 1 / 0
    end if
end procedure

msg_hook = routine_id("bot_msg")
msg_parser = new_html_parser()
set_text_routine(msg_parser, routine_id("msg_text"))

