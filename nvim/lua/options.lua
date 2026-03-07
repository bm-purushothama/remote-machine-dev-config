-- ~/.config/nvim/lua/options.lua
-- Editor options (optimized for large codebase / remote dev server)

local opt = vim.opt
local g   = vim.g

-- ── Leader ──────────────────────────────────────────────────
g.mapleader      = " "
g.maplocalleader = "\\"

-- ── Indentation ─────────────────────────────────────────────
opt.tabstop      = 4
opt.shiftwidth   = 4
opt.softtabstop  = 4
opt.expandtab    = true
opt.smartindent  = true
opt.shiftround   = true

-- ── Line Numbers ────────────────────────────────────────────
opt.number         = true
opt.relativenumber = true
opt.cursorline     = true
opt.signcolumn     = "yes"

-- ── Search ──────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase  = true
opt.hlsearch   = true
opt.incsearch  = true

-- ── UI ──────────────────────────────────────────────────────
opt.termguicolors  = true
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.splitbelow     = true
opt.splitright     = true
opt.wrap           = false
opt.linebreak      = true
opt.showmode       = false
opt.cmdheight      = 1
opt.pumheight      = 15
opt.laststatus     = 3           -- Global statusline
opt.fillchars      = { eob = " ", fold = " ", foldopen = "", foldsep = " ", foldclose = "" }
opt.smoothscroll   = true        -- Neovim 0.10+

-- ── Performance (tuned for remote / SSH) ────────────────────
opt.updatetime  = 200
opt.timeoutlen  = 300
opt.lazyredraw  = false
opt.redrawtime  = 1500
opt.synmaxcol   = 240
opt.ttyfast     = true           -- Assume fast terminal (helps SSH)

-- ── Persistence ─────────────────────────────────────────────
opt.undofile    = true
opt.undolevels  = 10000
opt.swapfile    = false
opt.backup      = false
opt.writebackup = false
opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,terminal"

-- ── Folding (Treesitter-based) ──────────────────────────────
opt.foldmethod  = "expr"
opt.foldexpr    = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel   = 99
opt.foldlevelstart = 99
opt.foldenable  = true

-- ── Completion ──────────────────────────────────────────────
opt.completeopt = "menu,menuone,noselect"

-- ── Clipboard ───────────────────────────────────────────────
opt.clipboard   = "unnamedplus"

-- ── Grep (use ripgrep — much faster than grep on big trees) ─
opt.grepprg    = "rg --vimgrep --smart-case --hidden"
opt.grepformat = "%f:%l:%c:%m"

-- ── Add Mason binaries to PATH ──────────────────────────────
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- ── WINBAR with navic breadcrumbs ───────────────────────────
-- Shows: 󰈙 filename  Module  Class  Method
-- Invaluable for orientation in large files
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities.documentSymbolProvider then
      -- Set winbar to show file icon + navic breadcrumbs
      vim.wo.winbar = "%{%v:lua.require('nvim-navic').get_location()%}"
    end
  end,
})

-- ── GNU Global (gtags) environment ──────────────────────────
-- Use native-pygments for multi-language support beyond C/C++
-- Install: pip install pygments
-- This makes gtags work for Python, JS, Rust, Go, Ruby, etc.
vim.env.GTAGSLABEL = "native-pygments"
-- Optional: set GTAGSCONF if non-standard location
-- vim.env.GTAGSCONF = "/usr/local/share/gtags/gtags.conf"

-- ── Large file performance guard ────────────────────────────
-- Disable expensive features for files > 1.5MB
vim.api.nvim_create_autocmd("BufReadPre", {
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 1.5 * 1024 * 1024 then
      vim.b[args.buf].large_file = true
      vim.cmd("syntax clear")
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      vim.opt_local.swapfile = false
      vim.opt_local.undofile = false
      vim.opt_local.breakindent = false
      vim.opt_local.colorcolumn = ""
      vim.opt_local.statuscolumn = ""
      vim.opt_local.signcolumn = "no"
      vim.b[args.buf].miniindentscope_disable = true
      -- Notify the user
      vim.notify("Large file detected — heavy features disabled", vim.log.levels.WARN)
    end
  end,
})
