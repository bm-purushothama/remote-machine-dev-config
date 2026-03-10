-- ~/.config/nvim/lua/configs/smart-splits.lua

require("smart-splits").setup({
  ignored_buftypes = { "NvimTree" },
  default_amount = 3,
  at_edge = "wrap",
  move_cursor_same_row = false,
  cursor_follows_swapped_bufs = false,
})

local map = vim.keymap.set

-- Navigation: Ctrl+hjkl
map("n", "<C-h>", function() require("smart-splits").move_cursor_left() end,  { desc = "Move to left split/pane" })
map("n", "<C-j>", function() require("smart-splits").move_cursor_down() end,  { desc = "Move to below split/pane" })
map("n", "<C-k>", function() require("smart-splits").move_cursor_up() end,    { desc = "Move to above split/pane" })
map("n", "<C-l>", function() require("smart-splits").move_cursor_right() end, { desc = "Move to right split/pane" })

-- Resizing: Alt+hjkl
map("n", "<A-h>", function() require("smart-splits").resize_left() end,  { desc = "Resize left" })
map("n", "<A-j>", function() require("smart-splits").resize_down() end,  { desc = "Resize down" })
map("n", "<A-k>", function() require("smart-splits").resize_up() end,    { desc = "Resize up" })
map("n", "<A-l>", function() require("smart-splits").resize_right() end, { desc = "Resize right" })

-- Buffer swapping: Leader+Leader+hjkl
map("n", "<leader><leader>h", function() require("smart-splits").swap_buf_left() end,  { desc = "Swap buffer left" })
map("n", "<leader><leader>j", function() require("smart-splits").swap_buf_down() end,  { desc = "Swap buffer down" })
map("n", "<leader><leader>k", function() require("smart-splits").swap_buf_up() end,    { desc = "Swap buffer up" })
map("n", "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, { desc = "Swap buffer right" })
