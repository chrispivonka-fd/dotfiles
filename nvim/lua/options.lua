-- =============================================================================
-- Core Neovim options
-- =============================================================================

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

local indentation = vim.api.nvim_create_augroup("LanguageIndentation", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = indentation,
  pattern = { "python", "rust", "java", "cs", "fsharp", "vb" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = indentation,
  pattern = { "go", "make" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.shiftwidth = 0
    vim.opt_local.tabstop = 8
    vim.opt_local.softtabstop = 0
  end,
})

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = false      -- minimalist: remove line highlight
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.colorcolumn = ""        -- minimalist: hide color column
opt.showmode = false
opt.pumheight = 10
opt.cmdheight = 0           -- minimalist: hide command line when not used

-- Splits
opt.splitright = true
opt.splitbelow = true

-- File handling
opt.swapfile = false
opt.backup = false
opt.undofile = true         -- persistent undo
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.writebackup = false

-- Clipboard
opt.clipboard = "unnamedplus"

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300

-- Whitespace visualization
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Line wrapping
opt.wrap = false
opt.breakindent = true

-- Completion
opt.completeopt = { "menuone", "noselect" }

-- Fold (use treesitter)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99          -- start with all folds open
opt.foldenable = true

-- Misc
opt.mouse = "a"
opt.confirm = true           -- confirm before closing unsaved
opt.iskeyword:append("-")    -- treat hyphenated words as one word
