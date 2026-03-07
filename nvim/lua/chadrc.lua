-- ~/.config/nvim/lua/chadrc.lua
-- NvChad v2.5 UI Configuration

---@type ChadrcConfig
local M = {}

-- ── Theme ───────────────────────────────────────────────────
M.base46 = {
  theme = "catppuccin",          -- 68+ themes: onedark, gruvbox, tokyonight, etc.
  transparency = false,
  hl_override = {
    Comment      = { italic = true },
    ["@comment"] = { italic = true },
    -- Slightly brighter line numbers
    CursorLineNr = { fg = "yellow", bold = true },
  },
}

-- ── UI Components ───────────────────────────────────────────
M.ui = {
  cmp = {
    icons_left  = true,          -- icons on left side of completion menu
    style       = "default",     -- "default" | "atom" | "atom_colored" | "flat_light" | "flat_dark"
    format_colors = {
      tailwind = true,           -- show tailwind color swatches
    },
  },

  telescope = { style = "borderless" },  -- "borderless" | "bordered"

  statusline = {
    theme     = "vscode_colored",        -- default | vscode | vscode_colored | minimal
    separator_style = "round",           -- default | round | block | arrow
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor", "cwd" },
  },

  tabufline = {
    order   = { "treeOffset", "buffers", "tabs", "btns" },
    enabled = true,
  },
}

-- ── Terminal ────────────────────────────────────────────────
M.term = {
  winopts = { number = false, relativenumber = false },
  sizes   = { sp = 0.3, vsp = 0.4, ["bo sp"] = 0.3, ["bo vsp"] = 0.4 },
  float   = { relative = "editor", row = 0.1, col = 0.1, width = 0.8, height = 0.75, border = "rounded" },
}

-- ── Mason ───────────────────────────────────────────────────
M.mason = {
  pkgs = {
    -- LSP servers
    "lua-language-server",
    "typescript-language-server",
    "pyright",
    "rust-analyzer",
    "gopls",
    "clangd",
    "tailwindcss-language-server",
    "css-lsp",
    "html-lsp",
    "json-lsp",
    "yaml-language-server",
    "bash-language-server",
    "dockerfile-language-server",
    "terraform-ls",
    -- Formatters
    "stylua",
    "prettier",
    "black",
    "isort",
    "gofumpt",
    "goimports",
    "clang-format",
    "shfmt",
    -- Linters
    "eslint_d",
    "ruff",
    "shellcheck",
    -- DAP adapters
    "debugpy",
    "delve",
    "codelldb",
    "js-debug-adapter",
  },
}

return M
