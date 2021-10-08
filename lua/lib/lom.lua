#!/usr/bin/env lua
-- ================================================================== --
-- Lua Object Model: based on lxp
-- DOM: tbm = {['.'] = tag; ['@'] = {}; ['&'] = {{}..}; {'comment'}, ...}
-- Usage example:
--      lom = require('lom')
--      doc = lom(file)
--      doc = lom() doc:parse(txt):parse() or doc:parse(txt):buildxlink()
--      xml = lom.dump(doc, true)
-- ================================================================== --
local lxp = require('lxp') -- the standard Lua Expat module
local tun = require('util') -- for path
local class = require('pool')

local next, assert, type = next, assert, type
local strlen, strsub, strmatch, strgmatch = string.len, string.sub, string.match, string.gmatch
local strrep, strgsub, strfind = string.rep, string.gsub, string.find
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
-- ================================================================== --
-- LOM (Lua Object Model)
-- ================================================================== --
local function starttag (p, name, attr) -- {{{
    local stack = p:getcallbacks().stack
    tinsert(stack, {['.'] = name, ['@'] = #attr > 0 and attr or nil})
end -- }}}
local function endtag (p, name) -- {{{
    local stack = p:getcallbacks().stack
    local element = tremove(stack)
    -- assert(element['.'] == name)
    tinsert(stack[#stack], element)
end -- }}}
local function cleantext (p, txt) -- {{{
    if strfind(txt, '%S') then
        txt = strmatch(txt, '^.*%S')
        local stack = p:getcallbacks().stack
        tinsert(stack[#stack], txt)
    end
end -- }}}
local function text (p, txt) -- {{{
    local stack = p:getcallbacks().stack
    tinsert(stack[#stack], txt)
end -- }}}
local function comment (p, txt) -- {{{
    local stack = p:getcallbacks().stack
    tinsert(stack[#stack], {txt})
end -- }}}

local function parse (o, txt) -- friend function {{{
    local p = o.docs[o.root] -- root = ''
    local status, msg, line, col, pos = p:parse(txt) -- passed nil if failed
    if not (txt and status) then
        o.docs[o.root] = p:getcallbacks().stack[1]
        o.docs[o.root]['?'] = status and {} or {msg..' #'..line}
        p:close() -- seems destroy the lxp obj
        o.parse = nil
        o:buildxlink()
    end
    return o -- for cascade oop
end --}}}

local function parseXml (o, filename, mode) -- friend function {{{
    if o.docs[filename] then return filename end

    local p = lxp.new {
        StartElement = starttag,
        EndElement = endtag,
        CharacterData = mode and text or cleantext,
        Comment = mode and comment or nil,
        _nonstrict = true,
        stack = {{}}
    }

    -- HTML
    -- '<?xml version="1.0" encoding="utf-8"?><html xmlns="http://www.w3.org/1999/xhtml">\n')
    -- content
    -- '\n</html>'

    if filename then
        filename = tun.normpath(filename)
        local file, msg = io.open(filename, 'r')
        if not file then
            o.docs[filename] = {['?'] = {msg}}
            return filename
        end
        local status, msg, line, col, pos = p:parse(file:read('*all'))
        file:close()
        if status then status, msg, line = p:parse() end
        o.docs[filename] = p:getcallbacks().stack[1]
        o.docs[filename]['?'] = status and {} or {msg..' #'..line}
        p:close()
    else
        filename = ''
        o.docs[filename] = p
        o.parse = parse
    end
    return filename
end --}}}
-- ================================================================== --
local function strToTbl (tmpl, sep, set) -- {{{ -- build the tmpl from string
    local res = {}
    if tmpl then
        set = set or '='
        for token in strgmatch(strgsub(tmpl, sep or ',', ' '), '(%S+)') do
            local k, v = strmatch(token, '([^'..set..']+)'..set..'(.*)')
            if k and v and k ~= '' then
                local q, qo = strmatch(v, '^([\'"])(.*)%1$') -- trim qotation mark
                res[k] = qo or v
            else -- also numbered
                tinsert(res, token)
            end
        end
    end
    return res
end -- }}}

local function xPath (o, path, doc) -- {{{ return doc/xml-node table, missingTag
    if (not path) or path == '' or #doc == 0 then return doc, path end
    -- NB: xpointer does not have standard treatment
    -- /A/B[@attr="val",@bb='4']
    -- anywhere/A/B/1/-2/3
    local anywhere = strsub(path, 1, 1) ~= '/'
    local tag, attr
    tag, path = strmatch(path, '([^/]+)(.*)$')
    local idx = tonumber(tag)
    if idx then return xPath(o, path, {doc[idx % #doc]}) end
    tag, attr = strmatch(tag, '([^%[]+)%[?([^%]]*)')
    local attrspec = strToTbl(attr)
    -- print(tag, path)

    local xn = {} -- xml-node (doc)
    local docl = doc['&']
    local docn = docl and 0 or false
    repeat
        for i = 1, #doc do
            local mt = doc[i]
            if type(mt) == 'table' then
                if mt['.'] == tag and ((attr == '') or tun.match(mt['@'], attrspec)) then
                    if path == '' then -- final res
                        tinsert(xn, mt)
                    else -- build intermediate working res
                        for j = 1, #mt do tinsert(xn, mt[j]) end
                    end
                elseif anywhere and (#mt > 0 or mt['&']) then
                    -- print(tag, mt['.'], path, attr, mt, mt['&'])
                    local tagatt = tag..attr..path
                    local mtl = mt['&']
                    local mtn = mtl and 0 or false
                    repeat
                        local sub = xPath(o, tagatt, mt)
                        for j = 1, #sub do tinsert(xn, sub[j]) end
                        if mtn then mtn = mtn < #mtl and mtn + 1 end
                        mt = mtn and mtl[mtn]
                    until not mt
                end
            end
        end
        if docn then docn = docn < #docl and docn + 1 end
        doc = docn and docl[docn]
    until not doc
    return xPath(o, path, xn)
end -- }}}
-- ================================================================== --
local function xmlstr (s, fenc) -- {{{
    -- encode: gzip -c | base64 -w 128
    -- decode: base64 -i -d | zcat -f
    -- return '<!-- base64 -i -d | zcat -f -->{{{'..
    --     tun.popen(s, 'tun.gzip -c | base64 -w 128'):read('*all')..'}}}'
    s = tostring(s)
    if strfind(s, '\n') or (strlen(s) > 1024) then -- large text
        if fenc or strfind(s, ']]>') then -- enc flag or hostile strings
            local status, stdout, stderr = tun.popen(s, 'gzip -c | base64 -w 128')
            return '<!-- base64 -i -d | zcat -f -->{{{'..stdout..'}}}'
        else
            -- return (strfind(s, '"') or strfind(s, "'") or strfind(s, '&') or
            --         strfind(s, '<') or strfind(s, '>')) and '<![CDATA[\n'..s..']]>' or s
            return (strfind(s, '&') or strfind(s, '<') or strfind(s, '>'))
                and '<![CDATA[\n'..s..']]>' or s
        end
    else -- escape characters
        return strgsub(strgsub(strgsub(strgsub(strgsub(s,
            '&', '&amp;'), '"', '&quot;'), "'", '&apos;'), '<', '&lt;'), '>', '&gt;')
    end
end -- }}}

local function dumpLom (node) -- {{{
    if 'string' == type(node) then return node end
    if not node['.'] then return node[1] and '<!--'..node[1]..'-->' end
    local res = {}
    if node['@'] then
        for _, k in ipairs(node['@']) do tinsert(res, k..'="'..strgsub(node['@'][k], '"', '\\"')..'"') end
    end
    res = '<'..node['.']..(#res > 0 and ' '..tconcat(res, ' ') or '')
    if #node == 0 then return res..' />' end
    res = {res..'>'}
    for i = 1, #node do tinsert(res, type(node[i]) == 'table' and dumpLom(node[i]) or xmlstr(node[i])) end
    if #res == 2 and #(res[2]) < 100 and not strfind(res[2], '\n') then
        return res[1]..res[2]..'</'..node['.']..'>'
    end
    return strgsub(tconcat(res, '\n'), '\n', '\n  ')..'\n</'..node['.']..'>' -- indent 2
end -- }}}

local lom = class {
    docs = false;
    root = false;

    parse = false; -- implemented in friend function

    xpath = function (o, path, doc) return xPath(o, path, doc or o.docs[o.root]) end;

    buildxlink = function (o) -- xlink/xpointer based on root {{{
        if o.parse then o:parse() end
        local stamp = math.random()
        local stack = {}
        local function traceTbl (doc, xml) -- {{{ lua table form
            local href = doc['@'] and doc['@']['xlink:href']
            if href then -- print(xml..'<'..doc['.']..'>'..href)
                tinsert(stack, xml..'<'..doc['.']..'>'..href)
                if stack[href] then
                    return tinsert(o.docs[xml]['?'], 'loop '..tconcat(stack, '->'))
                end
                stack[href] = true
            end
            if href and ((not doc['&']) or (doc['&']['#'] ~= stamp)) then -- attr
                local link, xpath = strmatch(href, '^([^#]*)(.*)') -- {{{ file_link, tag_path
                if link == '' then -- back to this doc root
                    link = xml
                else -- new file
                    if strsub(link, 1, 1) ~= '/' then link = strgsub(xml, '[^/]*$', '')..link end
                    link = tun.normpath(link)
                end -- }}}

                if not o.docs[link] then parseXml(o, link) end
                if xml ~= link then traceTbl(o.docs[link], link) end
                link, xpath = xPath(o, strmatch(xpath or '', '#xpointer%((.*)%)'), o.docs[link])

                if #link == 0 then -- error message
                    tinsert(o.docs[xml]['?'], 'broken <'..doc['.']..'> '..xpath)
                    doc['&'] = nil
                else
                    doc['&'] = link -- xlink
                    link['#'] = stamp
                    -- print(doc['@']['xlink:href'], 'linked', #link)
                end
            end
            if href then
                stack[href] = nil
                tremove(stack) -- #stack
            end
            for i = 1, #doc do -- continous override
                if type(doc[i]) == 'table' and doc[i]['.'] then traceTbl(doc[i], xml) end
            end
        end -- }}}
        local doc = o.docs[o.root]
        if #doc['?'] == 0 then traceTbl(doc, o.root) end -- no error msg
    end; -- }}}

    ['<'] = function (o, data) --{{{
        o.docs = {}
        if type(data) == 'table' then -- partial table-tree
            local n = {}
            for _, v in pairs(data) do tinsert(n, v) end
            o.root = ''
            o.docs[o.root] = n
        else -- data is nil or filename
            o.root = parseXml(o, data)
            if data then o:buildxlink() end
        end
    end; --}}}

    -- output
    dump = function (o, fxml) -- {{{ dump fxml=1/html
        if not fxml then return tun.dumpVar(0, o.docs[o.root]) end
        local res = {fxml == 1 and '<?xml version="1.0" encoding="UTF-8"?>' or nil}
        for j = 1, #(o.docs[o.root]) do tinsert(res, dumpLom(o.docs[o.root][j])) end
        return tconcat(res, '\n')
    end;-- }}}

    -- member functions support cascade oo style
    selectAll = function (o, path) return class:new(o, o:xpath(path)) end;

    select = function (o, path) return class:new(o, o:xpath(path..'/1')) end;

    attr = function (o, var, val) -- TODO
        if val then
            return o
        end
        local vals = {}
        return vals
    end;
}
-- ================================================================== --
-- service for checking object model -- {{{
if arg and #arg > 0 and strgsub(arg[0], '^.*/', '') == 'lom.lua' then
    local doc = lom(arg[1] == '-' and nil or arg[1])
    if arg[1] == '-' then doc:parse(io.stdin:read('a')):parse() end
    print(doc.docs[o.root]['?'][1] or doc:dump())
end -- }}}

return lom
--[[ {{{  MINI TUTORIAL https://matthewwild.co.uk/projects/luaexpat/manual.html
-- ================================================================== --
lxp.new(callbacks [, separator])
    The optional separator character in the parser constructor defines the character used
    in the namespace expanded element names.  The separator character is optional (if not
    defined the parser will not handle namespaces) but if defined it must be different from
    the character '\0'.

callbacks.StartNamespaceDecl = function(parser, namespaceName)
    Called when the parser detects an XML namespace declaration with namespaceName.
    Namespace declarations occur inside start tags, but the StartNamespaceDecl handler is
    called before the StartElement handler for each namespace declared in that start tag.

callbacks.EndNamespaceDecl = function(parser, namespaceName)
    Called when the parser detects the ending of an XML namespace with namespaceName.
    The handling of the End namespace is done after the handling of the End tag For the element
    the namespace is associated with.

callbacks.StartDoctypeDecl = function(parser, name, sysid, pubid, has_internal_subset)
    Called when the parser detects the beginning of an XML DTD (DOCTYPE) section. These
    precede the XML root element and take the form:

        <!DOCTYPE root_elem PUBLIC 'example'>

callbacks.UnparsedEntityDecl = function(parser, entityName, base, systemId, publicId, notationName)
    Called when the parser receives declarations of unparsed entities. These are entity
    declarations that have a notation (NDATA) field. As an example, in the chunk

        <!ENTITY logo SYSTEM 'images/logo.gif' NDATA gif>

    entityName would be 'logo', systemId would be 'images/logo.gif' and notationName would be 'gif'.
    For this example the publicId parameter would be nil. The base parameter would be whatever has
    been set with parser:setbase. If not set, it would be nil.

callbacks.NotationDecl = function(parser, notationName, base, systemId, publicId)
    Called when the parser detects XML notation declarations with notationName
    The base parameter is the base to use for relative system identifiers. It is set
    by parser:setbase and may be nil. The systemId parameter is the system identifier
    specified in the entity declaration and is never nil. The publicId parameter is
    the public id given in the entity declaration and may be nil.

callbacks.CharacterData = function(parser, string)
    Called when the parser recognizes an XML CDATA string.

callbacks.StartCdataSection = function(parser)
    Called when the parser detects the begining of an XML CDATA section.

callbacks.EndCdataSection = function(parser)
    Called when the parser detects the End of a CDATA section.

callbacks.Comment = function(parser, string)
    Called when the parser recognizes an XML comment string.

callbacks.Default = function(parser, string)
    Called when the parser has a string corresponding to any characters In the document
    which wouldnot otherwise be handled.
    Using this handler has the side effect of turning off expansion of references to
    internally defined general entities.
    Instead these references are passed to the default handler.

callbacks.DefaultExpand = function(parser, string)
    Called when the parser has a string corresponding to any characters In the document
    which wouldnot otherwise be handled.
    Using this handler doesnot affect expansion of internal entity references.

callbacks.StartElement = function(parser, elementName, attributes)
    Called when the parser detects the begining of an XML element with elementName.
    The attributes parameter is a Lua table with all the element attribute names and values.
    The table contains an entry for every attribute in the element start tag and entries for
    the default attributes for that element. The attributes are listed by name (including the
    inherited ones) and by position (inherited attributes are not considered in the position list).
    As an example if the book element has attributes author, title and an optional format
    attribute (with 'printed' as default value),

        <book author='Ierusalimschy, Roberto' title='Programming in Lua'>

    would be represented as

        {[1] = 'Ierusalimschy, Roberto',
        [2] = 'Programming in Lua',
        author = 'Ierusalimschy, Roberto',
        format = 'printed',
        title = 'Programming in Lua'}

callbacks.EndElement = function(parser, elementName)
    Called when the parser detects the ending of an XML element with elementName.

callbacks.ExternalEntityRef = function(parser, subparser, base, systemId, publicId)
    Called when the parser detects an external entity reference.
    The subparser is a LuaExpat parser created with the same callbacks and Expat context
    as the parser and should be used to parse the external entity.
    The base parameter is the base to use for relative system identifiers.
    It is set by parser:setbase and may be nil. The systemId parameter is the system
    identifier specified in the entity declaration and is never nil.
    The publicId parameter is the public id given in the entity declaration and may be nil.

callbacks.NotStandalone = function(parser)
    Called when the parser detects that the document is not 'standalone'.
    This happens when there is an external subset or a reference to a parameter entity,
    but the document does not have standalone set to 'yes' in an XML declaration.

callbacks.ProcessingInstruction = function(parser, target, data)
    Called when the parser detects XML processing instructions. The target is the first word
    in the processing instruction.
    The data is the rest of the characters in it after skipping all whitespace after the initial word.

XML in general
    XML elements must follow these naming rules:

    Element names are case-sensitive
    Element names must start with a letter or underscore
    Element names cannot start with the letters xml (or XML, or Xml, etc)
    Element names can contain letters, digits, hyphens, underscores, and periods
    Element names cannot contain spaces
    Any name can be used, no words are reserved (except xml).
--]]
-- ================================================================== --
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
