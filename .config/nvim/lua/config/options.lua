local opt = vim.opt

-- Basic
opt.errorbells = false
opt.belloff = "all"
opt.mouse = "a"
opt.encoding = "utf-8"
opt.fileformat = "unix"
opt.swapfile = false
-- smartcase has no effect unless ignorecase is also on (see :h smartcase);
-- the original init.vim set smartcase alone, which was a no-op
opt.ignorecase = true
opt.smartcase = true
opt.wrap = true
opt.whichwrap:append("<,>,[,]")
opt.backspace = { "indent", "eol", "start" }
opt.incsearch = true
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.autoindent = true
opt.scrolloff = 5
opt.splitbelow = true
opt.splitright = true
opt.wildmenu = true

-- matchit (ships with Neovim as an optional runtime package, replaces
-- tmhedberg/matchit)
vim.cmd("packadd! matchit")

-- Backup
opt.backup = true
opt.backupdir = vim.fn.stdpath("config") .. "/backups//"
opt.writebackup = true
opt.backupcopy = "yes"
vim.fn.mkdir(vim.fn.stdpath("config") .. "/backups", "p")

-- Indentation
vim.cmd("filetype plugin indent on")

-- Appearance
vim.cmd("syntax on")
opt.cursorline = true
opt.background = "dark"
opt.termguicolors = true
opt.laststatus = 2
opt.showmode = false

-- Diagnostics: keep the color/virtual text, drop the underline (nvim
-- defaults underline = true, which draws a plain solid line under
-- flagged code, e.g. lint warnings on JSX tags)
vim.diagnostic.config({ underline = false })
