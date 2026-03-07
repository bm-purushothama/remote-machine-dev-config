-- ~/.config/nvim/lua/mappings.lua
-- Keymaps for large codebase navigation
-- NOTE: Ctrl+hjkl / Alt+hjkl are handled by smart-splits.nvim (configs/smart-splits.lua)

require "nvchad.mappings"

local map = vim.keymap.set

-- ─── General ────────────────────────────────────────────────
map("n", ";",       ":",            { desc = "CMD enter command mode" })
map("i", "jk",      "<ESC>",       { desc = "Exit insert mode" })
map("n", "<ESC>",   "<cmd>noh<CR>",{ desc = "Clear search highlight" })
map("n", "<C-s>",   "<cmd>w<CR>",  { desc = "Save file" })
map("n", "<C-q>",   "<cmd>qa<CR>", { desc = "Quit all" })

-- ─── Better movement ────────────────────────────────────────
map("n", "J",       "mzJ`z",       { desc = "Join lines (keep cursor)" })
map("n", "<C-d>",   "<C-d>zz",     { desc = "Half page down (centered)" })
map("n", "<C-u>",   "<C-u>zz",     { desc = "Half page up (centered)" })
map("n", "n",       "nzzzv",       { desc = "Next search (centered)" })
map("n", "N",       "Nzzzv",       { desc = "Prev search (centered)" })

-- ─── Line manipulation ──────────────────────────────────────
map("v", "J",       ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K",       ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- ─── Better paste ───────────────────────────────────────────
map("x", "p",       [["_dP]],      { desc = "Paste without yank" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yank" })

-- ─── Splits (creation & management) ─────────────────────────
-- Navigation/resizing handled by smart-splits (Ctrl+hjkl / Alt+hjkl)
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>sh", "<cmd>split<CR>",  { desc = "Horizontal split" })
map("n", "<leader>se", "<C-w>=",          { desc = "Equalize splits" })
map("n", "<leader>sx", "<cmd>close<CR>",  { desc = "Close split" })

-- ─── Buffer navigation ──────────────────────────────────────
map("n", "<S-h>",      "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>",      "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>",   { desc = "Delete buffer" })

-- ─── Diagnostics ────────────────────────────────────────────
map("n", "<leader>q",  vim.diagnostic.setloclist,   { desc = "Diagnostic loclist" })
map("n", "]d",         vim.diagnostic.goto_next,    { desc = "Next diagnostic" })
map("n", "[d",         vim.diagnostic.goto_prev,    { desc = "Prev diagnostic" })
map("n", "<leader>dd", vim.diagnostic.open_float,   { desc = "Line diagnostics" })

-- ═════════════════════════════════════════════════════════════
--  LSP NAVIGATION
-- ═════════════════════════════════════════════════════════════
map("n", "gd",         "<cmd>Telescope lsp_definitions<CR>",      { desc = "Go to definition" })
map("n", "gr",         "<cmd>Telescope lsp_references<CR>",       { desc = "References" })
map("n", "gi",         "<cmd>Telescope lsp_implementations<CR>",  { desc = "Implementations" })
map("n", "gt",         "<cmd>Telescope lsp_type_definitions<CR>", { desc = "Type definition" })
map("n", "<leader>ca", vim.lsp.buf.code_action,                   { desc = "Code action" })
map("n", "<leader>rn", vim.lsp.buf.rename,                        { desc = "Rename symbol" })
map("n", "K",          vim.lsp.buf.hover,                         { desc = "Hover docs" })
map("n", "<leader>ls", vim.lsp.buf.signature_help,                { desc = "Signature help" })

-- ═════════════════════════════════════════════════════════════
--  GTAGS / CSCOPE NAVIGATION (gutentags_plus)
--  Works on ANY language with pygments — no LSP needed
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>gs", "<cmd>GscopeFind s <C-R><C-W><CR>", { desc = "Gtags: Find symbol" })
map("n", "<leader>gd", "<cmd>GscopeFind g <C-R><C-W><CR>", { desc = "Gtags: Find definition" })
map("n", "<leader>gc", "<cmd>GscopeFind c <C-R><C-W><CR>", { desc = "Gtags: Find callers" })
map("n", "<leader>gC", "<cmd>GscopeFind d <C-R><C-W><CR>", { desc = "Gtags: Find callees" })
map("n", "<leader>gt", "<cmd>GscopeFind t <C-R><C-W><CR>", { desc = "Gtags: Find text" })
map("n", "<leader>ge", "<cmd>GscopeFind e <C-R><C-W><CR>", { desc = "Gtags: Find egrep" })
map("n", "<leader>gf", "<cmd>GscopeFind f <C-R>=expand('<cfile>')<CR><CR>", { desc = "Gtags: Find file" })
map("n", "<leader>gi", "<cmd>GscopeFind i <C-R>=expand('<cfile>')<CR><CR>", { desc = "Gtags: Find includers" })
map("n", "<leader>ga", "<cmd>GscopeFind a <C-R><C-W><CR>", { desc = "Gtags: Find assignments" })

-- ═════════════════════════════════════════════════════════════
--  AERIAL — Code outline sidebar
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>ao", "<cmd>AerialToggle!<CR>",    { desc = "Aerial: Toggle outline" })
map("n", "<leader>an", "<cmd>AerialNext<CR>",       { desc = "Aerial: Next symbol" })
map("n", "<leader>ap", "<cmd>AerialPrev<CR>",       { desc = "Aerial: Prev symbol" })
map("n", "<leader>af", "<cmd>Telescope aerial<CR>", { desc = "Aerial: Fuzzy symbols" })

-- ═════════════════════════════════════════════════════════════
--  TELESCOPE
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>",            { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",             { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",               { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",             { desc = "Help tags" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>",              { desc = "Recent files" })
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>",  { desc = "Document symbols" })
map("n", "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", { desc = "Workspace symbols" })
map("n", "<leader>fw", "<cmd>Telescope grep_string<CR>",           { desc = "Grep word under cursor" })
map("n", "<leader>fp", "<cmd>Telescope projects<CR>",              { desc = "Recent projects" })

-- ═════════════════════════════════════════════════════════════
--  FZF-LUA (faster on remote/SSH)
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>zf", "<cmd>FzfLua files<CR>",                { desc = "Fzf: Files" })
map("n", "<leader>zg", "<cmd>FzfLua live_grep<CR>",            { desc = "Fzf: Live grep" })
map("n", "<leader>zb", "<cmd>FzfLua buffers<CR>",              { desc = "Fzf: Buffers" })
map("n", "<leader>zs", "<cmd>FzfLua lsp_document_symbols<CR>", { desc = "Fzf: Document symbols" })
map("n", "<leader>zS", "<cmd>FzfLua lsp_workspace_symbols<CR>",{ desc = "Fzf: Workspace symbols" })
map("n", "<leader>zr", "<cmd>FzfLua lsp_references<CR>",       { desc = "Fzf: References" })
map("n", "<leader>zd", "<cmd>FzfLua lsp_definitions<CR>",      { desc = "Fzf: Definitions" })
map("n", "<leader>zi", "<cmd>FzfLua lsp_implementations<CR>",  { desc = "Fzf: Implementations" })
map("n", "<leader>zw", "<cmd>FzfLua grep_cword<CR>",           { desc = "Fzf: Grep word" })
map("n", "<leader>zW", "<cmd>FzfLua grep_cWORD<CR>",           { desc = "Fzf: Grep WORD" })
map("n", "<leader>zt", "<cmd>FzfLua tags<CR>",                 { desc = "Fzf: Tags" })
map("n", "<leader>zT", "<cmd>FzfLua btags<CR>",                { desc = "Fzf: Buffer tags" })
map("n", "<leader>zl", "<cmd>FzfLua lines<CR>",                { desc = "Fzf: Lines (all bufs)" })
map("n", "<leader>zL", "<cmd>FzfLua blines<CR>",               { desc = "Fzf: Lines (cur buf)" })
map("n", "<leader>zc", "<cmd>FzfLua git_commits<CR>",          { desc = "Fzf: Git commits" })
map("n", "<leader>zx", "<cmd>FzfLua diagnostics_document<CR>", { desc = "Fzf: Diagnostics" })
map("n", "<leader>zX", "<cmd>FzfLua diagnostics_workspace<CR>",{ desc = "Fzf: Workspace diag" })
map("n", "<leader>zq", "<cmd>FzfLua quickfix<CR>",             { desc = "Fzf: Quickfix" })
map("n", "<leader>zh", "<cmd>FzfLua help_tags<CR>",            { desc = "Fzf: Help" })
map("n", "<leader>zo", "<cmd>FzfLua oldfiles<CR>",             { desc = "Fzf: Recent files" })

-- ═════════════════════════════════════════════════════════════
--  GIT (Telescope)
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>Gc", "<cmd>Telescope git_commits<CR>",  { desc = "Git commits" })
map("n", "<leader>Gb", "<cmd>Telescope git_branches<CR>", { desc = "Git branches" })
map("n", "<leader>Gs", "<cmd>Telescope git_status<CR>",   { desc = "Git status" })

-- ═════════════════════════════════════════════════════════════
--  DAP (Debug)
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
map("n", "<leader>dc", "<cmd>DapContinue<CR>",         { desc = "Debug continue" })
map("n", "<leader>di", "<cmd>DapStepInto<CR>",         { desc = "Step into" })
map("n", "<leader>do", "<cmd>DapStepOver<CR>",         { desc = "Step over" })
map("n", "<leader>dO", "<cmd>DapStepOut<CR>",          { desc = "Step out" })
map("n", "<leader>dr", "<cmd>DapToggleRepl<CR>",       { desc = "Toggle REPL" })
map("n", "<leader>dt", "<cmd>DapTerminate<CR>",        { desc = "Terminate debug" })
map("n", "<leader>du", function() require("dapui").toggle() end, { desc = "Toggle DAP UI" })

-- ═════════════════════════════════════════════════════════════
--  TROUBLE
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",              { desc = "Trouble: Diagnostics" })
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Trouble: Buffer diag" })
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>",                  { desc = "Trouble: Loclist" })
map("n", "<leader>xq", "<cmd>Trouble quickfix toggle<CR>",                 { desc = "Trouble: Quickfix" })

-- ═════════════════════════════════════════════════════════════
--  TOGGLES
-- ═════════════════════════════════════════════════════════════
map("n", "<leader>tw", "<cmd>set wrap!<CR>",           { desc = "Toggle wrap" })
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
