#!/usr/bin/env lua
-- ======================================================================== --
-- utility subroutine
-- ======================================================================== --
local tun = {cvs_id = "$Id: $"}

-- ======================================================================== --
local strgsub, strsub, strgmatch, strmatch, strfind =
    string.gsub, string.sub, string.gmatch, string.match, string.find
local tinsert, tremove, tconcat =
    table.insert, table.remove, table.concat

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
tun.Dbg = function (msg) -- {{{
    if tun.debug then tun.info(msg, 'DBG:') end
end -- }}}
-- ======================================================================== --
-- ===================  EXTERNAL SUBPROCESS COMMAND   ===================== --
-- ======================================================================== --
local posix = require('posix')
tun.popen = function (datastr, cmd) -- {{{ status, out, err = tun.popen(in, cmd)
    --  thread
    --  |
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
    if multi then cmd = string.gsub(cmd, ';', ' >& /dev/null;') end
    return assert(os.execute(cmd..' >& /dev/null'))
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
-- ======================================================================== --
-- =========================  SIMPLE I/O  ================================= --
-- ======================================================================== --
tun.Load = function (filename) -- {{{
    local file, msg = io.open(filename, 'r')
    if file == nil then error(msg) end
    local chunk = file:read('*all')
    file:close()
    return chunk
end -- }}}
tun.Dump = function (o, filename) -- {{{
    local file, msg = io.open(filename, 'w')
    if file == nil then error(msg) end
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
        tinsert(res, strmatch(tostring(select(i, ...)), '(%S.*%S)') or '')
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
tun.normpath = function (path) -- {{{ full, base, name
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
    local res = {}
    if tmpl then
        set = set or '='
        for token in strgmatch(strgsub(tmpl, sep or ',', ' '), '(%S+)') do
            local k, v = strmatch(token, '([^'..set..']+)'..set..'(.*)')
            if k and v and k ~= '' then
                local q, qo = strmatch(v, '^([\'"])(.*)%1$') -- trim qotation mark
                res[k] = qo or v
            end
        end
    end
    return res
end -- }}}
tun.match = function (targ, tmpl) -- {{{ -- match assignment in tmpl
    if type(targ) ~= 'table' then return not next(tmpl) end
    if tmpl then
        for k, v in pairs(tmpl) do if targ[k] ~= v then return false end end
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
-- =========================  debug info gadgets ========================== --
-- ======================================================================== --
tun.whos = function (t) -- {{{
    for k, v in pairs(type(t) == 'table' and t or _ENV) do
        if type(k) == 'string' then print(k, v) end
    end
end -- }}}
return tun
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
