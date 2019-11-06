"=============================================================================
" File:        aide.vim (alternative ide)
" Author:      Josh Feng <jui-hsuan.feng@globalfoundries.com>
" Last Change: Sat Oct 26 21:12:34 EDT 2019
" Version:     0.01
" Description: Bookmarks
"              t:bookmarks
"              t:roopath <-- from bookmarks
"=============================================================================

scriptencoding utf-8

if exists('loaded_aide') || &cp | finish | endif
let loaded_aide = 1

" Initialize {{{ AIDE
if !exists('g:aide_wid') | let g:aide_wid = 24  | endif
if !exists('g:aide_inc') | let g:aide_inc = winwidth(0)*3/10 | endif
if !exists('g:aide_bms')
    let g:aide_bms = $HOME.'/.vimaide' " bookmarks file
endif
if !exists('g:aide_wig') | let g:aide_wig = "\..*\.swp" | endif " setlocal wildignore=".*.swp"
" }}}

function! s:AIDE(lastwn) " {{{
    if !exists(a:lastwn)
        if exists('t:aide_bn') && (bufwinnr(t:aide_bn) != -1)
            exec 'silent! '.bufwinnr(t:aide_bn).'wincmd q'
        endif
    else
        if exists('t:aide_bn') && (t:aide_bn != -1)
            exec 'silent! sp | silent! b'.t:aide_bn
        else
            let t:aide_bname = '__AIDE__'.tabpagenr()
            exec 'silent! new 't:aide_bname
            call s:InitAide()
        endif
    endif
endfunction
if exists(':AIDE') != 2
    command -nargs=? AIDE call <SID>AIDE('<args>')
endif " }}}

" if exists(':Tagbar') != 2
" exec 'vertical resize '.g:ide_width
" if match(g:ide_flags, '\Cl') != -1 | let b:ide_cd_cmd = 'lcd' | endif
" let b:ide_resize_cmd = 'exec ''vertical resize ''.g:ide_width'
" setlocal statusline=%!TagbarGenerateStatusline()
" let s:compare_typeinfo = {}
" let w:autoclose = a:autoclose
" if filereadable(glob('~/.vimide_mappings')) | source ~/.vimide_mappings | endif
" call confirm('IDE/Vim error. Please Enter :AIDE again and report this bug.', "&OK", 1)
" let bufname=escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ')
" let g:aide_bn = bufnr(bufname.'\>')
" tabpagenr()
"       call setline(line(".")+1, "")
"       call cursor(line(".")+1, col("."))
"   for i in g:NERDTreeBookmark.Bookmarks()
"       call setline(line(".")+1, i.str())
"       call cursor(line(".")+1, col("."))
"   endfor
"   return '.. (up a dir)'
"   let header = self.nerdtree.root.path.str({'format': 'UI', 'truncateTo': winwidth(0)})
"   call setline(line(".")+1, header)
"   call cursor(line(".")+1, col("."))
"       let treeParts = repeat('  ', a:depth - 1)
"           call add(toReturn, i)
"       let l:globList = globpath(l:pathSpec, a:pattern, !g:NERDTreeRespectWildIgnore, 1, 0)
"           call remove(l:globList, index(l:globList, l:file))
"       let bookmarkStrings = readfile(g:NERDTreeBookmarksFile)
"       let invalidBookmarksFound = 0
"       for i in bookmarkStrings
"       echo readfile('/home/jfeng/log.rml')
"   if foldlevel('.') == 0 | return | endif
"   let immediate_infoline = getline('.')
"   let infoline = s:RecursivelyConstructDirectives(line('.'))
"   strlen()
"       let name = substitute(infoline, '^[#\t ]*\([^=]*\)=.*', '\1', '')
"       let sort = (match(g:ide_flags, '\CS') != -1)
"       if line('.') == line('$')
"               if foldclosed('.') == -1
"       if !isdirectory(glob(home))
"           call confirm('"'.home.'" is not a valid directory.', "&OK", 1)
"       else
"           let cwd=getcwd()
"           let spaces=strpart('                                               ', 0, foldlev)
"           unlet b:files b:filecount b:dirs b:dircount
" set wildignore=*.o,*.obj
" filter
" " Create a scratch buffer with a list of files (full path names).
" " Argument is a specification like '*.c' to list *.c files (default is '*').
" " Can use '*.[ch]' to find *.c and *.h (see :help wildcard).
" " If command uses !, list includes matching files in all subdirectories.
" " If filespec contains a slash or backslash, the path in filespec is used;
" " otherwise, start searching in directory of current file.
" function! s:Listfiles(bang, filespec)
"   if a:filespec =~ '[/\\]'  " if contains path separator (slash or backslash)
"     let dir = fnamemodify(a:filespec, ':p:h')
"     let fnm = fnamemodify(a:filespec, ':p:t')
"   else
"     let dir = expand('%:p:h')  " directory of current file
"     let fnm = a:filespec
"   endif
"   if empty(fnm)
"     let fnm = '*'
"   endif
"   if !empty(a:bang)
"     let fnm = '**/' . fnm
"   endif
"   let files = filter(split(globpath(dir, fnm), '\n'), '!isdirectory(v:val)')
"   echo 'dir=' dir ' fnm=' fnm ' len(files)=' len(files)
"   if empty(files)
"     echo 'No matching files'
"     return
"   endif
"   new
"   setlocal buftype=nofile bufhidden=hide noswapfile
"   call append(line('$'), files)
"   1d  " delete initial empty line
"   " sort i  " sort, ignoring case
" endfunction
" command! -bang -nargs=? Listfiles call s:Listfiles('<bang>', '<args>')
" :Listfile /my/path/*.c    " list *.c in given path
" :let a = "aaaa\nxxxx"
" :echo matchstr(a, "..\n..")
" aa
" xx

" {{{ Help message
let s:aidehelp = [
    \ '" p: toggle help for keybindings',
    \ '" x/X: toggle aide window horizontal/vertical',
    \ '" ------------ in bookmarks ------------',
    \ '" P: echo bookmark file',
    \ '" a/A: add bookmark',
    \ '" d/D: delete bookmark',
    \ '" r/R: rename bookmark/change bookmark file',
    \ '" u/U: update from bookmakr file/update to bookmark file',
    \ '" s/S: sort ascend/descend',
    \ '" <CR>: change directory to the bookmark',
    \ '" -------- in files/directories --------',
    \ '" P: toggle hidden files',
    \ '" a/A: add file/directory',
    \ '" i/I: open file in a new window/tab and jump',
    \ '" o/O: open file in a new window/tab',
    \ '" d/D: remove file/directory',
    \ '" c/C: change directory/resume directory',
    \ '" u/U: toggle folding/update',
    \ '" s/S: sort ascend/descend',
    \ '" <CR>: open file in the current window/toggle folding',
    \ ]
" }}}
function! s:AideToggleHelp() " {{{
    setlocal modifiable
    let t:showhelp = t:showhelp ? 0 : 1
    silent! global/^"/delete
    silent! 0put =(t:showhelp ? s:aidehelp : s:aidehelp[0])
    setlocal nomodifiable
endfunction "}}}
function! s:AideFileCheck(path) " {{{
    for p in split(&wig, ',')
        if match(a:path, p.'$') >= 0 | return v:false | endif
    endfor
    return match(a:path, '^t') < 0
endfunction "}}}
function! s:AideGetPath(ind) " {{{ NB: pos is lost (arrow acount for 3 characters)
    let l:path = ''
    let l:ind = a:ind
    while l:ind > 0
        let l:ind -= 2
        if search('^'.repeat(' ', l:ind).'▼', 'bW') > 0
            let l:path = strpart(substitute(getline('.'), ' ->.*$', '/', ''), l:ind + 4).l:path
        endif
    endwhile
    return t:rootpath.l:path
endfunction "}}}
function! s:AideRemoveTree(ind) " {{{
    setlocal modifiable
    let l:indent = repeat(' ', a:ind)
    normal! j
    while match(getline('.'), l:indent) == 0
        delete
    endwhile
    normal! k
    setlocal nomodifiable
endfunction "}}}
function! s:AideTree(ind, path) " {{{
    let l:pos = getpos('.')
    let l:path = s:AideGetPath(a:ind - 2).substitute(substitute(a:path, ' ->.*$', '/', ''), ' ', '\\ ','g')
    let l:aidetree = filter(split(system('ls -'.t:hidden.'Fl '.l:path), '\n'), 's:AideFileCheck(v:val)')
    let l:aidetreedir = []
    let l:aidetreefile = []
    let l:indent = repeat(' ', a:ind)
    for lp in l:aidetree
        let l:p = substitute(lp, '\(\S\+\s\+\)\{8}', '', '')
        echo l:p
        if match(l:p, '/$') < 0
            call add(l:aidetreefile, l:indent .substitute(l:p, '\*$', '', ''))
        else
            call add(l:aidetreedir, l:indent.'▶ '.l:p)
        end
    endfor
    silent! call setpos('.', l:pos)
    if len(l:aidetreedir) > 0 | silent! put =l:aidetreedir | endif
    if len(l:aidetreefile) > 0 | silent! put =l:aidetreefile | endif
    unlet l:aidetreedir l:aidetreefile l:aidetree
    silent! global/^$/delete
    silent! call setpos('.', l:pos)
endfunction "}}}
function! s:AideToggleWinHight() " {{{
    let t:winhit = t:winhit ? 0 : 1
    exec 'silent! wincmd '.(t:winhit ? '_' : '=')
endfunction "}}}
function! s:AideToggleWinWidth() " {{{
    let t:winwid = t:winwid ? 0 : 1
    exec 'silent! '.g:aide_inc.'wincmd '.(t:winwid ? '>' : '<')
endfunction "}}}

function! s:AideOpenFile(mode) " {{{
endfunction "}}}

function! s:AideUpdateDir(...) " {{{
endfunction "}}}

function! s:AideOperation(...) " {{{ add/remove dir/file
endfunction "}}}

function! s:AideCRAction() " {{{
    let l:line = getline('.') " echo line('.').'-'.col('.')
    if match(l:line, '^>') == 0 " bookmark region
        if match(l:line, '^> [:alpha:]') == 0 " bookmark TODO
            echo 'bookmark'
        endif
    elseif match(l:line, '^\.\. up') == 0 " up-directory TODO
        echo 'updir'
    elseif match(l:line, '/$') >= 0 " directory
        setlocal modifiable
        if match(l:line, '▶ ') >= 0
            let l:ind = match(l:line, '▶ ')
            silent! substitute/▶/▼/
            silent! call s:AideTree(l:ind + 2, substitute(l:line, '^.*▶ ', '', ''))
        else
            let l:ind = match(l:line, '▼ ')
            setlocal modifiable
            silent! substitute/▼/▶/
            silent! call s:AideRemoveTree(l:ind + 2)
        endif
        setlocal nomodifiable
    elseif match(l:line, '^"') < 0 " file
        let l:pos = getpos('.')
        let l:file = substitute(substitute(substitute(l:line, '^\s*', '', ''), ' ->.*$', '/', ''), ' ', '\\ ','g')
        let l:file = s:AideGetPath(match(l:line, '\S')).l:file
        silent! call setpos('.', l:pos)
        exec 'silent! '.t:aide_lastwn.'wincmd w'
        exec 'silent! edit '.l:file
    endif
endfunction "}}}

function! s:AideUpdateBookmark(aide_bms) " {{{
    setlocal modifiable
    let t:aide_bms = a:aide_bms
    let t:aidebookmark = []
    silent! global/^>/delete
    let l:title =strpart(s:bookmarkbound, 0, strlen(s:bookmarkbound) - 3).'{{{ '
    silent! put =l:title
    if len(t:aidebookmark) > 0 | silent! put =t:aidebookmark | endif
    silent! put =s:bookmarkbound
    silent! foldclose
    unlet l:title
    " status t:aide_bms TODO
    setlocal nomodifiable
endfunction "}}}
let s:bookmarkbound ='> --- bookmark }}}'

function! s:AideUpdateRootPath(path) " {{{
    setlocal modifiable
    silent! 1
    silent! call search(s:bookmarkbound, 'W')
    let t:rootpath = a:path
    let l:title ='.. up ('.t:rootpath.')'
    silent! put =l:title
    unlet l:title
    silent! call s:AideTree(0, '')
    setlocal nomodifiable
endfunction "}}}

function! s:AideEnterBuffer() " {{{ Buffer Initialization
endfunction "}}}

function! s:InitAide() " {{{ Buffer Initialization
    let t:winwid = 0
    let t:winhit = 0

    let t:showhelp = 0
    silent! 0put =s:aidehelp[0]
    call s:AideUpdateBookmark(g:aide_bms)

    let t:hidden = '' " 'A'
    setlocal wig=s:wig
    call s:AideUpdateRootPath(getcwd().'/')

    setlocal filetype=aide
    setlocal nomodeline
    setlocal noreadonly " in case the "view" mode is used
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nolist
    setlocal nowrap
    setlocal winfixwidth
    setlocal textwidth=0
    setlocal nocursorcolumn
    setlocal nospell
    setlocal nonumber
    if exists('+relativenumber')
        setlocal norelativenumber
    endif

    setlocal statusline="[AIDE]"
    setlocal buflisted
    let t:aide_bn = bufnr('')
    if t:aide_bn == -1 | unlet t:aide_bn | endif
    setlocal nobuflisted
    setlocal cursorline

    " Syntax Stuff {{{
    syntax match aideArrow       '\(▶\|▼\)'
    syntax match aideTree        '^.*/$' contains=aideArrow
    syntax match aideUpdir       '^\.\..*$'
    syntax match aideDescription '^".\+'
    syntax match aideBookmark    '^>.\+'

    highlight def link aideDescription  Comment
    highlight def link aideBookmark     Identifier
    highlight def link aideTree         Include
    highlight def link aideUpdir        Statement
    highlight def link aideArrow        Statement
    "}}}
    " Key-Mappings {{{
    nnoremap <buffer> <silent> p          \|:call <SID>AideToggleHelp()<CR>
    nnoremap <buffer> <silent> x          \|:call <SID>AideToggleWinWidth()<CR>
    nnoremap <buffer> <silent> X          \|:call <SID>AideToggleWinHight()<CR>
    nnoremap <buffer> <silent> <Return>   \|:call <SID>AideCRAction()<CR>

    "nmap     <buffer> <silent> <LocalLeader>s <S-Return>
    "nmap     <buffer> <silent> <M-CR> <Return><C-W>p
    "nmap     <buffer> <silent> <LocalLeader>v <M-CR>
    "nmap     <buffer> <silent> <LocalLeader>o <C-Return>
    "nmap     <buffer> <silent> <LocalLeader><Up> <C-Up>
    "nmap     <buffer> <silent> <LocalLeader><Down> <C-Down>
    " exec 'nnoremap <buffer> <LocalLeader>'.k.'  \|:call <SID>Spawn('.k.')<CR>'

    nnoremap <buffer> <silent> <LocalLeader>T \|:call <SID>DoFoldOrOpenEntry('', 'tabe')<CR>
    nnoremap <buffer> <silent> <LocalLeader>S \|:call <SID>LoadAllSplit(0, line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>i :echo <SID>RecursivelyConstructDirectives(line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>I :echo IDE_GetFname(line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>l \|:call <SID>LoadAll(0, line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>L \|:call <SID>LoadAll(1, line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>w \|:call <SID>WipeAll(0, line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>W \|:call <SID>WipeAll(1, line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>W \|:call <SID>WipeAll(1, line('.'))<CR>
    nnoremap <buffer> <silent> <LocalLeader>g \|:call <SID>GrepAll(0, line('.'), "")<CR>
    nnoremap <buffer> <silent> <LocalLeader>G \|:call <SID>GrepAll(1, line('.'), "")<CR>
    nnoremap <buffer> <silent> <2-LeftMouse>   \|:call <SID>DoFoldOrOpenEntry('', 'e')<CR>
    nnoremap <buffer> <silent> <S-2-LeftMouse> \|:call <SID>DoFoldOrOpenEntry('', 'sp')<CR>
    nnoremap <buffer> <silent> <LocalLeader>c :call <SID>CreateEntriesFromDir(0)<CR>
    nnoremap <buffer> <silent> <M-2-LeftMouse> <M-CR>
    nnoremap <buffer> <silent> <S-LeftMouse>   <LeftMouse>
    nmap     <buffer> <silent> <C-2-LeftMouse> <C-Return>
    nnoremap <buffer> <silent> <C-LeftMouse>   <LeftMouse>
    nnoremap <buffer> <silent> <3-LeftMouse>  <Nop>
    nmap     <buffer> <silent> <RightMouse>   <space>
    nmap     <buffer> <silent> <2-RightMouse> <space>
    nmap     <buffer> <silent> <3-RightMouse> <space>
    nmap     <buffer> <silent> <4-RightMouse> <space>
    nnoremap <buffer> <silent> <space>  \|:silent exec 'vertical resize '.(winwidth('.') > g:ide_width?(g:ide_width):(winwidth('.') + g:ide_incre))\|:nohlsearch<CR>
    nnoremap <script> <Plug>IDEOnly :call <SID>DoIDEOnly()<CR>

    " The :help command stomps on the IDE Window.  Try to avoid that.
    " This is not perfect, but it is alot better than without the mappings.
    cnoremap <buffer> help let g:ide_doinghelp = 1<CR>:help
    " }}}
    " Autocommands {{{
    let l:bufname = bufname('')
    " exec 'au BufWipeout '.bufname.' au! * '.bufname
    " exec 'au BufWipeout '.bufname.' unlet g:aide_bn'
    " exec 'au BufWipeout '.bufname.' nunmap <C-W>o'
    " exec 'au BufWipeout '.bufname.' nunmap <C-W><C-O>'
    " " Autocommands to keep the window the specified size
    " exec 'au WinLeave '.bufname.' call s:DoEnsurePlacementSize_au()'
    exec 'au BufEnter '.t:aide_bn.' call s:AideEnterBuffer()'
    " au WinLeave * call s:RecordPrevBuffer_au()
    " }}}

    call s:AideEnterBuffer()
endfunction " }}}
finish
" vim: ts=8 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1:
