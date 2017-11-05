" Vim syntax file
" Language:	Tachyon
" Maintainer:	Josh Feng <jui-hsuan.feng@globalfoundries.com>
" Last change:  Feb 5, 2013    
" Extensions:   *.job,*.lua
" Comment:      This file includes some functions and variables for LUA, and device
"               setup macros for OPC. LMC will be included in the future.
" Version:      0.1     initial implementation (Jan 25, 2013)
"               0.2     OPC recipe syntax (Feb 5, 2013)
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Read the lua syntax to start with
if version < 600
  so <sfile>:p:h/lua.vim
else
  runtime! syntax/lua.vim
  unlet b:current_syntax
endif

" =======================================================================
" Lua 5.2
syn match LUA52     "\<_ENV\>"                 " 

" =======================================================================
" Tachyon extentions
syn match JobMacro      "^\s*LUA\s\+BEGIN"
syn match JobMacro      "^\s*LUA\s\+END"
" syn match JobComment    "\#.*$"                 " 
syn match JobComment    "^\#.*$"                 " 
syn match DtVar		"DT\.\w*"               " variables and functions

" commentstring
set cms=\ --\ %s

" TODO LMC
" syn match DtLMC       "GEO.*" 

" TODO
" syn keyword TachyonKeyword and angle
" syn region  TachyonBlockComment start="/\*" end="\*/"
" syn match DtTable "[^//].*{"he=e-1
" syn match DtString /"[^"]*"/hs=s+1,he=e-1
" syn match DtString /"[^"]*"/

" SynColor MarkUpTag term=reverse cterm=NONE ctermfg=White ctermbg=cyan gui=NONE guifg=White guibg=cyan
hi def MarkUpTag term=reverse cterm=NONE ctermfg=Black ctermbg=cyan gui=NONE guifg=Black guibg=cyan

" =======================================================================
" Default highlighting
if version >= 508 || !exists("did_tachyon_syntax_inits")
  if version < 508
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink DtVar		Identifier
  HiLink JobMacro       MarkUpTag
  HiLink JobComment     Comment
  HiLink LUA52          Identifier
  " Statement Repeat String String Number Float Operator Constant Conditional Function Comment Todo Structure Error SpecialChar Identifier
  delcommand HiLink
endif

let b:current_syntax = "tachyon"

" vim: ts=8
