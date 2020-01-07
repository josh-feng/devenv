#!/usr/bin/env lua
-- ======================================================================== --
-- Lua XML Table (Object Model)
-- Usage example:
--      lxt = require('lxt')
--      doc = lxt.ParseXml(file)
--      xml = lxt.Dump(doc, true)
-- ======================================================================== --
local lxt = {id = ''} -- version control

local lxp = require('lxp') -- the standard Lua Expat module
local tun = require('util') -- for path

local next, assert, type = next, assert, type
local strlen, strsub, strmatch, strgmatch = string.len, string.sub, string.match, string.gmatch
local strrep, strgsub, strfind = string.rep, string.gsub, string.find
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat

lxt.indent, lxt.cdata = strrep(' ', 2), 1024 -- zip threshold
-- ======================================================================== --
-- LXT (Lua XML Table)
-- ======================================================================== --
-- node == token == tag == table
lxt.Parse = function (txt, mode) -- {{{ trim the leading and tailing space of data 1:blank line
    mode = tonumber(mode) or 0
    local trim = mode % 2 -- trim: 0/1 (html:+2)
    local node = {} -- working variable: doc == root node (node == token == tag == table)
    local cdata = 0

    local lxtcallbacks = {
        StartElement = function (parser, name, attr) -- {{{
            if #attr > 0 then
                attr['@'] = tconcat(attr, ' ')
                for i = 1, #attr do attr[i] = nil end
            end
            attr['.'] = node -- record parent node
            node = attr
        end; -- }}}
        EndElement = function (parser, name) -- {{{
            node[0] = name
            tinsert(node['.'], node)
            node, node['.'] = node['.'], nil -- record the tag/node name
        end; -- }}}
        CharacterData = function (parser, s) -- {{{
            if strmatch(s, '%S') then
                if cdata == 0 then
                    s = strmatch(strgsub(s, '%s+', ' '), '^(.-)%s*$') -- space
                else
                    if trim > 0 then s = strgsub(s, '^%s*\n', '') end -- empty line CDATA
                    s = strgsub(s, '%s*\n', '\n') -- clean end space
                end
                tinsert(node, strmatch(s, (cdata == 1 and '^(' or '(%S')..'.-)%s*$'))
            end
        end; -- }}}
        StartCdataSection = function(parser) cdata = 1 end;
        EndCdataSection = function(parser) cdata = 0 end;
    }

    local plxt = lxp.new(lxtcallbacks)
    if mode > 2 then
        plxt:parse('<?xml version="1.0" encoding="utf-8"?><html xmlns="http://www.w3.org/1999/xhtml">\n')
    end
    local status, msg, line, col, pos = plxt:parse(txt) -- passed nil if failed
    if mode > 2 then plxt:parse('\n</html>') end
    plxt:parse()
    plxt:close() -- seems destroy the lxp obj
    node['?'] = status and {} or {msg..' #'..line}
    return node
end
-- }}}
-- ======================================================================== --
lxt.genDoc = function (doc) -- {{{
    if type(doc) == 'table' and doc['@'] == nil then
        local attr = {}
        for k, v in pairs(doc) do
            if type(k) == 'number' then
                if type(v) == 'table' then lxt.genDoc(v) end
            elseif string.find(k, '^[_%w]') then
                tinsert(attr, k)
            end
        end
        if #attr > 0 then doc['@'] = tconcat(table.sort(attr) or attr, ' ') end
    end
    return doc
end -- }}}
tun.xnVal = function (doc, ftop) -- {{{ ftop: []/all-sub-node 0/+/-:top
    if type(doc) ~= 'table' then return doc end
    local res, i = {}, 1
    ftop = tonumber(ftop)
    repeat -- collect along the metatable (if mode is defined)
        local mt = ftop and doc or doc[i]
        repeat -- collect along the metatable -- only values
            for j = 1, #mt do if type(mt[j]) ~= 'table' then tinsert(res, mt[j]) end end
            mt = getmetatable(mt)
            if mt then mt = mt.__index end
        until not mt
        if not ftop then i = i + 1 end
    until ftop or i > #doc
    if not ftop then return tconcat(res, '\n') end
    res = strgsub(strmatch(tconcat(res, ' '), '(%S.-)%s*$') or '', '%s+', ' ')
    return ftop == 0 and tun.Split(res, ' ') or res
end -- }}}
lxt.xPath = function (doc, path) -- {{{ return doc/xml-node table, missingTag
    if (not path) or path == '' or #doc == 0 then return doc, path end
    -- NB: xpointer does not have standard treatment -- A/B, /A/B[attr="val",bb='4']
    local tag, attr, idx
    tag, path = strmatch(path, '([^/]+)(.*)$')
    tag, attr = strmatch(tag, '([^%[]+)%[?([^%]]*)')
    attr, idx = tun.strToTbl(attr) -- idx: []/all, [-]/last, [0]/merged, [+]/first
    local xn = {} -- xml-node (doc)
    repeat -- collect along the metatable (if mode is defined)
        for i = 1, #doc do -- no metatable
            local mt = doc[i]
            if type(mt) == 'table' and mt[0] == tag and tun.match(mt, attr) then
                if idx and idx < 0 then xn[1] = nil end -- clean up
                if path ~= '' or idx == 0 then
                    repeat -- collect along the metatable (NB: ipairs will dupe metatable)
                        for j = 1, #mt do if type(mt[j]) == 'table' or path == '' then tinsert(xn, mt[j]) end end
                        mt = getmetatable(mt)
                        if mt then mt = mt.__index end
                    until not mt
                else
                    tinsert(xn, mt)
                end
                if idx and idx > 0 then break end
            end
        end
        if idx and idx > 0 and #xn > 0 then break end
        doc = getmetatable(doc)
        if doc then doc = doc.index end
    until not doc
    return lxt.xPath((path == '' and idx == 0) and {[0] = tag; xn} or xn, path)
end -- }}}
lxt.ParseXml = function (filename, mode, doctree) -- doc = lxt.ParseXml(xmlfile, docfactory) -- {{{
    filename = tun.normpath(filename)
    if type(doctree) == 'table' and doctree[filename] then return doctree[filename] end

    local file, msg = io.open(filename, 'r')
    if not file then return {['?'] = {msg}} end
    local doc = lxt.Parse(file:read('*all'), mode) -- mode +3 for html
    file:close()

    if type(doctree) == 'table' then doctree[filename] = doc end
    return doc
end -- }}}
lxt.XmlBuild = function (xmlfile, mode) -- topxml, doctree = lxt.XmlBuild(rootfile) -- {{{ -- trace and meta
    local topxml, base = tun.normpath(xmlfile)
    local doctree = {}
    local doc = lxt.ParseXml(topxml, mode, doctree) -- doc table

    local function TraceTbl (xn, xml) -- {{{ lua xml table
        local v = xn['@'] and xn['xlink:href']
        if v then
            local link, xpath = strmatch(v, '^([^#]*)(.*)') -- {{{ file_link, tag_path
            if link == '' then -- back to this doc root
                link = xml
            else -- new file
                if strsub(link, 1, 1) ~= '/' then link = strgsub(xml, '[^/]*$', '')..link end
                link = tun.normpath(link)
            end -- }}}

            if not doctree[link] then TraceTbl(lxt.ParseXml(link, mode, doctree), link) end
            link, xpath = lxt.xPath(doctree[link], strmatch(xpath or '', '#xpointer%((.*)%)'))

            if #link == 1 then -- the linked table
                local meta = link[1]
                repeat -- loop detect {{{
                    meta = getmetatable(meta) and getmetatable(meta).__index
                    if meta == xn then break end
                until not meta -- }}}
                if meta then
                    tinsert(doctree[xml]['?'], 'loop '..v) -- error message
                elseif xn ~= link[1] then
                    setmetatable(xn, {__index = link[1]})
                    TraceTbl(link[1], xml)
                end
            else
                tinsert(doctree[xml]['?'], 'broken <'..xn[0]..'> '..xpath..':'..#link..':'..v) -- error message
            end
        end
        for i = 1, #xn do if type(xn[i]) == 'table' then TraceTbl(xn[i], xml) end end -- continuous override
    end -- }}}

    if #doc['?'] == 0 then TraceTbl(doc, topxml) end -- no error msg
    return topxml, doctree
end -- }}}
-- ======================================================================== --
-- Output
-- ======================================================================== --
lxt.xmlstr = function (s, fenc) -- {{{
    -- encode: gzip -c | base64 -w 128
    -- decode: base64 -i -d | zcat -f
    -- return '<!-- base64 -i -d | zcat -f -->{{{'..
    --     tun.popen(s, 'tun.gzip -c | base64 -w 128'):read('*all')..'}}}'
    s = tostring(s)
    if strfind(s, '\n') or (strlen(s) > lxt.cdata) then -- large text
        if fenc or strfind(s, ']]>') then -- enc flag or hostile strings
            local status, stdout, stderr = tun.popen(s, 'gzip -c | base64 -w 128')
            return '<!-- base64 -i -d | zcat -f -->{{{'..stdout..'}}}'
        else
            return (strfind(s, '&') or strfind(s, '<') or strfind(s, '>')) and '<![CDATA[\n'..s..']]>' or s
        end
    else -- escape characters
        return strgsub(strgsub(strgsub(strgsub(strgsub(s,
            '"', '&quot;'), "'", '&apos;'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
    end
end -- }}}
local function dumpLxt (node) -- {{{ xtm = {[0] = tag; ['@'] = attrOrder; ['*'] = txt; ...;}
    if not node[0] then return end
    local res = {}
    if node['@'] then
        for k in strgmatch(node['@'], '%S+') do tinsert(res, k..'="'..strgsub(node[k], '"', '\\"')..'"') end
    end
    res = '<'..node[0]..(#res > 0 and ' '..tconcat(res, ' ') or '')
    if #node == 0 then return res..' />' end
    if #node == 1 and type(node[1]) == 'string' then
        local s = lxt.xmlstr(node[1])
        if strfind(s, '\n') then s = '\n'..s..'\n' end -- CDATA
        return res..'>'..s..'</'..node[0]..'>'
    end
    res = {res..'>'}
    for i = 1, #node do tinsert(res, type(node[i]) == 'table' and dumpLxt(node[i]) or lxt.xmlstr(node[i])) end
    return strgsub(tconcat(res, '\n'), '\n', '\n'..lxt.indent)..'\n</'..node[0]..'>'
end -- }}}
lxt.Dump = function (docs, fxml) -- {{{ dump fxml=0/html, 1/xhtml
    if type(docs) ~= 'table' then return '' end
    if not fxml then return tun.dumpVar(0, docs) end
    local res = {}
    for _, doc in ipairs(docs) do tinsert(res, dumpLxt(doc)) end
    return (fxml == 1 and '' or '<?xml version="1.0" encoding="UTF-8"?>\n')..tconcat(res, '\n')
end -- }}}
-- ======================================================================== --
if arg and #arg > 0 and strgsub(arg[0], '^.*/', '') == 'lxt.lua' then -- service for checking object model -- {{{
    local xml = (arg[1] == '-' and io.stdin or io.open(arg[1], 'r')) or error('Error open '..arg[1])
    xml = lxt.Parse(xml:read('a'), 0)
    print(xml['?'][1] or lxt.Dump(xml))
end -- }}}

return lxt
--[[ {{{  MINI TUTORIAL https://matthewwild.co.uk/projects/luaexpat/manual.html
-- ======================================================================== --
-- LOM (Lua Object Model) : based on the standard LOM
-- ======================================================================== --
-- interesting technique of stack operation {{{
-- node == token == tag => table (stack operation)
local callbacks = {
    StartElement = function (parser, name, attr) -- {{{
        local node = parser:getcallbacks().node
        local elem = { tag = name }
        if next(attr) ~= nil then
            for i = 1, #attr do attr[i] = nil end -- free attr order info
            for k, v in pairs(attr) do elem['@'..attr] = v end
        end
        tinsert(node, elem)
    end; -- }}}

    EndElement = function (parser, name) -- {{{
        local node = parser:getcallbacks().node
        local elem = tremove(node)
        assert(elem.tag == name)
        tinsert(node[#node], elem)
    end; -- }}}

    CharacterData = function (parser, s) -- {{{
        if strmatch(s, '^%s*$') then return end -- NB: skip blank lines
        local node = parser:getcallbacks().node
        local elem = node[#node] -- top of the stack
        local n = #elem
        if type(elem[n]) == 'string' then
            elem[n] = elem[n]..s
        else
            tinsert(elem, s)
        end
    end; -- }}}
}

local function parse (o)
    local p = lxp.new(callbacks)
    callbacks.node = {{}} -- stack FILO/LIFO
    local status, msg, line, col
    if type(o) == 'string' then
        status, msg, line = p:parse(o)
        if not status then return nil, msg..' @line '..line  end
    else
        for i, v in ipairs(o) do
            status, msg, line = p:parse(v)
            if not status then
                return nil, msg..' @line '..line..' ('..i..')'
            end
        end
    end
    status, msg, line, col, pos = p:parse()
    if not status then return nil, msg..' @line '..line end
    p:close() -- seems destroy the lxp obj
    return callbacks.node[1][1]
end -- }}}

lxp.new(callbacks [, separator])
    The optional separator character in the parser constructor defines the character used
    in the namespace expanded element names.  The separator character is optional (if not
    defined the parser will not handle namespaces) but if defined it must be different from
    the character '\0'.

-- ======================================================================== --
callbacks.StartNamespaceDecl = function(parser, namespaceName)
    Called when the parser detects an XML namespace declaration with namespaceName.
    Namespace declarations occur inside start tags, but the StartNamespaceDecl handler is
    called before the StartElement handler for each namespace declared in that start tag.

callbacks.EndNamespaceDecl = function(parser, namespaceName)
    Called when the parser detects the ending of an XML namespace with namespaceName.
    The handling of the End namespace is done after the handling of the End tag For the element
    the namespace is associated with.

-- ======================================================================== --
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

-- ======================================================================== --
callbacks.CharacterData = function(parser, string)
    Called when the parser recognizes an XML CDATA string.

callbacks.StartCdataSection = function(parser)
    Called when the parser detects the begining of an XML CDATA section.

callbacks.EndCdataSection = function(parser)
    Called when the parser detects the End of a CDATA section.

-- ======================================================================== --
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

-- ======================================================================== --
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

-- ======================================================================== --
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
-- ======================================================================== --
-- vim: ts=4 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
