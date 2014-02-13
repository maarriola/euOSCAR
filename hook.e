global sequence snac_hooks, idle_hooks

snac_hooks = {}
idle_hooks = {}

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


