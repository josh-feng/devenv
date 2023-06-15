" File:        fml.vim
" Description: Reduced Markup Language
" Author:      Josh Feng <joshfwisc@gmail.com>
" Licence:     Vim licence
" Website:     http://josh-feng.github.com/pool/
" Version:     1.00
" Version: 1.00
" change log: {{{
"   fml     := '#fml' [hspace+ [attr1]]* [vspace hspace* [assign | comment]]*
"   hspace  := ' ' | '\t'
"   vspace  := '\r'
"   space   := hspace | vspace
"   comment := '#' [pdata] [hspace | ndata]* '\r'
"   assign  := [id] [prop1* | prop2] ':' [hspace+ [comment] [pdata | sdata]] [space+ (ndata | comment)]*
"   prop1   := '|' [attr0 | attr1]
"   prop2   := '|{' [comment+ [attr0 | attr2 ]]* vspace+ '}'
"   attr0   := [&|*] id
"   attr1   := id '=' ndata
"   attr2   := id hspace* '=' (hspace+ | comment) [pdata | sdata]
"   ndata   := [^space]+
"   sdata   := ['|"] .* ['|"]
"   pdata   := '<' [id] '[' id ']' .- '[' id ']>'
"}}}

" quit when a syntax file was already loaded {{{
if exists("b:current_syntax") | finish | endif

scriptencoding utf-8

let s:cpo_save = &cpo
set cpo&vim

syn case match

"syn sync minlines=100
"}}}

" string
syn match   fmlSpecial  contained #\\[\\abfnrtvz'"]\|\\x[[:xdigit:]]\{2}\|\\[[:digit:]]\{,3}#
syn match   fmlSpecial  contained #\\[\\abfnrtv'"[\]]\|\\[[:digit:]]\{,3}#
syn region  fmlString   nextgroup=fmlComment
    \ start=+\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<='+ skip=+\\\\\|\\'+ end=+'\(\s\|$\)\@=+
    \ contains=fmlSpecial,@Spell
syn region  fmlString   nextgroup=fmlComment
    \ start=+\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<="+ skip=+\\\\\|\\"+ end=+"\(\s\|$\)\@=+
    \ contains=fmlSpecial,@Spell

" consume paste and string
syn match   fmlNormal   +\S*[:=]\s[^ #]+ nextgroup=fmlNormal,fmlTagLine,fmlTagProp,fmlComment
syn match   fmlError    contained containedin=fmlTagProp +[^ '"#]\S*+

" verbatim block
syn region  fmlPaste    matchgroup=fmlCDATA fold nextgroup=fmlComment,fmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<\z(\i*\)\[\z(\i*\)\]" end="\[\z2\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@fmlPasteHook

syn match   fmlAssign   +=+ contained containedin=fmlAttr,fmlAttrVal
syn match   fmlSep      +|+ contained containedin=fmlAttr,fmlTagLine,fmlTagName

" attribute
syn match   fmlAttr     contained containedin=fmlTagLine "|[^ |]*[^ |:]"hs=s+1 contains=fmlAssign,fmlSep
syn match   fmlAttrSet  contained containedin=fmlTagProp
    \ "\(^\||{\)\@<=\s*\(\*\|&\)\?\I\i*\(\s\|$\)\@=" nextgroup=fmlComment
syn match   fmlAttrVal  contained containedin=fmlTagProp contains=fmlAssign
    \ "\(^\||{\)\@<=\s*\(\*\|&\)\?\I\i*\s*=" nextgroup=fmlPaste,fmlString

" tag: see cindent
syn match   fmlTagLine  keepend +^\s*\(\(\i\||\)\S*\)\?:\(\s\|$\)\@=+
    \ contains=fmlAttr,fmlSep nextgroup=fmlString,fmlPaste,fmlNormal
syn region  fmlTagProp  keepend matchgroup=fmlTagName nextgroup=fmlString,fmlPaste,fmlNormal
    \ start="^\s*\(\i[^ |{]*\)\?|{\(\s\|$\)\@=" end="^\s*}:\(\s\|$\)\@="
    \ contains=ALLBUT,fmlTagLine,fmlTagProp

" comment
syn keyword fmlTodo     contained TODO FIXME XXX
syn match   fmlComment  keepend +\(^\|\s\)#.*$+ contains=fmlTodo,@Spell
syn region  fmlComment  matchgroup=fmlComment fold
    \ start="\(^\|\s\+\)#<\w*\[\z([^\]]*\)\]" end="#\[\z1\]>.*$"
    \ contains=fmlTodo,@Spell,@fmlPasteHook

" The default highlighting."{{{
" highlight Folded term=bold ctermbg=blue ctermfg=cyan guibg=grey guifg=blue

hi def link fmlTodo     Todo
hi def link fmlComment  Comment

hi def link fmlString   String
hi def link fmlCDATA    Folded

hi def link fmlAttr     Statement
hi def link fmlAttrSet  Statement
hi def link fmlAttrVal  Statement
hi def link fmlSep      Identifier
hi def link fmlAssign   Typedef

hi def link fmlTagName  Identifier
hi def link fmlTagLine  Identifier
hi def link fmlTagProp  NONE

hi def link fmlError    Error
"}}}
let &cpo = s:cpo_save
unlet s:cpo_save
let &cms = ' # %s'
let b:current_syntax = "fml"
" ------------------  paste hook ------------------"{{{
" execute 'syntax include @fmlPasteHook '.$VIMRUNTIME.'/syntax/'.s:paste.'.vim'
" syn include @fmlPasteHook   $VIMRUNTIME/syntax/lua.vim
unlet b:current_syntax
syn include @fmlPasteHookLua $VIMRUNTIME/syntax/lua.vim
syn region  fmlPaste    matchgroup=fmlCDATA nextgroup=fmlComment fold nextgroup=fmlComment,fmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<lua\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@fmlPasteHookLua

unlet b:current_syntax
syn include @fmlPasteHookTex $VIMRUNTIME/syntax/tex.vim
syn region  fmlPaste    matchgroup=fmlCDATA nextgroup=fmlComment fold nextgroup=fmlComment,fmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<tex\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@fmlPasteHookTex

unlet b:current_syntax
syn include @fmlPasteHookCpp $VIMRUNTIME/syntax/cpp.vim
syn region  fmlPaste    matchgroup=fmlCDATA nextgroup=fmlComment fold nextgroup=fmlComment,fmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<cpp\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@fmlPasteHookCpp

unlet b:current_syntax
syn include @fmlPasteHookSh $VIMRUNTIME/syntax/sh.vim
syn region  fmlPaste    matchgroup=fmlCDATA nextgroup=fmlComment fold nextgroup=fmlComment,fmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<\S*sh\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@fmlPasteHookSh

unlet b:current_syntax
syn include @fmlPasteHookMd $VIMRUNTIME/syntax/markdown.vim
syn region  fmlPaste    matchgroup=fmlCDATA nextgroup=fmlComment fold nextgroup=fmlComment,fmlError
    \ start="\(\(:\|=\)\s\+\(#[^\n]*\n\s*\)\?\)\@<=<md\[\z([^\]]*\)\]" end="\[\z1\]>\(\s\|$\)\@="
    \ extend contains=@Spell,@fmlPasteHookMd
" ------------------  paste hook ------------------"}}}
" vim:ts=4:sw=4:sts=4:et:foldenable:fdm=marker:fmr={{{,}}}:fdl=1:sbr=-->
