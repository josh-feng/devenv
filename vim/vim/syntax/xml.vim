"

" syn include @xmlCdataHook <sfile>
" or
" syntax include @JS $VIMRUNTIME/syntax/javascript.vim
" syntax region start=/\V<![CDATA[/ end=/\V]]>/ contains=@JS

" NB: hi def takes the first def
" hi def link xmlCdata String
hi def link xmlCdata None
source $VIMRUNTIME/syntax/xml.vim

" unlet b:current_syntax
" syntax include @CDATA_SVRF $HOME/.vim/syntax/calibre.vim
" syntax include @CDATA_SVRF $HOME/.vim/syntax/calibre.vim
" syntax cluster xmlCdataHook add=@CDATA_SVRF
" syntax include @CDATA_LUA  $HOME/.vim/syntax/tachyon.vim
" syntax cluster xmlCdataHook add=@CDATA_LUA

unlet b:current_syntax
syntax include @CDATA_SVRF $HOME/.vim/syntax/calibre.vim
syntax region xmlCdataSvrf start=/\V<SvrfCode><![CDATA[/ end=/\V]]>/ contains=@CDATA_SVRF keepend
syntax region xmlCdataSvrf start=/\V<SvrfCode>/ end=/\V<\/SvrfCode>/ contains=@CDATA_SVRF keepend
"syntax region xmlCdataSvrf start=/\V<![CDATA[\/\// end=/\V]]>/ contains=@CDATA_SVRF keepend
unlet b:current_syntax
syntax include @CDATA_LUA  $HOME/.vim/syntax/tachyon.vim
syntax region xmlCdataLua  start=/\V<LuaCode><![CDATA[/ end=/\V]]>/ contains=@CDATA_LUA keepend
syntax region xmlCdataLua  start=/\V<LuaCode>/ end=/\V<\/LuaCode>/ contains=@CDATA_LUA keepend
"syntax region xmlCdataLua  start=/\V<![CDATA[\-\-/ end=/\V]]>/ contains=@CDATA_LUA keepend

" commentstring
setlocal cms=<!--%s-->
