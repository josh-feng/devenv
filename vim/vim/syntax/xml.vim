" syn include @xmlCdataHook <sfile>
" or
" syntax include @JS $VIMRUNTIME/syntax/javascript.vim
" syntax region start=/\V<![CDATA[/ end=/\V]]>/ contains=@JS

" NB: hi def takes the first def
" hi def link xmlCdata String
hi def link xmlCdata None
source $VIMRUNTIME/syntax/xml.vim

unlet b:current_syntax
syntax include @CDATA_TCL $VIMRUNTIME/syntax/tcl.vim
syntax region xmlCdataTcl start=/\V<TclCode><![CDATA[/ end=/\V]]>/ contains=@CDATA_TCL keepend
syntax region xmlCdataTcl start=/\V<TclCode>/ end=/\V<\/TclCode>/ contains=@CDATA_TCL keepend

unlet b:current_syntax
syntax include @CDATA_LUA  $VIMRUNTIME/syntax/lua.vim
syntax region xmlCdataLua  start=/\V<LuaCode><![CDATA[/ end=/\V]]>/ contains=@CDATA_LUA keepend
syntax region xmlCdataLua  start=/\V<LuaCode>/ end=/\V<\/LuaCode>/ contains=@CDATA_LUA keepend

" vim:ts=4:sw=4:sts=4:et:fdm=marker:fdl=1:sbr=-->
