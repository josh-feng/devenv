-- runtimepath
-- ~/.config/nvim/init.lua
--  after/
--  ftpplugin/
--  autoload/
--  lua/ --> included in runtimepath
--      myluamodule.lua
--      other_modules/
--          anothermodule.lua
--          init.lua
--  plugin/
--  syntax/
--  init.lua
--
--  1. vim-api: vim.cmd(), vim.fn() 2. nvim-api: vim.api 3. lua-api: vim.*
-- ====================  GLOBAL SETTINGS  ============================
-- ----- basic settings ----- {{{
-- set runtimepath=/usr/share/vim/@VIMCUR@,~/.vim
-- verbose set ai? cin? cink? cino? si? inde? indk?
-- setlocal nocindent indentexpr=
vim.opt.mouse = ''
vim.o.encoding = 'utf-8'
vim.o.fileencoding = 'utf-8' -- gbk,gb18030,big5,iso8859-1,default
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
-- disable realtime editing result
vim.o.icm = ''
vim.cmd('filetype plugin indent on')
vim.cmd('syntax enable')
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.showmode = true
-- vim.cmd('expandtab smartindent showmode on')

-- vim.cmd('nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>')
vim.keymap.set('n', '<Space>', ':nohlsearch<Bar>:echo<CR>', {silent = true})

if vim.o.clipboard ~= nil then vim.o.clipboard = 'unnamed' end

-- autocmd StdinReadPre * let s:std_in = 1
vim.api.nvim_create_autocmd({'StdinReadPre'}, {
    pattern = {'*'},
    command = 'let s:std_in = 1'
})

--  let &t_EI = "\<Esc>]12;red\x7" " use a red cursor otherwise
--  let &t_ve = "[34h[?25h"
--
--  word / filename under cursor <cfile> <cword>
--  variable 'isfname' is for filename setting
--  variable 'iskeyword' is for searching/selection
--  set iskeyword+=\.                 " include .
--  set iskeyword-=\.                 " disable it
--  set isk=@,48-57,_,128-167,224-235
--  set isk=@,48-57,_,192-255,#       " make
--  set isk=@,46-57,_,192-255         " make (include /)
--  set isk=@,48-57,_
--  set isk=a-z,A-Z,48-57,_,.,-,>     " C/C++
--
-- :e ++ff=dos
-- :w ++ff=unix
-- :set fileformat=unix to convert from dos to unix

-- ======================  VIM DIFF MODE  ============================
-- vimdiff/viewdiff mode {{{
-- do    get change form the other
-- dp    put change to the other
-- ]c    next diff
-- [c    prev diff
-- if &diff | set scrollbind | endif " }}}
if vim.o.diff then vim.o.scrollbind = true end

vim.cmd([[
function! RidSpace() " clean space {{{
    if &filetype == 'make'
        silent! exec '%s/\(^\)\@<!\t/    /g'
    else
        retab
    end
    silent! exec '%s/\s\+$//g'
    set foldlevel=0 foldenable
endfunction " }}}
fu! CustomFoldText() " custom fold display {{{
    let line1 = getline(v:foldstart)
    let lineCnt = line("$")
    let w = winwidth(0) - &foldcolumn - (&number ? (strwidth(printf("%d", lineCnt)) + 2) : 0)
    let fldCnt = 1 + v:foldend - v:foldstart
    let fldStr = printf(" %d+%d %.1f%%", fldCnt, v:foldlevel, (fldCnt * 1.0) / lineCnt * 100)
    let expStr = repeat(".", w - strwidth(line1.fldStr))
    return strpart(line1, 0, w - strwidth(expStr.fldStr)).expStr.fldStr
endf " }}}
]])
vim.o.foldtext = 'CustomFoldText()'

-- Spell {{{
-- [s    search back
-- ]s    search forth
-- zg    add word under cursor
-- set spell spelllang=en_us
vim.o.spellfile = '~/.vim/spell/en.utf-8.add'

-- set nospell
-- set spelllang=fr " en or fr
-- }}}
-- }}}

-- ----- color ----- {{{
vim.o.background = 'dark'   -- dark/light

-- hi CursorColumn cterm=NONE ctermbg=black ctermfg=green guibg=NONE guifg=NONE

if vim.o.t_Co == '256' then -- rxvt-unicode-256color
    vim.cmd('hi CursorLine   ctermbg=darkgrey')
    vim.cmd('hi Comment ctermfg=243 ctermbg=NONE guibg=NONE guifg=darkgrey')
else -- colorscheme evening
    vim.cmd('hi CursorLine   ctermbg=NONE')
    vim.cmd('hi Comment ctermfg=darkblue ctermbg=black guifg=gray gui=bold')
end
vim.cmd('hi Folded term=bold ctermbg=blue ctermfg=cyan guibg=grey guifg=blue')
vim.cmd('hi FoldColumn guibg=darkgrey guifg=white')

vim.cmd('au WinLeave * highlight StatusLine ctermfg=darkgrey')
vim.cmd('au WinEnter * highlight StatusLine ctermfg=green')
-- }}}

-- ----- binding ----- {{{
-- nmap ;; :split | terminal
vim.keymap.set('n', ';', ':!')
vim.keymap.set('n', '<Bslash><Bslash>', ':call RidSpace()<CR>', {silent = true})
vim.cmd([[let mapleader = ","]])
vim.cmd([[let maplocalleader = ","]])

vim.keymap.set('n', '<Leader>,', ':set wrap!<CR>', {silent = true})

-- TODO www/lynx/links2/gitbook: gx: xdg-open
vim.cmd([=[nmap <silent> w /\[[^\]]*\]([^)]*)<CR>]=])

-- nnoremap <F9> :set invpaste paste?<CR>
vim.o.pastetoggle = '<F9>'

vim.keymap.set('n', 't', '<C-w>')
vim.keymap.set('n', 'tm', ':vnew<CR>')
vim.keymap.set('n', 'Tc', ':tabnew<CR>', {silent = true})
vim.keymap.set('n', 'Tn', ':tabmove +1<CR>', {silent = true})
vim.keymap.set('n', 'Tp', ':tabmove -1<CR>', {silent = true})

-- <F2>-<F3> all filetype
-- map <F2> a<C-R>=strftime("%c")<CR><Esc>
-- map <F3> :let @@=expand('<cword>')<CR> " copy to "
-- map <F4> :let @+=expand('<cword>')<CR> " copy to selection
vim.keymap.set('n', '<F2>', ':set invcursorcolumn invcursorline wrap! nu!<CR>', {silent = true})
vim.keymap.set('n', '<F3>', ':set invcursorline rnu!<CR>', {silent = true})
vim.keymap.set('n', '<F4>', ':copen<CR><c-w>J', {silent = true}) -- quickfix

-- c-j generate 'NL'
vim.keymap.set('i', '<C-h>', '<c-o>h')
vim.keymap.set('i', '<C-j>', '<c-o>j')
vim.keymap.set('i', '<C-k>', '<c-o>k')
vim.keymap.set('i', '<C-l>', '<c-o>l')

vim.keymap.set('i', '<F2>', '<C-R>=strftime("%Y-%m%d")<CR>')
-- inoremap <F3>
vim.keymap.set('i', '<F4>', '<C-v>u')

-- Useful bubble text normal mapping for arrow keys.
-- vnoremap <DOWN>  xjP`[<C-V>`]
-- vnoremap <UP>    xkP`[<C-V>`]
-- vnoremap <LEFT>  xhP`[<C-V>`]
-- vnoremap <RIGHT> xlP`[<C-V>`]

-- vnoremap m :!cconv -f big5 -t utf8<CR>
-- vnoremap M :!cconv -f gb18030 -t utf8<CR>

vim.cmd([[vnoremap f :s/\(\S\)\s\+/\1:/g<CR>]])
vim.keymap.set('v', 'F', ':s/:/ /g<CR>')
vim.keymap.set('v', '`', ':w !sh<CR>')
vim.keymap.set('v', 't', '!column -t<CR>')
vim.keymap.set('v', 'o', ':!/usr/bin/nl -n rz<CR>')

vim.cmd([[vnoremap <silent> \ :s/\s\+$//g<CR>']])

-- &cms &com: comment block/comment lines
vim.cmd.AddComment = function () -- user function under vim.cmd {{{
    vim.cmd([["
    " echo mode() visualmode(): v/V/^V
    " echo split(&cms, '%s')[0]
    let b:c = split(&cms, '%s')
    let b:s = b:c[0].' '
    let b:e = ''

    if len(b:c) > 1 | let b:e = ' '.b:c[1] | endif
    if visualmode() == 'v'
        let @" = b:s.@".b:e
    elseif visualmode() == "V"
        let @" = substitute(@", '[^\n]\+', ' '.b:s.'\0'.b:e, 'g')
    " else " ^V not support
    endif
    silent normal P
    " if last line then use p

    unlet b:c b:s b:e
    " if mode()=="v"
    "     let [line_start, column_start] = getpos("v")[1:2]
    "     let [line_end, column_end] = getpos(".")[1:2]
    " else
    "     let [line_start, column_start] = getpos("'<")[1:2]
    "     let [line_end, column_end] = getpos("'>")[1:2]
    " end
    " let lines = getline(line_start, line_end)
    " if len(lines) == 0 | return '' | endif
    " vnoremap <F2> :<C-u>for line in getline("'<", "'>") \| execute line \| endfor<CR>
    ]])
end -- }}}
vim.keymap.set('v', '<F2>', 'x:lua vim.cmd.AddComment()<CR>', {silent = true})

local libvim = '~/.config/nvim/lib.vim'
vim.keymap.set('n', '<A-m>', ':split '..libvim..'<CR>', {silent = true})
vim.keymap.set('v', '<A-m>', ':source '..libvim..'<CR>', {silent = true})
-- }}}

-- ----- file support ----- {{{
-- Ignore these files when completing names and in Explorer
vim.o.wildignore = '.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif'

vim.cmd([[
autocmd BufWritePost $MYVIMRC source <afile>

augroup filetype
    au BufRead,BufNewFile *akefile*,.*akefile*,*.mk  set filetype=make
    au BufRead,BufNewFile *.rml    set filetype=rml
    au BufRead,BufNewFile *.txt    setf text
augroup END

au FileType vim           let&l:kp=':help'
au FileType python        set kp=pydoc
au FileType perl          set kp=perldoc
au FileType c,cpp,h,hpp   set kp=man\ -S\ 3p:2:3
au FileType c,cpp,h,hpp   set ts=2 sw=2

au FileType text,tex,bib,mail,rml,pandoc set kp=sdcv
]])

-- autocmd Syntax c,cpp,tcl,xml set foldmethod=marker
-- autocmd Syntax xml           syn match OotclComment "//.*"
-- autocmd Syntax xml           hi def link OotclComment Comment
-- }}}

-- ====================  PLUGINS SETTINGS  ===========================
require('plugins') -- lua/plugins.lua .config/nvim/lua/plugins.lua
-- NOTE: {{{ :map :nmap ...
-- ====================  GENERAL INFO  ===============================
-- :!col -b " to ignore the control characters
--
-- gv    go back to previous visual selection
-- va{   visual selection {
-- di"   delete in "
-- g/pattern/normal ...
--
-- environment variables start w/ $ : ex. $HOME
-- ab -- general abbreviation; ca -- command line mode abbreviation
-- ca mkix   !makeindex
-- ======================  PATTERN REGX  =============================
-- :g/\<condition\>\%(\s\+number\>\)\@!/p
--   \<         begin of word (don't match "precondition")
--   condition  matches itself
--   \>         end of word (don't match "conditional")
--   \%(        start subpattern
--   \s\+       any number of whitespace (at least one)
--   number     matches itself
--   \>         end of word ("condition numbering" is different)
--   \)         end subpattern
--   \@!        subpattern must NOT match
--
-- :s/\([.0-9]*\s\+\)\{3}/&\r/g
--   &   matched pattern
--
-- insert <CR> after pattern example: s/\(\S\+\s\+\)\{76}/\0\r/g
-- :s/\([.0-9]* \)\{76}/&\r/g    " after matching 76 times
-- ===================================================================
-- use \r to insert linebreak
--   /[(,)]
--   :s//\r&/g
-- =======================  REGISTERS  ===============================
-- : help registers
-- '='   the expression register: you are prompted (see |expression|)
--       When the result is a |List| the items are used as lines.
-- ===================================================================
-- }}}
-- vim:ts=4:sw=4:sts=4:et:fdm=marker:fdl=1
