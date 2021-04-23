"============================================================
" vim-vue-md
" Modified from JamshedVesuna/vim-markdown-preview.git
"============================================================

" let g:vmp_script_path = resolve(expand('<sfile>:p:h'))

if exists('vue_md_load') || &cp | finish | endif
let vue_md_load = 1

let g:vim_vue_md_toggle = 0

if !exists("g:vim_vue_md_browser")
    let g:vim_vue_md_browser = 'Google Chrome'
endif

if !exists("g:vim_vue_md_pandoc")
  let g:vim_vue_md_pandoc = 1
endif

if !exists("g:vim_vue_md_use_xdg_open")
    let g:vim_vue_md_use_xdg_open = 1
endif

if !exists("g:vim_vue_md_hotkey")
    let g:vim_vue_md_hotkey='<C-p>'
endif

function! Vue_MD(global) " {{{
  let b:curr_file = expand('%:p')
  let l:vue_md_file = 'vue_md.html'
  if a:global == 1
      let l:vue_md_file = '/tmp/vue_md.html'
  endif

  if g:vim_vue_md_pandoc == 1
    echo 'pandoc --standalone "'.b:curr_file.'" > '.l:vue_md_file
    call system('pandoc --standalone "'.b:curr_file.'" > '.l:vue_md_file)
  else
    call system('markdown "'.b:curr_file.'" > '.l:vue_md_file)
  endif
  " if v:shell_error | echo 'Please install the necessary requirements' | endif

  let chrome_wid = system("xdotool search --name 'vue_md.html - ".g:vim_vue_md_browser."'")
  if !chrome_wid
    if g:vim_vue_md_use_xdg_open == 1
      call system('xdg-open '.l:vue_md_file.' 1>/dev/null 2>/dev/null &')
    else
      call system('see '.l:vue_md_file.' 1>/dev/null 2>/dev/null &')
    endif
  else
    let curr_wid = system('xdotool getwindowfocus')
    call system('xdotool windowmap '.chrome_wid)
    call system('xdotool windowactivate '.chrome_wid)
    call system("xdotool key 'ctrl+r'")
    call system('xdotool windowactivate '.curr_wid)
  endif

  " sleep 200m
  " call system('rm '.l:vue_md_file)
endfunction " }}}

if g:vim_vue_md_toggle == 0
  "Maps vim_vue_md_hotkey to Vue_MD()
  exec 'autocmd Filetype markdown,md map <buffer> '.g:vim_vue_md_hotkey.' :call Vue_MD(1)<CR>'
elseif g:vim_vue_md_toggle == 1
  "Display images - Maps vim_vue_md_hotkey to Vue_MD_Local() - saves the html file locally
  "and displays images in path
  exec 'autocmd Filetype markdown,md map <buffer> '.g:vim_vue_md_hotkey.' :call Vue_MD(0)<CR>'
elseif g:vim_vue_md_toggle == 2
  "Display images - Automatically call Vue_MD_Local() on buffer write
  autocmd BufWritePost *.markdown,*.md :call Vue_MD(0)
elseif g:vim_vue_md_toggle == 3
  "Automatically call Vue_MD() on buffer write
  autocmd BufWritePost *.markdown,*.md :call Vue_MD(1)
endif
" vim: ts=8 sw=4 sts=4 et foldenable fdm=marker fmr={{{,}}} fdl=1
