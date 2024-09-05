-- calling `lua require('plugins')` from your init.vim
-- vim.o vim.bo vim.wo vim.g vim.b vim.w vim.t
-- vim.call({func},{...}) vim.cmd({cmd}), vim.fn.{func}({...})

-- ================================================================= --
-- :help packages
-- ~/.local/share/nvim/site/pack/*
-- vim.cmd [[packadd packer]]
-- vim.cmd 'autocmd BufWritePost plugins.lua PackerCompile'
-- vim.cmd 'autocmd BufWritePost plugins.lua PackerUpdate'
-- vim.cmd 'autocmd BufWritePost plugins.lua PackerSync'

-- https://github.com/junegunn/vim-plug?tab=readme-ov-file
-- put it in ~/.config/nvim/autoload/plug.vim
vim.cmd [[
call plug#begin()

Plug 'neovim/nvim-lspconfig'
Plug 'ms-jpq/coq_nvim'
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'majutsushi/tagbar'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'numToStr/FTerm.nvim'

call plug#end()
]]

-- Pandoc :Pandoc [option]* {{{
-- " let g:pad#dir = "~/documents/notes"
-- " let g:pad#local_dir = "notes"
-- " let g:pandoc#after#modules#enabled = ["nrrwrgn", "ultisnips"]
-- " let g:pandoc#syntax#codeblocks#embeds#langs = ["ruby", "literatehaskell=lhaskell", "bash=sh"]
vim.g['pandoc#syntax#codeblocks#embeds#langs'] = {
    "lua", "cpp", "bash=sh", "vim", "make", "html", "sql", "java", "javascript", "css"
}
vim.g['pandoc#spell#enabled'] = 1
-- " let g:pandoc#folding#mode = ["expr"]
-- " let g:pandoc#folding#mode = "syntax"
vim.g['pandoc#folding#fold_fenced_codeblocks'] = 1
-- " let g:pandoc#folding#fold_vim_markers = 1
-- " let g:pandoc#filetypes#handled = ["pandoc", "markdown"]
-- " let g:pandoc#filetypes#pandoc_markdown = 0
vim.g['pandoc#modules#enabled'] = {"formatting", "folding", "keyboard"}
-- " let g:pandoc#formatting#mode = "h"
-- }}}

-- nvim-treesitter {{{
-- https://github.com/nvim-treesitter/nvim-treesitter
-- :TSInstallInfo
-- :TSInstall <lang>
-- :TSUpdate}}}


-- aerial.nvim: https://github.com/stevearc/aerial.nvim
-- telescope.nvim

-- FTerm.nvim{{{
require('FTerm').setup {
    border = 'double', -- 'single',
    dimension = {height = 0.8, width = 0.8, x = 0.5, y = 0.5},
    ft = 'FTerm', ---Filetype of the terminal buffer -@type string

    ---Command to run inside the terminal
    ---NOTE: if given string[], it will skip the shell and directly executes the command
    ---@type fun():(string|string[])|string|string[]
    cmd = os.getenv('SHELL'),

    -- auto_close = true, ---Close the terminal as soon as shell/command exits.
    hl = 'Normal', ---Highlight group for the terminal. See `:h winhl`
    blend = 0, ---Transparency of the floating window. See `:h winblend`
    clear_env = false, ---See `:h jobstart-options`
    env = nil, ---See `:h jobstart-options` -@type table<string,string>|nil
    on_exit = nil, ---See `:h jobstart-options` -@type fun()|nil
    on_stdout = nil, ---See `:h jobstart-options` -@type fun()|nil
    on_stderr = nil, ---See `:h jobstart-options` -@type fun()|nil
}
vim.keymap.set('n', '<A-t>', '<CMD>lua require("FTerm").toggle()<CR>')
vim.keymap.set('t', '<A-t>', '<C-\\><C-n><CMD>lua require("FTerm").toggle()<CR>')
-- }}}

-- fix colors/highlighting in 0.8
vim.api.nvim_set_hl(0, 'FloatBorder', {bg = '#3B4252', fg = '#5E81AC'})
vim.api.nvim_set_hl(0, 'NormalFloat', {bg = '#3B4252'})
vim.api.nvim_set_hl(0, 'TelescopeNormal', {bg = '#3B4252'})
vim.api.nvim_set_hl(0, 'TelescopeBorder', {bg = '#3B4252'})

local nvim_lsp = require('lspconfig')
local coq = require('coq')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function (client, bufnr)-- {{{
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    --Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end-- }}}

-- map buffer local keybindings when the language server attaches
-- local servers = { "pyright", "rust_analyzer", "tsserver" }
-- for _, lsp in ipairs(servers) do
--   nvim_lsp[lsp].setup {
--     on_attach = on_attach,
--     -- flags = {debounce_text_changes = 150}
--   }
-- end

-- =======================  LSP SETTINGS  ============================ --
-- ~/.local/share/nvim/site/pack/lua-language-server
nvim_lsp.lua_ls.setup {-- {{{
    on_init = function (client)
        local path = client.workspace_folders[1].name -- ~/.config/nvim/lua
        if not vim.loop.fs_stat(path..'/.luarc.json') and not vim.loop.fs_stat(path..'/.luarc.jsonc') then
            client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
            Lua = {
                runtime = {version = 'LuaJIT'}, -- or 'Lua 5.4'
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME
                        -- "${3rd}/luv/library"
                        -- "${3rd}/busted/library",
                    }
                    -- library = vim.api.nvim_get_runtime_file("", true)
                }
            }
            })
            client.notify("workspace/didChangeConfiguration", {settings = client.config.settings})
        end
        return true
    end,
    on_attach = on_attach,
}-- }}}

-- tagbar {{{
-- " let g:tagbar_ctags_bin = 'ctags'   "ctags 程序的路径
vim.g.tagbar_width = 28            -- 窗口宽度设置为 30
vim.g.tagbar_left = 0              -- 设置在 vim 左边显示
-- " let g:tagbar_vertical = winheight(0)/2

vim.g.tagbar_type_pandoc = { -- disable markdown/pandoc
    ctagsbin = 'true',
    ctagstype = 'markdown', -- 'c++', 'Unknown',
    -- regex = {'/(TODO).*//T,ToDo,ToDo Messages/{_anonymous=todo_}',},
    -- kinds = {
    --     'h:header files:1:0',
    --     'd:macros:1:0',
    --     'p:prototypes:1:0',
    --     'g:enums:0:1',
    --     'e:enumerators:0:0',
    --     't:typedefs:0:0',
    --     's:structs:0:1',
    --     'm:members:1:0',
    --     'v:variables:0:0',
    --     'f:functions:0:1',
    --     'T:todo:0:0',
    -- },
    -- sro = '::',
    -- kind2scope = {g = 'enum', s = 'struct'},
    -- scope2kind = {enum = 'g', struct = 's'}
}
-- }}}
-- vim:ts=4:sw=4:sts=4:et:fdm=marker:fdl=1
