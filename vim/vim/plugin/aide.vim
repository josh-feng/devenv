" File:        aide.vim (alternative ide)
" Author:      Josh Feng <joshfwisc@gmail.com>
" Last Change: Fri 07 Aug 2020 01:40:23 AM EDT
" Version:     1.00 (need mac/m$ env test
" Description: An IDE supporting Tagbar
" Development: Bookmarks (t:aide_bms/t:bookmarks/t:roopath )
"              desc/0 bookmark/1 updir/2 close_dir/3 open_dir/4 file/5

scriptencoding utf-8

if exists('loaded_aide') || &cp | finish | endif
let loaded_aide = 1

" Initialize {{{ AIDE
if exists('g:aide_force') && g:aide_force == 1
    autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | call ToggleAide() | endif
endif
if !exists('g:aide_bms') | let g:aide_bms = $HOME.'/.vimaide' | endif " bookmarks file
if !exists('g:aide_bmafld') | let g:aide_bmafld = 0 | endif " bookmarks auto-folding
if !exists('g:aide_wig') | let g:aide_wig = 'CVS/*,*\\~,.*.swp' | endif
" }}}

" {{{ Help message
let s:aidehelp = [
    \ '" p: toggle help for keybindings',
    \ '" P: toggle hidden files',
    \ '" x/X: toggle aide window horizontal/vertical',
    \ '" ------------ in bookmarks ------------',
    \ '" u/U: update from bookmark file/update to bookmark file',
    \ '" d/D: delete bookmark',
    \ '" a/A: add bookmark',
    \ '" o/O: open bookmark in a new tab/jump',
    \ '" r/R: rename bookmark/change bookmark file',
    \ '" s/S: toggle sort name/path',
    \ '" <CR>: change directory to the bookmark',
    \ '" -------- in files/directories --------',
    \ '" u/U: toggle folding/update',
    \ '" d/D: display/query file/directory abs path and save to register',
    \ '" a/A: open file in a new vertical split window/jump',
    \ '" o/O: open file in a new tab/jump',
    \ '" r/R: open the file in the previous window/jump',
    \ '" i/I: open file in a new window/jump',
    \ '" c/C: change root directory/create the directory as bookmark',
    \ '" <CR>: open file in the main window/toggle folding',
    \ ]
" }}}
function! s:AideToggleHelp() " {{{
    setlocal modifiable
    let t:showhelp = t:showhelp ? 0 : 1
    silent! global/^"/delete
    silent! 0put =(t:showhelp ? s:aidehelp : s:aidehelp[0])
    setlocal nomodifiable
endfunction "}}}
function! s:AideZone(line) " {{{ desc/0 bookmark/1 updir/2 close_dir/3 open_dir/4 file/5
    if match(a:line, '^"') == 0 | return 0 | endif " description
    if match(a:line, '^>') == 0 | return 1 | endif " bookmark
    if match(a:line, '^\.\. up') == 0 | return 2 | endif " up-directory
    if match(a:line, '/$') >= 0 | return match(a:line, '▶ ') >= 0 ? 3 : 4 | endif " directory
    return 5
endfunction "}}}
function! s:AideFileCheck(path) " {{{
    for p in split(&wig, ',')
        if match(a:path, p.'$') >= 0 | return v:false | endif
    endfor
    return match(a:path, '^t') < 0
endfunction "}}}
function! s:AideGetAbsPath(line, patstart) " {{{ NB: pos is lost (arrow acount for 3 characters)
    let l:pos = getpos('.')
    let l:path = ''
    let l:ind = match(a:line, '\S')
    while l:ind > 0
        let l:ind -= 2
        if search('^'.repeat(' ', l:ind).'▼', 'bW') > 0
            let l:path = strpart(substitute(getline('.'), ' ->.*$', '', ''), l:ind + 4).l:path
        endif
    endwhile
    call setpos('.', l:pos)
    let l:line = substitute(substitute(a:line, a:patstart, '', ''), ' ->.*$', '', '')
    return substitute(t:rootpath.l:path.l:line, ' ', '\\ ','g')
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
function! s:AideTree() " {{{
    let l:pos = getpos('.')
    let l:line = getline('.')
    let l:path = s:AideGetAbsPath(l:line, '^.*\(▼\|▶\) ')
    let l:tree = filter(split(system('ls -'.(t:hid == 1 ? 'A' : '').'Fl '.l:path), '\n'), 's:AideFileCheck(v:val)')
    let l:treedir = []
    let l:treefile = []
    let l:ind = match(l:line, '\S')
    let l:indent = repeat(' ', (l:ind < 0) ? -2 : (l:ind + 2))
    for lp in l:tree
        let l:p = substitute(lp, '\(\S\+\s\+\)\{8}', '', '')
        echo l:p
        if match(l:p, '/$') < 0
            call add(l:treefile, l:indent .substitute(l:p, '\*$', '', ''))
        else
            call add(l:treedir, l:indent.'▶ '.l:p)
        end
    endfor
    silent! call setpos('.', l:pos)
    if len(l:treedir) > 0 | silent! put =l:treedir | endif
    if len(l:treefile) > 0 | silent! put =l:treefile | endif
    unlet l:treedir l:treefile l:tree
    silent! global/^$/delete
    silent! call setpos('.', l:pos)
endfunction "}}}
function! s:AideUpdateRootPath(path) " {{{
    setlocal modifiable
    silent! global/^\.\. up/delete
    silent! 1
    silent! call search(s:bookmarkbound, 'W')
    silent! put =a:path
    silent! ,$delete
    let t:rootpath = a:path
    let l:title = ['.. up ('.t:rootpath.')', '']
    silent! put =l:title
    unlet l:title
    silent! call s:AideTree()
    normal! k
    setlocal nomodifiable
endfunction "}}}
function! s:AideAddBookmark(path) " {{{
    if strlen(a:path) > 0
        let l:title = input("bookmark(".a:path.") title? ")
        let l:path = a:path
    else
        let l:line = input("bookmark title|/path/to/folder? ")
        let l:title = matchstr(l:line, "^[^|]*")
        let l:path = substitute(l:line, "^[^|]*|\s?", "", "")
    endif
    if strlen(l:title) > 0 && strlen(l:path) > 0
        call add(t:aidebookmark, '> '.l:title.'| '.l:path)
        call s:AideUpdateBookmark('')
    endif
endfunction " }}}
" KEYs: {{{
function! s:AideUpdate(case) " {{{ u/U
    let l:line = getline('.')
    let l:z = s:AideZone(l:line)
    if l:z == 1
        if a:case == 0 " from bms
            call s:AideUpdateBookmark(t:aide_bms)
        else " to bms
            if strlen(t:aide_bms) > 0 && 1 == confirm("Overwrite ".t:aide_bms."?", "&Yes\n&No", 1)
                call writefile(t:aidebookmark, t:aide_bms)
            endif
        endif
    elseif l:z >= 3
        let l:ind = match(l:line, '\S')
        call search('^'.(l:ind > 0 ? repeat(' ', l:ind - 2).'▼' : '\.\.'), 'bW')
        if a:case == 1 " to refresh subfolder
            if l:ind > 0
                setlocal modifiable
                call s:AideRemoveTree(l:ind)
                " NB: nomofifiable by the above call
                setlocal modifiable
                silent! call s:AideTree()
                setlocal nomodifiable
            else
                call s:AideUpdateRootPath(t:rootpath)
            endif
        endif
    endif
endfunction " }}}
function! s:AideAdd(case) " {{{ a/A
    let l:line = getline('.')
    let l:z = s:AideZone(l:line)
    if l:z == 1
        call s:AideAddBookmark('')
    elseif l:z == 5 " vertical in last wn
        let l:line = getline('.')
        if s:AideZone(l:line) != 5 | return | endif
        let l:path = s:AideGetAbsPath(l:line, '^\s*')
        exec t:aide_lastwn.'wincmd w | vnew '.l:path
        if a:case == 0 | exec 'silent! '.bufwinnr(t:aide_bn).'wincmd w' | endif " jump back
    endif
endfunction " }}}
function! s:AideDelete(case) " {{{ d/D
    let l:line = getline('.')
    let l:z = s:AideZone(l:line)
    if l:z == 1
        silent! call remove(t:aidebookmark, index(t:aidebookmark, l:line))
        call s:AideUpdateBookmark('')
    elseif l:z >= 3
        let l:path = s:AideGetAbsPath(l:line, l:z == 5 ? '^\s*' : '^.*\(▼\|▶\) ')
        if a:case == 1 && l:z == 5
            call system('file '.l:path)
        else
            let @"=l:path
            echo l:path
        end
    endif
endfunction " }}}
function! s:AideOpenTab(case) " {{{ o/O
    let l:line = getline('.')
    let l:z = s:AideZone(l:line)
    if l:z == 1 && match(l:line, '|') > 0 " bookmark
        let l:rootpath = substitute(l:line, '.*| ', '', '')
        let l:aidebookmark = t:aidebookmark
        set lazyredraw
        exec 'silent! tabnew'
        let t:rootpath = l:rootpath
        let t:aidebookmark = deepcopy(l:aidebookmark)
        call ToggleAide()
        exec 'silent! file '.strpart(substitute(l:line, '|.*', '', ''), 2).'.'.tabpagenr()
        if a:case == 0 | silent! tabp | endif
        set nolazyredraw
    elseif l:z == 5 " file
        exec 'tabedit '.s:AideGetAbsPath(l:line, '^\s*')
        if a:case == 0 | silent! tabp | endif
    endif
endfunction " }}}
function! s:AideReplaceOrChange(case) " {{{ r/R
    let l:line = getline('.')
    let l:z = s:AideZone(l:line)
    if l:z == 1
        if a:case == 0 " rename
            let l:i = index(t:aidebookmark, l:line))
            if l:i < 0 | return | endif
            let l:path = substitute(l:line, "^[^|]*|\s?", "", "")
            let l:title = input("bookmark title? ")
            let t:aidebookmark[l:i] = '> '.l:title.'| '.l:path
            call s:AideUpdateBookmark('')
        else " R load bookmark
            let l:line = getline('.')
            if s:AideZone(l:line) != 1 | return | endif
            let l:line = input("bookmark file? ")
            call s:AideUpdateBookmark(l:line)
        endif
    elseif l:z == 5
        let l:path = s:AideGetAbsPath(l:line, '^\s*')
        exec 'silent! '.t:aide_lastwn.'wincmd w'
        exec 'edit '.l:path
        if a:case == 0 | exec 'silent! '.bufwinnr(t:aide_bn).'wincmd w' | endif " jump back
    endif
endfunction " }}}
" ---------- specific zones ---------------
function! s:AideBookmarkSortCompare(x, y) " {{{
    let l:x = substitute(a:x, '.*: ', '', '')
    let l:y = substitute(a:y, '.*: ', '', '')
    return (l:x == l:y) ? 0 : (l:x > l:y) ? -1 : 1
endfunction " }}}
function! s:AideBookmarkSort(case) " {{{ s/S
    let l:line = getline('.')
    if s:AideZone(l:line) != 1 | return | endif
    if a:case == 0
        call sort(t:aidebookmark)
    else " sort path
        call sort(t:aidebookmark, "s:AideBookmarkSortCompare")
    endif
    call s:AideUpdateBookmark('')
endfunction " }}}
function! s:AideOpenFile(case) " {{{ i/I
    let l:line = getline('.')
    if s:AideZone(l:line) != 5 | return | endif
    let l:path = s:AideGetAbsPath(l:line, '^\s*')
    exec t:aide_lastwn.'wincmd w | new '.l:path
    if a:case == 0 | exec 'silent! '.bufwinnr(t:aide_bn).'wincmd w' | endif " jump back
endfunction " }}}
function! s:AideTreeRootPathBookmark(case) " {{{ c/C
    let l:line = getline('.')
    let l:z = s:AideZone(l:line)
    if l:z == 2 " .. up (/path/) -->
        let l:line = strpart(l:line, 7, strlen(l:line) - 8)
        if a:case == 0 " update rootpath exec 'chd '.l:line
            let @"=l:line
            exec 'cd '.l:line
        else
            call s:AideAddBookmark(l:line)
        endif
        return
    elseif l:z != 3 && l:z != 4
        return
    endif
    let l:path = s:AideGetAbsPath(l:line, '^.*\(▼\|▶\) ')
    if a:case == 0 " update rootpath
        call s:AideUpdateRootPath(l:path)
    else "a:case == 1 " new bookmark
        call s:AideAddBookmark(l:path)
    endif
endfunction " }}}
" }}}
function! s:AideCRAction() " {{{
    let l:line = getline('.') " echo line('.').'-'.col('.')
    let l:z = s:AideZone(l:line)
    if l:z == 1 " bookmark
        let l:i = match(l:line, '|')
        if l:i > 0
            exec 'file '.strpart(l:line, 2, l:i - 2).'.'.tabpagenr()
            call s:AideUpdateRootPath(substitute(l:line, '^.*| ', '', ''))
        endif
    elseif l:z == 2 " up-directory
        call s:AideUpdateRootPath(substitute(t:rootpath, '/[^/]*/$', '/', ''))
    elseif l:z == 5 " file
        let l:path = s:AideGetAbsPath(l:line, '^\s*')
        exec 'silent! '.t:aide_lastwn.'wincmd w'
        exec 'edit '.l:path
    elseif l:z > 0 " directory
        setlocal modifiable
        if l:z == 3
            silent! substitute/▶/▼/
            silent! call s:AideTree()
        else "l:z == 4
            let l:ind = match(l:line, '▼ ')
            silent! substitute/▼/▶/
            call s:AideRemoveTree(l:ind + 2)
        endif
        setlocal nomodifiable
    endif
endfunction "}}}
function! s:AideUpdateBookmark(bms) " {{{
    setlocal modifiable
    if strlen(a:bms) > 0
        let t:aide_bms = a:bms
        silent! let t:aidebookmark = readfile(t:aide_bms)
    elseif !exists('t:aidebookmark')
        silent! let t:aidebookmark = readfile(t:aide_bms)
    endif
    silent! global/^>/delete
    silent! $
    silent! call search('"', 'bW')
    let l:title =strpart(s:bookmarkbound, 0, strlen(s:bookmarkbound) - 3).'{{{ '
    silent! put =l:title
    call uniq(t:aidebookmark)
    if len(t:aidebookmark) > 0 | silent! put =t:aidebookmark | endif
    silent! put =s:bookmarkbound
    if g:aide_bmafld == 1
        silent! foldclose
    endif
    unlet l:title
    setlocal statusline=%{t:aide_bms}
    setlocal nomodifiable
endfunction "}}}
let s:bookmarkbound ='> ------ bookmark ------ }}}'
function! s:AideEnterBuffer() " {{{ Buffer Initialization TODO
    " let bufname=escape(substitute(expand('%:p', 0), '\\', '/', 'g'), ' ')
endfunction "}}}
function! s:InitAide() " {{{ Buffer Initialization
    let t:showhelp = 0
    silent! 0put =s:aidehelp[0]
    if !exists('t:aide_bms') | let t:aide_bms = g:aide_bms | endif
    call s:AideUpdateBookmark('')

    let t:hid = -1
    exec 'setlocal wig='.g:aide_wig
    call s:AideUpdateRootPath(t:rootpath)

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

    setlocal buflisted
    let t:aide_bn = bufnr('')
    if t:aide_bn == -1 | unlet t:aide_bn | endif
    setlocal nobuflisted
    setlocal cursorline
    setlocal fdm=marker fmr={{{,}}}

    " Syntax {{{
    syntax match aideArrow        '\(▶\|▼\)'
    syntax match aideTree         '^.*/$' contains=aideArrow
    syntax match aideKey          '\S\+:'he=e-1 contained containedin=aideDescription
    syntax match aideBookmarkName '> \S\+|'hs=s+2,he=e-1 contained containedin=aideBookmarkZone
    syntax match aideDescription  '^".*$' contains=aideKey
    syntax match aideBookmarkZone '^>.*$' contains=aideBookmarkName
    syntax match aideUpdir        '^\.\..*$'
    highlight def link aideDescription  Comment
    highlight def link aideBookmarkZone Statement
    highlight def link aideBookmarkName Identifier
    highlight def link aideTree         Identifier
    highlight def link aideUpdir        TODO
    highlight def link aideArrow        Statement
    highlight def link aideKey          Constant
    "}}}
    " Key-Mappings {{{
    nnoremap <buffer> <silent> p  \|:call <SID>AideToggleHelp()<CR>
    nnoremap <buffer> <silent> P  \|:sil! let t:hid = -t:hid\|:call <SID>AideUpdateRootPath(t:rootpath)<CR>
    nnoremap <buffer> <silent> x  \|:sil! exec 'vert res '.(winwidth('.')<g:aide_mx?(g:aide_mx):(g:aide_wid))<CR>
    " exec 'silent! '.g:aide_inc.'wincmd '.(t:winwid ? '>' : '<')
    nnoremap <buffer> <silent> X  \|:sil! exec 'wincmd '.(winheight('.')>g:aide_h2?'=':'_')<CR>
    " zones
    nnoremap <buffer> <silent> u  \|:call <SID>AideUpdate(0)<CR>
    nnoremap <buffer> <silent> U  \|:call <SID>AideUpdate(1)<CR>
    nnoremap <buffer> <silent> a  \|:call <SID>AideAdd(0)<CR>
    nnoremap <buffer> <silent> A  \|:call <SID>AideAdd(1)<CR>
    nnoremap <buffer> <silent> d  \|:call <SID>AideDelete(0)<CR>
    nnoremap <buffer> <silent> D  \|:call <SID>AideDelete(1)<CR>
    nnoremap <buffer> <silent> o  \|:call <SID>AideOpenTab(0)<CR>
    nnoremap <buffer> <silent> O  \|:call <SID>AideOpenTab(1)<CR>
    nnoremap <buffer> <silent> r  \|:call <SID>AideReplaceOrChange(0)<CR>
    nnoremap <buffer> <silent> R  \|:call <SID>AideReplaceOrChange(1)<CR>
    " bookmark-part (zone 1)
    nnoremap <buffer> <silent> s  \|:call <SID>AideBookmarkSort(0)<CR>
    nnoremap <buffer> <silent> S  \|:call <SID>AideBookmarkSort(1)<CR>
    " tree-part (zone 3 4 5)
    nnoremap <buffer> <silent> i  \|:call <SID>AideOpenFile(0)<CR>
    nnoremap <buffer> <silent> I  \|:call <SID>AideOpenFile(1)<CR>
    nnoremap <buffer> <silent> c  \|:call <SID>AideTreeRootPathBookmark(0)<CR>
    nnoremap <buffer> <silent> C  \|:call <SID>AideTreeRootPathBookmark(1)<CR>
    "
    nnoremap <buffer> <silent> <Return>   \|:call <SID>AideCRAction()<CR>
    if exists(':Tagbar') == 2
        nnoremap <silent> _ :call SwitchAide(bufnr(t:tagbar_buf_name))<CR>
    endif
    " }}}
    " Autocommands {{{
    exec 'au BufWipeout '.bufname('').' unlet t:aide_bn t:aide_bms t:aidebookmark'
    exec 'au BufEnter '.t:aide_bn.' call s:AideEnterBuffer()'
    " }}}

    call s:AideEnterBuffer()
endfunction " }}}
function! s:AIDE(lastwn) " {{{
    if !exists(a:lastwn)
        if exists(':Tagbar') == 2
            TagbarClose
        endif
        if exists('t:aide_bn') && (bufwinnr(t:aide_bn) != -1)
            exec 'silent! '.bufwinnr(t:aide_bn).'wincmd q'
        endif
    else
        if exists(':Tagbar') == 2
            let g:aide_wid = g:tagbar_width
            TagbarOpen 'f'
            silent! new
        else
            if !exists('g:aide_wid') | let g:aide_wid = 24 | endif
            silent! vnew
        endif
        if exists('t:aide_bn') && (t:aide_bn != -1)
            exec 'silent! b'.t:aide_bn
        else
            let t:aide_bname = '__AIDE__'.tabpagenr()
            silent! edit
            " change buf name
            exec 'silent! file '.t:aide_bname
            if !exists('t:rootpath') | let t:rootpath = getcwd().'/' | endif " default
            call s:InitAide()
        endif
        exec 'cd '.t:rootpath
    endif
endfunction " }}}

function! ToggleAide() " {{{
    set lazyredraw
    if !exists('t:aide_bn') || (bufwinnr(t:aide_bn) == -1)
        let t:aide_lastwn = winnr()
        AIDE t:aide_lastwn
    else
        AIDE
    endif
    set nolazyredraw
endfunction " }}}
function! SwitchAide(b) " {{{
    let l:ssb = bufnr('')
    if l:ssb == a:b
        exec 'silent! '.t:aide_lastwn.'wincmd w'
    elseif exists('t:aide_bn')
        if l:ssb != t:aide_bn && (exists(':Tagbar') != 2 || l:ssb != bufnr(t:tagbar_buf_name))
            let t:aide_lastwn = winnr()
        endif
        if bufwinnr(t:aide_bn) == -1 | call ToggleAide() | endif
        exec 'silent! '.bufwinnr(a:b).'wincmd w'
    endif
    unlet l:ssb
endfunction " }}}
" <Bar> == |
nnoremap <silent> <Bar> :call SwitchAide(t:aide_bn)<CR>
nnoremap <silent> <Leader><Tab> :call ToggleAide()<CR>

if exists(':AIDE') != 2
    command -nargs=? AIDE call <SID>AIDE('<args>')
    if !exists('g:aide_mx') | let g:aide_mx = winwidth(0)*6/10 | endif
    if !exists('g:aide_h2') | let g:aide_h2 = winheight(0)/2 | endif
endif
finish
" vim: ts=8 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
