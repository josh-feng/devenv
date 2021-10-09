#!/usr/bin/env lua
-- ======================================================================== --
-- utility subroutine
-- ======================================================================== --
local tun = {id = ''} -- version control

-- ======================================================================== --
local strgsub, strsub, strgmatch, strmatch, strfind =
    string.gsub, string.sub, string.gmatch, string.match, string.find
local tinsert, tremove, tconcat, tsort =
    table.insert, table.remove, table.concat, table.sort

tun.Timestamp = false
local Log
tun.log = function (logfile) -- {{{ initially no log file: log('logfile')
    Log = {file = io.open(logfile, 'w')}
    if Log.file then
        setmetatable(Log, {__gc = function (o) if o.file then o.file:close() end end})
        tun.log = nil -- self destructive, only one log per run
    else
        tun.info('WRN: failed writing '..logfile)
    end
end -- }}}
tun.info = function (msg, header) -- {{{ message and header: info('msg', 'ERR')
    header = header and header..' ' or ''
    if tun.Timestamp then header = os.date('%T')..' '..header end
    msg = header..tun.concat(msg, '\n'..header)
    if Log and Log.file then Log.file:write(msg..'\n') end
    print(msg)
end -- }}}
tun.fatal = function (msg) -- {{{ fatal('err msg')
    if msg then tun.info('ERR: '..msg) end
    os.exit(msg and 1 or 0)
end -- }}}
tun.Dbg = function (msg) if tun.debug then tun.info(msg, 'DBG:') end end
-- ======================================================================== --
-- ===================  EXTERNAL SUBPROCESS COMMAND   ===================== --
-- ======================================================================== --
local posix = require('posix')
tun.popen = function (datastr, cmd) -- {{{ status, out, err = tun.popen(in, cmd)
    --  thread
    --  +--------+
    --  |        |
    --  | i-rw-> | pipe (is uni-directional)
    --  | <-rw-o | pipe
    --  | <-rw-e | ...
    --  | ...... |
    --  V        V
    --  Parent   Children

    -- usage example: local status, out, err = tun.popen(in, 'wc -c')
    local ri, wi = posix.pipe() -- for child stdin
    local ro, wo = posix.pipe() -- for child stdout
    local re, we = posix.pipe() -- for child stderr
    assert(wi or ro or re, 'pipe() failed')
    local pid, err = posix.fork() -- child proc
    if pid == 0 then -- for child proc {{{
        posix.close(wi)
        posix.close(ro)
        posix.close(re)
        posix.dup2(ri, posix.fileno(io.stdin))
        posix.dup2(wo, posix.fileno(io.stdout))
        posix.dup2(we, posix.fileno(io.stderr))
        -- local ret, err = posix.execp(path, argt or {}) -- w/ shell
        local ret, err = posix.exec('/bin/sh', {'-c', cmd}) -- w/o shell
        posix.close(ri)
        posix.close(wo)
        posix.close(we)
        posix._exit(1)
    end -- }}}
    -- for parent proc
    posix.close(ri)
    posix.close(wo)
    posix.close(we)

    -- pid, wi, ro, re -- posix pid and posix's filedes
    -- send to stdin
    posix.write(wi, datastr)
    posix.close(wi)
    -- get from stdout
    local stdout = {}
    while true do
        local buf = posix.read(ro, 4096)
        if buf == nil or #buf == 0 then break end
        tinsert(stdout, buf)
    end
    -- posix.close(r3)
    local stderr = {}
    while true do
        local buf = posix.read(re, 4096)
        if buf == nil or #buf == 0 then break end
        tinsert(stderr, buf)
    end
    return posix.wait(pid), tconcat(stdout), tconcat(stderr)
end -- }}}

tun.Cmd = function (cmd, multi) -- {{{ the system should do as told quietly: Cmd('cd / ; ls', true)
    tun.Dbg(cmd)
    if multi then cmd = string.gsub(cmd, ';', ' > /dev/null 2>&1 ;') end
    return assert(os.execute(cmd..' > /dev/null 2>&1'))
end -- }}}
tun.Ask = function (cmd, multi) -- {{{ Est-ce-que (Alor, on veut savoir le resultat)
    tun.Dbg(cmd)
    if multi then cmd = string.gsub(cmd, ';', ' 2>&1;') end
    -- NB: lua use (POSIX) sh, we can use 2>&1 to redirect stderr to stdout
    local file = io.popen(cmd..' 2>&1', 'r')
    local msg = file:read('*all')
    file:close()
    return msg
end -- }}}
tun.Put = function (str, cmd) -- {{{ Put to stdin (str?)
    tun.Dbg(cmd)
    local file = io.popen(cmd, 'w')
    local result = file:write(str)
    file:close()
end -- }}}
tun.exist = function (path) -- {{{
    path = io.open(path, 'r')
    return path and (path:close() or true)
end -- }}}
tun.isdir = function (path) return tun.exist(path..'/.') end
-- ======================================================================== --
-- =========================  SIMPLE I/O  ================================= --
-- ======================================================================== --
tun.loadStr = function (filename, verify) -- {{{ load a file into a string
    local file, msg = io.open(filename, 'r')
    if file == nil then return verify and error(msg) end
    local chunk = file:read('*all')
    file:close()
    return chunk
end -- }}}
tun.dumpStr = function (o, filename, verify) -- {{{ dump a string to a file
    local file, msg = io.open(filename, 'w')
    if file == nil then return verify and error(msg) or msg end
    file:write(type(o) == 'table' and tun.concat(o, '\n') or tostring(o))
    file:close()
end -- }}}
-- ======================================================================== --
-- ========================  TABLES FUNCTIONS  ============================ --
-- ======================================================================== --
tun.concat = function (o, sep) -- string or table {{{
    if type(o) ~= 'table' then return tostring(o) end
    local t = {}
    for i, v in ipairs(o) do tinsert(t, tostring(v)) end -- make entry string
    return tconcat(t, sep or '\n')
end -- }}}
tun.tappi = function (src, targ) -- {{{ append src table to targ table
    local t = type(targ) == 'table' and targ or {}
    if type(src) == 'table' then
        for _, v in ipairs(src) do tinsert(t, v) end
    elseif type(src) then
        tinsert(t, src)
    end
    return t
end -- }}}
tun.traceTbl = function (tbl, testkey, procvalue, ...) -- {{{ table trace
    for k, v in pairs(tbl) do
        if testkey(k) then
            procvalue(v, ...) -- record in ...
        elseif type(v) == 'table' then -- trace the sub table
            tun.traceTbl(v, testkey, procvalue, ...)
        end
    end
end -- }}}
-- ======================================================================== --
-- ========================  STRING FUNCTIONS  ============================ --
-- ======================================================================== --
tun.Split = function (str, sep) -- {{{ split string w/ ':' into a table
    if type(str) ~= 'string' then return end
    local t = {}
    sep = sep or ':'
    for o in strgmatch(str..sep, '([^'..sep..']-)'..sep) do tinsert(t, o) end
    return t
end -- }}}
tun.Cut = function (str, sep) -- {{{ cut string w/ '-' into 2 parts
    if type(str) ~= 'string' then return end
    local f1, rest = strmatch(str, '^([^%'..(sep or '-')..']+)(.*)')
    return f1, (#rest > 0) and strsub(rest, 2, -1) or nil
end -- }}}
tun.strpm = function (str) -- pattern matching string {{{ -- escape: ().%+-*?[^$
    return strgsub(strgsub(strgsub(strgsub(strgsub(
        strgsub(strgsub(strgsub(strgsub(strgsub(str,
        '%%', '%%%%'), '%(', '%%('), '%)', '%%)'), '%+', '%%+'), '%-', '%%-'),
        '%.', '%%.'), '%*', '%%*'), '%?', '%%?'), '%[', '%%['), '%^', '%%^')
end -- }}}
tun.trim = function (...) -- {{{ trim space
    local res = {}
    for i = 1, select('#', ...) do
        tinsert(res, strmatch(tostring(select(i, ...)), '(%S.-)%s*$') or '')
    end
    return table.unpack(res)
end -- }}}

tun.realpath = function (bin) -- {{{ trace the binary link / realpath
    repeat
        local l = strmatch(io.popen('ls -ld '..bin..' 2>/dev/null'):read('*all'), '->%s+(.*)') -- link
        if l then bin = strsub(l, 1, 1) == '/' and l or strgsub(bin, '[^/]*$', '')..l end
    until not l
    return tun.normpath(bin)
end -- }}}
tun.normpath = function (path, pwd) -- {{{ full, base, name
    if pwd and strsub(path, 1, 1) ~= '/' then path = pwd..'/'..path end
    local o = {}
    for i, v in ipairs(tun.Split(strgsub(path, '/+/', '/'), '/')) do
        if v == '..' then
            if #o == 0 or o[#o] == '..' then tinsert(o, v) elseif o[#o] ~= '' then tremove(o) end
        elseif v ~= '.' then
            tinsert(o, v)
        end
    end
    o = tun.trim(tconcat(o, '/'))
    return o, strmatch(o, '(.-/?)([^/]+)$') -- full, base, name
end -- }}}
tun.getstem = function (path) -- {{{
    return strgsub(strgsub(path, '^.*/', ''), '%.[^.]*$', '')
end -- }}}

tun.tblToStr = function (tbl, sep) -- {{{ build the set
    local res = {}
    local assign = (sep and string.len(sep) > 1) and ' = ' or '='
    for k, v in pairs(tbl) do table.insert(res, k..assign..tostring(v)) end
    table.sort(res)
    return tconcat(res, sep or ',')
end -- }}}
tun.strToTbl = function (tmpl, sep, set) -- {{{ -- build the tmpl from string
    local res, order = {}
    if tmpl then
        set = set or '='
        for token in strgmatch(strgsub(tmpl, sep or ',', ' '), '(%S+)') do
            local k, v = strmatch(token, '([^'..set..']+)'..set..'(.*)')
            if k and v and k ~= '' then
                local q, qo = strmatch(v, '^([\'"])(.*)%1$') -- trim qotation mark
                res[k] = qo or v
            elseif sep then -- also numbered
                tinsert(res, token)
            else
                order = token
            end
        end
    end
    return res, tonumber(order)
end -- }}}
tun.match = function (targ, tmpl, fExact) -- {{{ -- match assignment in tmpl
    if type(targ) ~= 'table' then return not next(tmpl) end
    if tmpl then
        for k, v in pairs(tmpl) do
            if (type(k) == 'number' and type(v) == 'string' and targ[v] == nil)
                or (targ[k] ~= v) then
                return false
            end
        end
    end
    if fExact then
        for k in pairs(targ) do if tmpl[k] == nil then return false end end
    end
    return true
end -- }}}

tun.check = function (v) -- {{{ -- check v is true or false
    if type(v) == 'boolean' then return v end
    if tonumber(v) then return tonumber(v) ~= 0 end
    v = string.lower(tostring(v))
    return (v == 'true') or (v == 'yes') or (v == 'y')
end -- }}}
-- ======================================================================== --
local function dumpVar (key, value, ctrl) -- {{{ dump variables in lua
    key = (type(key) == 'string' and strfind(key, '%W')) and '["'..key..'"]' or key
    local assign = type(key) == 'number' and '' or key..' = '
    if type(value) == 'number' then return assign..value end
    if type(value) == 'string' then return assign..'"'..strgsub(value, '"', '\\"')..'"' end
    if type(value) ~= 'table' then return '' end
    tinsert(ctrl, type(key) == 'number' and '['..key..']' or key) -- increase the depth
    local extdef, keyhead = ''
    if ctrl.ext then -- the depths to external {{{
        for _ = 1, #(ctrl.ext) do
            if #ctrl == ctrl.ext[_] then
                keyhead = strgsub(tconcat(ctrl, "."), '%.%[', '[')
                break
            end
        end
    end -- }}}
    local res, kset, tmp1 = {}, {}, ctrl['L'..#ctrl]
    for k, v in pairs(value) do
        if type(k) == 'string' then
            tinsert(kset, k)
        elseif type(v) == 'table' and type(k) == 'number' then -- 2D format
            tmp1 = false
        end
    end

    if #value > 0 then -- {{{
        if keyhead then
            for i = #value, 1, -1 do -- {{{
                local v = dumpVar(i, value[i], ctrl)
                if v ~= '' then tinsert(ctrl.def, 1, keyhead..'['..i..'] = '..v) end
            end -- }}}
        else
            for i = 1, #value do -- {{{
                local v = dumpVar(i, value[i], ctrl)
                if v ~= '' then tinsert(res, v) end
            end -- }}}
        end
        if tmp1 and (#res > ctrl['L'..#ctrl]) then -- level L# 2D table @ column
            local w, m = ctrl['L'..#ctrl], {} -- {{{
            for i = 0, #res - 1 do
                local l = string.len(tostring(res[i + 1]))
                m[i % w] = (m[i % w] and m[i % w] >= l) and m[i % w] or l
            end
            for i = 0, #res - 1 do
                res[i + 1] = string.format((i > 0 and (i % w) == 0 and '\n%' or '%')..m[i % w]..'s,', res[i + 1])
            end
            res = {tconcat(res, ' ')} -- }}}
        else --
            tmp1 = false
            res = tconcat(res, ',\n')
            if string.len(res) < ctrl.len then res = strgsub(res, '\n', ' ') end
            res = {res}
        end
    end -- }}}
    if #kset > 0 then -- {{{
        table.sort(kset)
        for i = 1, #kset do
            local v = dumpVar(kset[i], value[kset[i]], ctrl)
            if v ~= '' then -- {{{
                if keyhead then -- recursive so must be the first
                    tinsert(ctrl.def, 1, keyhead..(strsub(v, 1, 1) == '[' and v or '.'..v))
                else
                    tinsert(res, v)
                end
            end -- }}}
        end
    end -- }}}
    kset = #res
    tremove(ctrl)
    res = tconcat(res, ',\n')
    if #ctrl == 0 and #(ctrl.def) > 0 then extdef = '\n'..tconcat(ctrl.def, '\n') end
    if not strfind(res, '\n') then return assign..'{'..res..'}'..extdef end
    if (not tmp1) and string.len(res) < ctrl.len and kset < ctrl.num then
        return assign..'{'..strgsub(res, '\n', ' ')..'}'..extdef
    end
    tmp1 = string.rep(' ', 4)
    return assign..'{\n'..tmp1..strgsub(res, '\n', '\n'..tmp1)..'\n}'..extdef
end -- }}}
tun.dumpVar = function (key, value, ext) -- {{{
    -- e.g. print(tun.dumpVar('a', a, {1, L4=3}))
    -- e.g. print(tun.dumpVar('a', a,
    -- {1, ['a.b.1.3.5'] = 'ab',
    --     ['a.b.1.3.5'] = 13,
    -- }))
    local ctrl = {def = {}, len = 111, num = 11} -- external definitions m# = cloumn_num
    if type(ext) == 'table' then -- {{{
        ctrl.len = ext.len or ctrl.len -- max txt width
        ctrl.num = ext.num or ctrl.num -- max items in one line table
        for k, v in pairs(ext) do
            if type(k) == 'string' and strmatch(k, '^L%d+$') and tonumber(v) and v > 1 then ctrl[k] = v end
        end
        ctrl.ext = ext -- control table
    end -- }}}
    return dumpVar(key, value, ctrl)
end -- }}}
-- ======================================================================== --
-- =========================  debug info gadgets ========================== --
-- ======================================================================== --
tun.whos = function (t) -- {{{
    for k, v in pairs(type(t) == 'table' and t or _ENV) do
        if type(k) == 'string' then print(k, v) end
    end
end -- }}}
return tun
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
