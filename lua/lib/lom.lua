#!/usr/bin/env lua5.1
-- ======================================================================== --
-- Lua Object Model
-- Usage example:
--      lom = require('lom')
--      doc = lom.ParseXml(file)
--      print(doc.Flow.LayoutWriter[1]['@name'])
--      target = lom.Collect(doc, 'E1Target')
--      boolean = lom.Collect(doc, 'Map', 1)
--      xml = lom.Dump(doc, true)
--      subxml = lom.Dump(doc.Flow.LayoutWriter, 'TestTag')
-- ======================================================================== --
local lom = {cvs_id = '$Id: $'}

local lxp = require('lxp') -- the standard Lua Expat module
local tun = require('util')

local next, assert, type = next, assert, type
local strlen, strsub, strmatch, strgmatch = string.len, string.sub, string.match, string.gmatch
local strrep, strgsub, strfind = string.rep, string.gsub, string.find
local tinsert, tremove = table.insert, table.remove

local indent = strrep(' ', 2)
-- ======================================================================== --
-- LOM (Lua Object Model)
-- ======================================================================== --
-- node == token == tag == table {{{
local node -- working variable: doc == root node
local trim -- trim the leading and tailing space of data 0:end space, 1:blank line

local lomcallbacks = {
    StartElement = function (parser, name, attr) -- {{{
        local t = {['.'] = node} -- record parent node
        tinsert(node, t)
        for k, v in pairs(attr) do -- free attr info {{{
            if type(k) == 'string' then t['@'..k] = v end
            attr[k] = nil
        end -- }}}
        local subnode = node[name] -- {{{ build up the tag links
        if not subnode then node[name] = {t} else tinsert(subnode, t) end -- }}}
        node = t
    end; -- }}}
    EndElement = function (parser, name) -- {{{
        node, node['.'] =  node['.'], name -- record the tag/node name
    end; -- }}}
    CharacterData = function (parser, s) -- {{{
        if trim ~= 1 or strmatch(s, '%S') then
            tinsert(node, trim and strmatch(s, '^(.-)%s*$') or s)
        end
    end; -- }}}
}

local function parselom (o, mode)
    node = {} -- initialize the local root
    trim = mode
    local plom = lxp.new(lomcallbacks)
    local status, msg, line, col, pos = plom:parse(o) -- passed nil if failed
    plom:parse()
    plom:close() -- seems destroy the lxp obj
    node['?'] = status and {} or {msg..' @line '..line}
    return node
end
lom.Parse = parselom
-- }}}
-- ======================================================================== --
lom.ParseXml = function (filename, doctree, mode) -- doc = lom.ParseXml(xmlfile, docfactory) -- {{{
    filename = tun.normpath(filename)
    if type(doctree) == 'table' and doctree[filename] then return doctree[filename] end

    local file, msg = io.open(filename, 'r')
    if not file then return {['?'] = {msg}} end
    local doc = lom.Parse(file:read('*all'), mode)
    file:close()

    if type(doctree) == 'table' then doctree[filename] = doc end
    return doc
end -- }}}

lom.XmlBuild = function (xmlfile, mode) -- topxml, doctree = lom.XmlBuild(rootfile) -- {{{ -- trace and meta
    local topxml, base = tun.normpath(xmlfile)
    local doctree = {}
    local doc = lom.ParseXml(topxml, doctree, mode)

    local function TraceTbl (t, xml) -- {{{ lua table form
        for k, v in pairs(t) do
            if k == '@xlink:href' then -- attr

                local link, xpath = strmatch(v, '^([^#]*)(.*)') -- {{{ file_link, tag_path
                if link == '' then -- back to this doc root
                    link = xml
                else -- new file
                    if strsub(link, 1, 1) ~= '/' then link = strgsub(xml, '[^/]*$', '')..link end
                    link = tun.normpath(link)
                end -- }}}

                if not doctree[link] then TraceTbl(lom.ParseXml(link, doctree, mode), link) end
                link, xpath = lom.xPath(doctree[link], strmatch(xpath or '', '#xpointer%((.*)%)'))

                if link then -- the linked table
                    local meta = link
                    repeat -- loop detect {{{
                        meta = getmetatable(meta) and getmetatable(meta).__index
                        if meta == t then break end
                    until not meta -- }}}
                    if meta then
                        tinsert(doctree[xml]['?'], 'loop '.. v) -- error message
                    elseif t ~= link then
                        setmetatable(t, {__index = link})
                    end
                else
                    tinsert(doctree[xml]['?'], 'broken '.. v..':'..xpath) -- error message
                end
            end
            if type(v) == 'table' then TraceTbl(v, xml) end -- continous override
        end
    end -- }}}

    if #doc['?'] == 0 then TraceTbl(doc, topxml) end -- no error msg
    return topxml, doctree
end -- }}}

local checkAttr = function(t, _) -- {{{ check attr
    for attr, val in strgmatch(strmatch(_, '%[(.*)%]') or '', '(@.*)=(.*)') do
        local q, qo = strmatch(val, '^([\'"])(.*)%1$')
        if t[attr] ~= qo then return false end
    end
    return true
end -- }}}

lom.xPath = function (t, path) -- {{{ return doc table, missingTag
    if (not path) or path == '' then return t end
    -- NB: xpointer does not have standard treatment -- TODO supporting other formats
    -- /A/B -- TODO
    -- A/B[@attr="val",@bb='4']
    if strsub(path, 1, 1) ~= '/' then
        for k, v in pairs(t) do
            -- if type(k) ~= 'number' and type(v) == 'table' then t = v ; break end
            if type(k) ~= 'number' then t = v ; break end
        end
    end
    for _ in strgmatch(path, '([^/]+)') do -- tag path {{{
        t = t[strmatch(_, '[^%[]+')]
        if not t then return t, _ end
        local found
        for i = 1, #t do -- first hit (TODO multiple hits)
            if checkAttr(t[i], _) then found = t[i] ; break end
        end
        if not found then return nil, _ end
        t = found
    end -- }}}
    return t
end -- }}}
-- ======================================================================== --
lom.Collect = function (t, key, code) -- {{{
    local force = code and ''
    local fuzzy = code and code == 1
    local collection = {}
    if type(t) == 'table' and key then
        local function collect (subtbl, title)
            for k, v in pairs(subtbl) do
                if (fuzzy and strmatch(k, key)) or k == key then
                    if title then
                        collection[title] = v
                        if type(v) == 'table' then
                            collect(v, title..'/'..k)
                        end
                    else
                        tinsert(collection, v) -- shield by the first
                    end
                elseif (type(v) == 'table') and (k ~= '/') then -- supernode
                    collect(v, title and title..'/'..k)
                end
            end
        end
        collect(t, force)
    end
    return collection
end -- }}}

lom.Pick = function (filename, key, code) -- {{{
end -- }}}
-- ======================================================================== --
-- Output
-- ======================================================================== --
local resTbl -- result string
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
            return (strfind(s, '"') or strfind(s, "'") or strfind(s, '&') or
                    strfind(s, '<') or strfind(s, '>')) and '<![CDATA[\n'..s..']]>' or s
        end
    else -- escape characters
        return strgsub(strgsub(strgsub(strgsub(strgsub(s,
            '"', '&quot;'),
            "'", '&apos;'),
            '&', '&amp;'),
            '<', '&lt;'),
            '>', '&gt;')
    end
end -- }}}
local function DumpLom (node, c) -- {{{ XML format -- lom to XML
    if node['.'] then -- {{{ start tag
        tinsert(resTbl, strrep(indent, c)..'<'..node['.'])
        for k, v in pairs(node) do -- {{{ attribute
            if strsub(k, 1, 1) == '@' then
                tinsert(resTbl, ' '..strsub(k, 2, -1)..'="'..v..'"')
            end
        end -- }}}
        tinsert(resTbl, #node > 0 and '>\n' or ' />\n')
    end -- }}}
    c = c + 1
    for k = 1, #node do -- {{{ data
        local t = node[k]
        if type(t) == 'table' then
            DumpLom(t, c)
        else
            tinsert(resTbl, strrep(indent, c)..xmlstr(t)..'\n')
        end
    end -- }}}
    if #node > 0 and node['.'] then tinsert(resTbl, strrep(indent, c - 1)..'</'..node['.']..'>\n') end -- end tag
end -- }}}
local function DumpTbl (t, c) -- {{{ lua table form -- raw table
    tinsert(resTbl, '{\n')
    c = c + 1
    for k, v in pairs(t) do -- {{{ tag and @ttribute fisrt and skip other (survey-ed) tags
        if k == '.' or strsub(k, 1, 1) == '@' then
            tinsert(resTbl, strrep(indent, c)..'["'..k..'"] = "'..v..'",\n')
        end
    end -- }}}
    for k = 1, #t do -- {{{ data
        local v = t[k]
        tinsert(resTbl, strrep(indent, c))
        if type(v) ~= 'table' then
            tinsert(resTbl, '"'..tostring(v)..'"')
        else -- if next(v) ~= nil then
            DumpTbl(v, c)
        end
        tinsert(resTbl, ',\n') -- tinsert(resTbl, (next(t, k) and ',' or '')..'\n')
    end -- }}}
    tinsert(resTbl, strrep(indent, c - 1)..'}')
end -- }}}

lom.Dump = function (doc, fxml) -- {{{ dump
    if type(doc) ~= 'table' then return '' end
    if fxml then
        resTbl = {
            '<?xml version="1.0"?>\n',
            -- '<?xml-stylesheet type="text/xsl" href="shared/keyword.xsl"?>\n'
        }
        DumpLom(doc, -1)
    else
        resTbl = {}
        DumpTbl(doc, 0)
    end
    return table.concat(resTbl)
end -- }}}

return lom
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
