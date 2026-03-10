-- ~/.config/nvim/lua/plugins/init.lua
-- NvChad v2.5 — Large codebase on remote dev server
-- Features: gtags, tags completion, smart-splits, flash, aerial, harpoon

return {

  -- ════════════════════════════════════════════════════════════
  --  TREESITTER
  -- ════════════════════════════════════════════════════════════
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "html", "css", "javascript", "typescript", "tsx", "json", "jsonc", "graphql",
        "c", "cpp", "rust", "go", "gomod", "gowork", "gosum", "zig",
        "python", "lua", "luadoc", "bash", "fish", "ruby", "perl",
        "yaml", "toml", "ini", "dockerfile", "terraform", "hcl",
        "sql", "csv",
        "markdown", "markdown_inline", "vimdoc", "regex", "printf",
        "make", "cmake", "ninja", "diff", "git_rebase", "gitcommit", "gitignore",
        "vim",
      },
      highlight = { enable = true, use_languagetree = true, additional_vim_regex_highlighting = false },
      indent    = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>", node_incremental = "<C-space>",
          scope_incremental = false, node_decremental = "<BS>",
        },
      },
    },
  },

  -- ════════════════════════════════════════════════════════════
  --  LSP
  -- ════════════════════════════════════════════════════════════
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- using vim.lsp.config (nvim 0.11+)
      require("configs.lspconfig")
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
    dependencies = { "neovim/nvim-lspconfig", "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({ automatic_installation = true })
    end,
  },

  -- ════════════════════════════════════════════════════════════
  --  NVIM-CMP — Auto-completion engine
  --  Sources: LSP + ctags/gtags + snippets + buffer + path
  --  For C/C++: clangd provides best-in-class completion;
  --  tags act as fallback while clangd is indexing.
  -- ════════════════════════════════════════════════════════════
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      -- Sources
      "hrsh7th/cmp-nvim-lsp",               -- LSP completions (clangd, pyright, etc.)
      "hrsh7th/cmp-nvim-lsp-signature-help", -- Function signature help
      "quangnguyen30192/cmp-nvim-tags",      -- ctags/gtags completions
      "hrsh7th/cmp-buffer",                  -- Buffer word completions
      "hrsh7th/cmp-path",                    -- Filesystem path completions
      "hrsh7th/cmp-cmdline",                 -- Cmdline completions
      -- Snippet engine
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",        -- Predefined snippets for many languages
    },
    config = function()
      -- Load friendly-snippets into LuaSnip
      require("luasnip.loaders.from_vscode").lazy_load()
      -- Load our cmp config
      require("configs.cmp")
    end,
  },

  -- ════════════════════════════════════════════════════════════
  --  CONFORM — Formatting
  -- ════════════════════════════════════════════════════════════
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" }, python = { "isort", "black" },
        javascript = { "prettier" }, typescript = { "prettier" },
        typescriptreact = { "prettier" }, javascriptreact = { "prettier" },
        json = { "prettier" }, jsonc = { "prettier" },
        yaml = { "prettier" }, markdown = { "prettier" },
        html = { "prettier" }, css = { "prettier" }, scss = { "prettier" },
        graphql = { "prettier" },
        go = { "gofumpt", "goimports" }, rust = { "rustfmt" },
        c = { "clang-format" }, cpp = { "clang-format" },
        sh = { "shfmt" }, bash = { "shfmt" },
        terraform = { "terraform_fmt" }, toml = { "taplo" },
      },
      format_on_save = { timeout_ms = 1000, lsp_fallback = true },
      formatters = {
        shfmt = { prepend_args = { "-i", "4", "-ci" } },
        black = { prepend_args = { "--line-length", "100" } },
      },
    },
  },

  -- ════════════════════════════════════════════════════════════
  --  LINT
  -- ════════════════════════════════════════════════════════════
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "ruff" }, javascript = { "eslint_d" }, typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" }, javascriptreact = { "eslint_d" },
        sh = { "shellcheck" }, bash = { "shellcheck" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function() lint.try_lint() end,
      })
    end,
  },

  -- ╔══════════════════════════════════════════════════════════╗
  -- ║  SEAMLESS NVIM ↔ TMUX NAVIGATION                       ║
  -- ╚══════════════════════════════════════════════════════════╝

  -- ════════════════════════════════════════════════════════════
  --  SMART-SPLITS — Unified navigation & resizing
  --  Ctrl+hjkl navigates across nvim splits AND tmux panes.
  --  Alt+hjkl resizes across both.  Zero lag (pure Lua).
  --  DO NOT lazy-load (needs to set @pane-is-vim for tmux).
  -- ════════════════════════════════════════════════════════════
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,    -- Must load eagerly to set tmux @pane-is-vim
    config = function()
      require("configs.smart-splits")
    end,
  },

  -- ╔══════════════════════════════════════════════════════════╗
  -- ║  LARGE CODEBASE NAVIGATION STACK                        ║
  -- ╚══════════════════════════════════════════════════════════╝

  -- ════════════════════════════════════════════════════════════
  --  GUTENTAGS + GTAGS — Cross-reference indexing backbone
  --  Requires: universal-ctags + GNU Global (gtags)
  -- ════════════════════════════════════════════════════════════
  {
    "ludovicchabant/vim-gutentags",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "skywind3000/gutentags_plus" },
    init = function()
      vim.g.gutentags_modules = { "ctags", "gtags_cscope" }
      vim.g.gutentags_project_root = {
        ".git", ".hg", ".svn", ".project", ".root",
        "Makefile", "Cargo.toml", "go.mod", "package.json",
        "pyproject.toml", "setup.py", "CMakeLists.txt",
      }
      vim.g.gutentags_cache_dir = vim.fn.expand("~/.cache/nvim/tags")
      vim.g.gutentags_generate_on_new = true
      vim.g.gutentags_generate_on_missing = true
      vim.g.gutentags_generate_on_write = true
      vim.g.gutentags_generate_on_empty_buffer = false
      vim.g.gutentags_ctags_exclude = {
        "*.min.js", "*.min.css", "node_modules", ".git", ".hg", ".svn",
        "build", "dist", "vendor", "target", "__pycache__", "*.pyc",
        ".venv", "venv", "*.o", "*.a", "*.so", "*.dll",
        "*.lock", "*.log", ".cache", ".idea", ".vscode",
      }
      vim.g.gutentags_ctags_extra_args = { "--tag-relative=yes", "--fields=+ailmnS" }
      vim.g.gutentags_plus_nomap = 1
      vim.fn.mkdir(vim.fn.expand("~/.cache/nvim/tags"), "p")
    end,
  },
  { "skywind3000/gutentags_plus", event = { "BufReadPost", "BufNewFile" } },

  -- ════════════════════════════════════════════════════════════
  --  HARPOON 2 — Pin & instant-switch hot files
  -- ════════════════════════════════════════════════════════════
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("configs.harpoon") end,
  },

  -- ════════════════════════════════════════════════════════════
  --  AERIAL — Code outline / symbol sidebar
  -- ════════════════════════════════════════════════════════════
  {
    "stevearc/aerial.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = { max_width = { 40, 0.25 }, min_width = 30, default_direction = "prefer_right", placement = "edge" },
      attach_mode = "global",
      show_guides = true,
      guides = { mid_item = "├─ ", last_item = "└─ ", nested_top = "│  ", whitespace = "   " },
      filter_kind = {
        "Class", "Constructor", "Enum", "Function", "Interface",
        "Module", "Method", "Struct", "Type", "Variable",
        "Namespace", "Field", "Property", "Constant",
      },
      highlight_on_hover = true, autojump = true, close_on_select = false,
      keymaps = {
        ["<CR>"] = "actions.jump", ["<C-v>"] = "actions.jump_vsplit",
        ["<C-s>"] = "actions.jump_split", ["q"] = "actions.close", ["o"] = "actions.tree_toggle",
      },
    },
  },

  -- ════════════════════════════════════════════════════════════
  --  NAVIC — Breadcrumb context in winbar
  -- ════════════════════════════════════════════════════════════
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    opts = {
      lsp = { auto_attach = true }, highlight = true, separator = "  ", depth_limit = 5,
      icons = {
        File = "󰈙 ", Module = " ", Namespace = "󰌗 ", Package = " ",
        Class = "󰌗 ", Method = "󰆧 ", Property = " ", Field = " ",
        Constructor = " ", Enum = "󰕘 ", Interface = "󰕘 ", Function = "󰊕 ",
        Variable = "󰆧 ", Constant = "󰏿 ", String = "󰀬 ", Number = "󰎠 ",
        Boolean = "◩ ", Array = "󰅪 ", Object = "󰅩 ", Key = "󰌋 ",
        Null = "󰟢 ", EnumMember = " ", Struct = "󰌗 ", Event = " ",
        Operator = "󰆕 ", TypeParameter = "󰊄 ",
      },
    },
  },

  -- ════════════════════════════════════════════════════════════
  --  FLASH — Lightning-fast motion
  -- ════════════════════════════════════════════════════════════
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      labels = "asdfghjklqwertyuiopzxcvbnm",
      modes = { search = { enabled = true }, char = { enabled = true }, treesitter = { labels = "abcdefghijklmnop" } },
      label = { rainbow = { enabled = true, shade = 5 } },
    },
    keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash jump" },
      { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,             desc = "Flash remote" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end,  desc = "Flash TS search" },
      { "<C-s>", mode = "c",               function() require("flash").toggle() end,             desc = "Toggle flash search" },
    },
  },

  -- ════════════════════════════════════════════════════════════
  --  FZF-LUA — Fast fuzzy finder for huge repos over SSH
  -- ════════════════════════════════════════════════════════════
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      winopts = {
        height = 0.85, width = 0.85, row = 0.35, col = 0.50, border = "rounded",
        preview = { layout = "flex", flip_columns = 120, scrollbar = true },
      },
      files = {
        fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude target --exclude build --exclude dist",
        git_icons = true,
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden -g '!.git/' -g '!node_modules/' -g '!__pycache__/' -g '!target/' -g '!build/' -g '!dist/'",
      },
      lsp = { async_or_timeout = 5000 },
      fzf_opts = { ["--layout"] = "reverse" },
    },
  },

  -- ════════════════════════════════════════════════════════════
  --  FIDGET — LSP progress indicator
  -- ════════════════════════════════════════════════════════════
  { "j-hui/fidget.nvim", event = "LspAttach", opts = {
    progress = { display = { render_limit = 5, done_ttl = 3 } },
    notification = { window = { winblend = 0 } },
  }},

  -- ════════════════════════════════════════════════════════════
  --  PROJECT.NVIM — Auto-detect project root
  -- ════════════════════════════════════════════════════════════
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "pattern", "lsp" },
        patterns = { ".git", ".hg", ".svn", "Makefile", "Cargo.toml", "go.mod", "package.json", "pyproject.toml", "CMakeLists.txt", ".project", ".root" },
        silent_chdir = true, scope_chdir = "global", show_hidden = true,
      })
      pcall(function() require("telescope").load_extension("projects") end)
    end,
  },

  -- ════════════════════════════════════════════════════════════
  --  TREESITTER TEXTOBJECTS — Structural code navigation
  -- ════════════════════════════════════════════════════════════
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true, lookahead = true,
            keymaps = {
              ["af"] = { query = "@function.outer", desc = "Outer function" },
              ["if"] = { query = "@function.inner", desc = "Inner function" },
              ["ac"] = { query = "@class.outer",    desc = "Outer class" },
              ["ic"] = { query = "@class.inner",    desc = "Inner class" },
              ["aa"] = { query = "@parameter.outer", desc = "Outer parameter" },
              ["ia"] = { query = "@parameter.inner", desc = "Inner parameter" },
              ["al"] = { query = "@loop.outer",     desc = "Outer loop" },
              ["il"] = { query = "@loop.inner",     desc = "Inner loop" },
              ["ai"] = { query = "@conditional.outer", desc = "Outer conditional" },
              ["ii"] = { query = "@conditional.inner", desc = "Inner conditional" },
            },
          },
          move = {
            enable = true, set_jumps = true,
            goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner", ["]l"] = "@loop.outer" },
            goto_next_end       = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner", ["[l"] = "@loop.outer" },
            goto_previous_end   = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
          },
          swap = { enable = true, swap_next = { ["<leader>sp"] = "@parameter.inner" }, swap_previous = { ["<leader>sP"] = "@parameter.inner" } },
        },
      })
      local ts_repeat = require("nvim-treesitter.textobjects.repeatable_move")
      vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat.repeat_last_move_next)
      vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat.repeat_last_move_previous)
    end,
  },

  -- ════════════════════════════════════════════════════════════
  --  DAP
  -- ════════════════════════════════════════════════════════════
  { "mfussenegger/nvim-dap", dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio", "theHamsta/nvim-dap-virtual-text" }, config = function() require("configs.dap") end },
  {
    "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dapui = require("dapui")
      dapui.setup({ layouts = { { elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 40, position = "left" }, { elements = { "repl", "console" }, size = 0.25, position = "bottom" } }, floating = { border = "rounded" } })
      local dap = require("dap")
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"]     = function() dapui.close() end
    end,
  },
  { "theHamsta/nvim-dap-virtual-text", opts = { commented = true } },

  -- ════════════════════════════════════════════════════════════
  --  GIT / TROUBLE / TODO / INDENT / WHICH-KEY
  -- ════════════════════════════════════════════════════════════
  {
    "lewis6991/gitsigns.nvim", opts = {
      signs = { add = { text = "▎" }, change = { text = "▎" }, delete = { text = "" }, topdelete = { text = "" }, changedelete = { text = "▎" }, untracked = { text = "▎" } },
      current_line_blame = true, current_line_blame_opts = { delay = 500 },
    },
  },
  { "folke/trouble.nvim", cmd = "Trouble", opts = { use_diagnostic_signs = true } },
  { "folke/todo-comments.nvim", event = { "BufReadPost", "BufNewFile" }, dependencies = { "nvim-lua/plenary.nvim" }, opts = {} },
  { "lukas-reineke/indent-blankline.nvim", opts = { scope = { show_start = true, show_end = false } } },
  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "helix", delay = 300 } },

  -- ════════════════════════════════════════════════════════════
  --  EDITING HELPERS
  -- ════════════════════════════════════════════════════════════
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = { fast_wrap = {}, check_ts = true } },
  { "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },
  { "echasnovski/mini.ai", event = "VeryLazy", opts = { n_lines = 500 } },

  -- ════════════════════════════════════════════════════════════
  --  NVIM-TREE / TELESCOPE / SPECTRE
  -- ════════════════════════════════════════════════════════════
  {
    "nvim-tree/nvim-tree.lua", opts = {
      view = { width = 35, side = "left" },
      renderer = { highlight_git = true, icons = { show = { git = true } }, indent_markers = { enable = true } },
      filters = { dotfiles = false }, git = { enable = true, ignore = false },
    },
  },
  {
    "nvim-telescope/telescope.nvim", opts = {
      defaults = {
        file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/", "__pycache__", "%.lock", "target/", "%.o", "%.a", "%.out" },
        layout_strategy = "horizontal", layout_config = { prompt_position = "top" }, sorting_strategy = "ascending",
      },
    },
    dependencies = { { "nvim-telescope/telescope-fzf-native.nvim", build = "make", config = function() require("telescope").load_extension("fzf") end } },
  },
  { "nvim-pack/nvim-spectre", cmd = "Spectre", keys = { { "<leader>sr", function() require("spectre").toggle() end, desc = "Search & Replace" } }, opts = {} },

  -- ════════════════════════════════════════════════════════════
  --  LANGUAGE EXTRAS
  -- ════════════════════════════════════════════════════════════
  { "rust-lang/rust.vim", ft = "rust", init = function() vim.g.rustfmt_autosave = 1 end },
  { "ray-x/go.nvim", ft = { "go", "gomod" }, dependencies = { "ray-x/guihua.lua" }, opts = {}, build = ':lua require("go.install").update_all_sync()' },
}
