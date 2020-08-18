# devenv

Personal settings, probably not for public consumption.\
It is not necessary to git clone the whole repository.
Just copy individual file to meet your need.

    ▼ images/
      vim-aide.png
    ▼ lua/
      ▼ lib/
        lom.lua
        lxt.lua
        util.lua
        XmlObject.lua
      ▼ lrm/
        lrm.lua
        lrp.cpp
        lrp.hpp
        lrps.lua
        rml.rml
    ▼ vim/
      ▼ vim/
        ▼ autoload/
        ▼ doc/
        ▼ plugin/
          aide.vim
        ▼ syntax/
          xml.vim
      vimrc
      vimrc.local
    README.md
    tmux.conf

## vim-aide project

This simple vim module create an IDE-like side panel, which supports `tagbar` module in the same panel if `tagbar` is installed:
- Copy the file vim/vim/plugin/**aide.vim** to your vim folder **~/.vim/plugin/**
- In vim, press `Leader` `Tab` to open the side window for vim-aide,
    where default `Leader` is '\' 
- press `|` to switch between the current file and the side window
- press `_` to switch between the current file and the tagbar window

![vim-aide](images/vim-aide.png)

## Reduced Markup Language (RML)

- lrps.lua
- lrm.lua
- rml.rml
- rml.vim

Several formats (xml, markdown, json, yaml, etc.) are not stable and/or have some limitations.
We will develop our own. The goal is to have a succinct format to break a text into usable fields.

    Syntax: RML works like punctutaions
        rml     := '#rml' [hspace+ [attr1]]* [vspace hspace* [assign | comment]]*
        hspace  := ' ' | '\t'
        vspace  := '\r'
        space   := hspace | vspace
        comment := '#' [pdata] [hspace | ndata]* '\r'
        assign  := [id] [prop1* | prop2] ':' [hspace+ [comment] [pdata | sdata]] [space+ (ndata | comment)]*
        prop1   := '|' [attr0 | attr1]
        prop2   := '|{' [comment+ [attr0 | attr2 ]]* vspace+ '}'
        attr0   := [&|*] id
        attr1   := id '=' ndata
        attr2   := id hspace* '=' (hspace+ | comment) [pdata | sdata]
        ndata   := [^space]+
        sdata   := ['|"] .* ['|"]
        pdata   := '<' [id] '[' id ']' .- '[' id ']>'

lrps.lua provide a basic/simple lua script to parse an RML file,
it can be coded to C/C++ lib for efficiency. In fact, lrp.so will be the C-module parser.
With lrps.lua or lrp.so, the script lrm.lua provide a sample lua object model builder for RML file

## lua

### Requirement

- lxp
- posix
- pool

### Lua XML Table (LXT)

lxt.lua provide a simple x/html parser to LXT format.

**Example.1**

    lxt = require('lxt')
    lxt.ParseXml('file.xhtml', 0)
    lxt.ParseXml('file.xhtml', 1) -- clean end space
    lxt.ParseXml('file.xhtml', 2) -- clean space @ both ends
    lxt.ParseXml('file.html', 3)
    lxt.ParseXml('file.html', 4)  -- clean end space
    lxt.ParseXml('file.html', 5)  -- clean space @ both ends
