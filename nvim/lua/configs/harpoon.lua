-- ~/.config/nvim/lua/configs/harpoon.lua
-- Harpoon 2 — Pin & instant-switch hot files in large codebases

local harpoon = require("harpoon")

harpoon:setup({
  settings = {
    save_on_toggle = true,
    sync_on_ui_close = true,
    -- Per-branch marks (useful when working on multiple features)
    key = function()
      -- Use git branch as part of the key if in a git repo
      local branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
      if vim.v.shell_error == 0 and branch ~= "" then
        return vim.uv.cwd() .. "-" .. branch
      end
      return vim.uv.cwd()
    end,
  },
})

local map = vim.keymap.set

-- ── Add / Toggle UI ────────────────────────────────────────
map("n", "<leader>ha", function() harpoon:list():add() end,
  { desc = "Harpoon: Add file" })

map("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "Harpoon: Toggle menu" })

-- ── Direct file access (1-5) ────────────────────────────────
-- These are your hot-keys: muscle memory for your most-used files
map("n", "<leader>1", function() harpoon:list():select(1) end,
  { desc = "Harpoon: File 1" })
map("n", "<leader>2", function() harpoon:list():select(2) end,
  { desc = "Harpoon: File 2" })
map("n", "<leader>3", function() harpoon:list():select(3) end,
  { desc = "Harpoon: File 3" })
map("n", "<leader>4", function() harpoon:list():select(4) end,
  { desc = "Harpoon: File 4" })
map("n", "<leader>5", function() harpoon:list():select(5) end,
  { desc = "Harpoon: File 5" })

-- ── Cycle through harpooned files ───────────────────────────
map("n", "<leader>hp", function() harpoon:list():prev() end,
  { desc = "Harpoon: Prev file" })
map("n", "<leader>hn", function() harpoon:list():next() end,
  { desc = "Harpoon: Next file" })

-- ── Telescope integration ───────────────────────────────────
-- Toggle Harpoon list via Telescope for a nicer preview
map("n", "<leader>ht", function()
  local conf = require("telescope.config").values
  local file_paths = {}
  for _, item in ipairs(harpoon:list().items) do
    table.insert(file_paths, item.value)
  end

  require("telescope.pickers").new({}, {
    prompt_title = "Harpoon",
    finder = require("telescope.finders").new_table({ results = file_paths }),
    previewer = conf.file_previewer({}),
    sorter = conf.generic_sorter({}),
  }):find()
end, { desc = "Harpoon: Telescope picker" })
