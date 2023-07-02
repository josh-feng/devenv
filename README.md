# devenv

Here are some files for personal settings, probably not for public consumption.
It is not necessary to git clone the whole repository.
Just copy individual file to meet your need.

    ▼ images/
      vim-aide.png
    ▼ lua/
      ▼ lib/
        lom.lua
        util.lua
        XmlObject.lua
      ▼ lfm/
        lfm.lua
        lfp.lua
        fml.fml
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

# vim-aide project

This simple vim module create an IDE-like side panel, which supports `tagbar` module in the same panel if `tagbar` is installed:
- Copy the file vim/vim/plugin/**aide.vim** to your vim folder **~/.vim/plugin/**
- In vim, press `Leader` `Tab` to open the side window for vim-aide,
    where default `Leader` is ` \ `
- press `|` to switch between the current file and the side window
- press `_` to switch between the current file and the tagbar window

![vim-aide](images/vim-aide.png)

# Fake Markup Language (FML)


Several formats (xml, markdown, json, yaml, etc.) are not stable and/or have some limitations.
We will develop our own. The goal is to have a succinct format to break a text into usable fields.

    Syntax: FML works like punctutaions
        fml     := '#fml' [hspace+ [attr1]]* [vspace hspace* [assign | comment]]*
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


- `lfp.lua` basic parser
- `lfm.lua`
- `fml.fml`
- `fml.vim`

`lfp.lua` provide a basic/simple lua script to parse an FML file,
it can be coded to C/C++ lib for efficiency.
The file `lfm.lua`, using the parser `lfp.lua`, provides a sample lua object model builder for FML files.

# []()
<!--vim:ts=4:sw=4:sts=4:et:fdm=marker:fdl=1:sbr=-->
