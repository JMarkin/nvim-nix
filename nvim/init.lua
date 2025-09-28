vim.loader.enable()

table.unpack = table.unpack or unpack
if not vim.uv then
  vim.uv = vim.loop
end

local g = vim.g
local opt = vim.opt

g.has_ui = #vim.api.nvim_list_uis() > 0
g.modern_ui = (g.has_ui and vim.env.DISPLAY ~= nil) or string.format("%s", vim.env.TERM):find("256")
g.post_load_events = { "BufReadPost", "FileReadPost", "TermOpen" }
g.pre_load_events = { "BufReadPre", "FileReadPre", "BufNewFile", "TermOpen" }

-- stylua: ignore start
g.snips_author                                               = vim.env.AUTHOR or "Jury Markin"
g.snips_email                                                = vim.env.EMAIL or "me@jmarkin.ru"
g.snips_github                                               = vim.env.GITHUB or "https://github.com/JMarkin"


opt.cmdheight                                                = 1
-- opt.colorcolumn                                   = '+1'
opt.cursorlineopt                                            = 'both'
opt.cursorline                                               = true
-- g.cursorhold_updatetime                           = 200
g.default_winwidth                                           = 20
g.default_winheight                                          = 1
opt.winwidth                                                 = g.default_winwidth
opt.winheight                                                = g.default_winheight
opt.winminwidth                                              = 20
opt.pumheight                                                = 20
opt.splitright                                               = true
opt.splitbelow                                               = true
opt.equalalways                                              = false
opt.updatetime                                               = 200
opt.number                                                   = true
g.numbertoggle                                               = true
opt.ruler                                                    = true
opt.scrolloff                                                = 4
opt.sidescrolloff                                            = 8
opt.sidescroll                                               = 0
opt.signcolumn                                               = 'yes:1'
opt.swapfile                                                 = true
opt.undofile                                                 = true
opt.wrap                                                     = false
opt.linebreak                                                = true
opt.breakindent                                              = true
opt.scrollback                                               = 2000
opt.conceallevel                                             = 0
opt.autowriteall                                             = true
opt.virtualedit                                              = 'block'
opt.mouse                                                    = "vh"
opt.mousemoveevent                                           = true
opt.mousefocus                                               = false
g.mapleader                                                  = "\\"
opt.fileencoding                                             = "utf-8"
opt.encoding                                                 = "utf-8"
opt.hidden                                                   = true
opt.showmatch                                                = false
opt.hlsearch                                                 = true
opt.autochdir                                                = false
opt.bs                                                       = "indent,eol,start"
g.editorconfig                                               = true
opt.synmaxcol                                                = 2000
opt.exrc                                                     = true
opt.laststatus                                               = 3

opt.guifont                                                  = "JetBrainsMonoNL Nerd Font Mono:h13"
opt.guicursor                                                = "a:block"
opt.background                                               = "dark"

if vim.fn.has('nvim-0.11')                                  == 1 then
opt.completeopt                                              = "menu,menuone,noselect,popup,noinsert,fuzzy"
else
opt.completeopt                                              = "menu,menuone,noselect,popup,noinsert"
end
opt.cia                                                      = 'kind,abbr,menu'

opt.tags                                                     = { "tags", ".git/tags" }

opt.spell                                                    = false
opt.spelllang                                                = { "en", "ru" }
g.spellfile_URL                                              = "https://ftp.nluug.nl/vim/runtime/spell/"

g.root_pattern                                               = {
                                                                  ".nvim.lua",
                                                                  "flake.nix",
                                                                  "Makefile",
                                                                  ".git",
                                                               }
opt.list                                                     = true
opt.listchars                                                = {
                                                                tab    = '→ ',
                                                                trail  = '·',
                                                                eol    = '↲',
                                                               }
opt.fillchars                                                = {
                                                                eob    = ' ',
                                                               }

opt.tabstop                                                  = 4
opt.softtabstop                                              = 4
opt.shiftwidth                                               = 4
opt.expandtab                                                = true
opt.smartindent                                              = true
opt.autoindent                                               = true

opt.ignorecase                                               = true
opt.smartcase                                                = true

opt.termguicolors                                            = true

opt.textwidth                                                = 80

opt.relativenumber                                           = true
opt.sessionoptions                                           = 'curdir,folds,globals,help,tabpages,terminal,winsize'
opt.viewoptions                                              = 'folds,cursor'

g.omni_sql_ignorecase                                        = 1




g.lsp_autostart                                              = vim.env.LSP_AUTOSTART ~= nil

opt.wildignore:append({ -- Ignore on file name completion.
	".DS_store",
	"**/node_modules/**",
	"**/.venv/**",
})

opt.lazyredraw                                    = true

-- stylua: ignore end
g.dbs = {
  { name = "local", url = vim.env.DB_URL },
}

opt.shortmess:append({ W = false, I = true, c = true, C = true, A = false })

if g.modern_ui then
  opt.listchars:append({ nbsp = "␣" })
  opt.fillchars:append({
    eob = " ",
    diff = "╱",
  })
  vim.api.nvim_command('colorscheme ex-bamboo')
  -- vim.schedule(function ()
  --     vim.api.nvim_command('colorscheme ex-bamboo')
  -- end)
else
  opt.termguicolors = false
end

opt.backup = true
opt.backupdir:remove(".")

-- netrw settings
-- stylua: ignore start
g.netrw_winsize         = 30
g.netrw_banner          = 0
g.netrw_cursor          = 5
g.netrw_keepdir         = 1
g.netrw_list_hide       =  "__pycache__," .. [[\(^\|\s\s\)\zs\.\S\+]]
g.netrw_liststyle       = 0
g.netrw_localcopydircmd = "cp -r"
g.netrw_localmkdir      = "mkdir -p"
g.netrw_preview         = 1
g.netrw_alto            = 1
g.netrw_fastbrowse      = 2
g.netrw_sizestyle       = "H"
g.netrw_sort_options    = "i"
-- stylua: ignore end

-- disable plugins shipped with neovim
-- g.loaded_2html_plugin = 1
g.loaded_matchit = 1
g.loaded_tutor_mode_plugin = 1
g.loaded_vimball = 1
g.loaded_vimballPlugin = 1
g.loaded_python3_provider = 1
g.loaded_ruby_provider = 1
g.loaded_node_provider = 1
g.loaded_perl_provider = 1

-- g.loaded_zip = 1
-- g.loaded_zipPlugin = 1
-- g.loaded_gzip = 1
-- g.loaded_tar = 1
-- g.loaded_tarPlugin = 1
-- stylua: ignore end

vim.g.rainbow_delimiters_highlight = {
  "RainbowDelimiterRed",
  "RainbowDelimiterYellow",
  "RainbowDelimiterBlue",
  "RainbowDelimiterOrange",
  "RainbowDelimiterGreen",
  "RainbowDelimiterViolet",
  "RainbowDelimiterCyan",
}
