-- ~/.config/nvim/lua/configs/smart-splits.lua
-- Seamless navigation & resizing between Neovim splits and tmux panes
--
-- Ctrl+h/j/k/l = move between splits/panes
-- Alt+h/j/k/l  = resize splits/panes
-- Both work identically whether you're in nvim or tmux

local smart_splits = require("smart-splits")

smart_splits.setup({
  -- Recommended: leave default resize amounts
  resize_mode = {
    quit_key = "<ESC>",
    resize_keys = { "h", "j", "k", "l" },
    silent = false,
    hooks = {
      on_enter = function()
        vim.notify("Resize mode: h/j/k/l to resize, ESC to exit", vim.log.levels.INFO)
      end,
      on_leave = nil,
    },
  },

  -- Ignored filetypes (don't navigate into these)
  ignored_filetypes = { "nofile", "quickfix", "prompt" },
  ignored_buftypes  = { "NvimTree" },

  -- Default multiplier for resize amount
  default_amount = 3,

  -- At edge of nvim, move to tmux pane
  at_edge = "wrap",

  -- Move cursor to the same row when moving to a tmux pane
  move_cursor_same_row = false,

  -- Cursor follows buffer when swapping
  cursor_follows_swapped_bufs = false,

  -- Multiplexer integration (auto-detects tmux)
  multiplexer_integration = nil, -- auto-detect
})

local map = vim.keymap.set

-- ── Navigation: Ctrl+hjkl ───────────────────────────────────
-- These work seamlessly across nvim splits and tmux panes
map("n", "<C-h>", smart_splits.move_cursor_left,  { desc = "Move to left split/pane" })
map("n", "<C-j>", smart_splits.move_cursor_down,  { desc = "Move to below split/pane" })
map("n", "<C-k>", smart_splits.move_cursor_up,    { desc = "Move to above split/pane" })
map("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Move to right split/pane" })

-- ── Resizing: Alt+hjkl ─────────────────────────────────────
-- These also work across nvim and tmux
map("n", "<A-h>", smart_splits.resize_left,  { desc = "Resize left" })
map("n", "<A-j>", smart_splits.resize_down,  { desc = "Resize down" })
map("n", "<A-k>", smart_splits.resize_up,    { desc = "Resize up" })
map("n", "<A-l>", smart_splits.resize_right, { desc = "Resize right" })

-- ── Buffer swapping: Leader+hjkl ────────────────────────────
-- Swap the current buffer with the one in the direction
map("n", "<leader><leader>h", smart_splits.swap_buf_left,  { desc = "Swap buffer left" })
map("n", "<leader><leader>j", smart_splits.swap_buf_down,  { desc = "Swap buffer down" })
map("n", "<leader><leader>k", smart_splits.swap_buf_up,    { desc = "Swap buffer up" })
map("n", "<leader><leader>l", smart_splits.swap_buf_right, { desc = "Swap buffer right" })

-- ── Persistent resize mode ──────────────────────────────────
-- Enter with leader+r, then use h/j/k/l freely, ESC to exit
map("n", "<leader>wr", smart_splits.start_resize_mode, { desc = "Enter resize mode" })
