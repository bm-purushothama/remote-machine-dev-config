-- ~/.config/nvim/lua/configs/cmp.lua
-- Completion engine: LSP + ctags/gtags + clangd + buffer + path + snippets
--
-- Priority order:
--   1. LSP (clangd, pyright, rust-analyzer, etc.)
--   2. Tags (ctags/gtags — works even when LSP is unavailable)
--   3. Snippets
--   4. Buffer words (fallback for any file)
--   5. Path completion

local cmp = require("cmp")
local cmp_ui = require("nvchad.configs.cmp")

-- Icons for completion kinds
local kind_icons = {
  Text          = "󰉿", Method    = "󰆧", Function  = "󰊕",
  Constructor   = "", Field     = "󰜢", Variable  = "󰀫",
  Class         = "󰠱", Interface = "", Module    = "",
  Property      = "󰜢", Unit      = "󰑭", Value     = "󰎠",
  Enum          = "", Keyword   = "󰌋", Snippet   = "",
  Color         = "󰏘", File      = "󰈙", Reference = "󰈇",
  Folder        = "󰉋", EnumMember = "", Constant = "󰏿",
  Struct        = "󰙅", Event     = "", Operator  = "󰆕",
  TypeParameter = "",
}

-- Source labels for the completion menu
local source_labels = {
  nvim_lsp = "[LSP]",
  tags     = "[TAG]",
  luasnip  = "[SNP]",
  buffer   = "[BUF]",
  path     = "[PTH]",
  cmdline  = "[CMD]",
  nvim_lsp_signature_help = "[SIG]",
}

cmp.setup({
  -- ── Snippet engine ────────────────────────────────────────
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },

  -- ── Window appearance ─────────────────────────────────────
  window = {
    completion = cmp.config.window.bordered({
      border = "rounded",
      winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:None",
      scrollbar = true,
    }),
    documentation = cmp.config.window.bordered({
      border = "rounded",
      winhighlight = "Normal:CmpDoc",
    }),
  },

  -- ── Key mappings ──────────────────────────────────────────
  mapping = cmp.mapping.preset.insert({
    -- Navigate completion items
    ["<C-p>"]     = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    ["<C-n>"]     = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),

    -- Scroll docs
    ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
    ["<C-f>"]     = cmp.mapping.scroll_docs(4),

    -- Trigger completion manually
    ["<C-Space>"] = cmp.mapping.complete(),

    -- Cancel
    ["<C-e>"]     = cmp.mapping.abort(),

    -- Confirm selection
    ["<CR>"]      = cmp.mapping.confirm({ select = false }),  -- Only confirm explicit selection

    -- Tab: complete or jump in snippet
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        require("luasnip").expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require("luasnip").jumpable(-1) then
        require("luasnip").jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),

  -- ── Sources (priority order) ──────────────────────────────
  sources = cmp.config.sources({
    -- Group 1: High-priority (shown first)
    { name = "nvim_lsp",                priority = 1000 },  -- LSP (clangd, pyright, etc.)
    { name = "nvim_lsp_signature_help", priority = 900 },   -- Function signatures
    { name = "tags",                    priority = 800,      -- ctags/gtags
      option = {
        -- Only trigger after 2 chars to avoid noise
        keyword_length = 2,
      },
    },
    { name = "luasnip",                 priority = 700 },   -- Snippets
  }, {
    -- Group 2: Fallback (shown if Group 1 has no results)
    { name = "buffer",
      priority = 500,
      keyword_length = 3,
      option = {
        -- Index all visible buffers (not just current)
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
          return vim.tbl_keys(bufs)
        end,
      },
    },
    { name = "path", priority = 400 },
  }),

  -- ── Formatting ────────────────────────────────────────────
  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = function(entry, vim_item)
      -- Icon
      vim_item.kind = (kind_icons[vim_item.kind] or "") .. " " .. vim_item.kind

      -- Source label
      vim_item.menu = source_labels[entry.source.name] or ("[" .. entry.source.name .. "]")

      -- Truncate long items
      local max_width = 50
      if #vim_item.abbr > max_width then
        vim_item.abbr = vim_item.abbr:sub(1, max_width) .. "…"
      end

      return vim_item
    end,
  },

  -- ── Sorting ───────────────────────────────────────────────
  sorting = {
    priority_weight = 2,
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      -- Deprioritize text/snippet when LSP results exist
      function(entry1, entry2)
        local kind1 = entry1:get_kind()
        local kind2 = entry2:get_kind()
        -- Text kind = 1, deprioritize it
        if kind1 == 1 and kind2 ~= 1 then return false end
        if kind1 ~= 1 and kind2 == 1 then return true end
        return nil
      end,
      cmp.config.compare.recently_used,
      cmp.config.compare.locality,
      cmp.config.compare.kind,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },

  -- ── Performance ───────────────────────────────────────────
  performance = {
    debounce        = 60,     -- ms before triggering completion
    throttle        = 30,     -- ms between filtering updates
    fetching_timeout = 500,   -- ms timeout for slow sources
    max_view_entries = 30,    -- Max items shown at once
  },

  -- ── Experimental ──────────────────────────────────────────
  experimental = {
    ghost_text = true,        -- Inline preview of top suggestion
  },
})

-- ── Cmdline completion ──────────────────────────────────────
-- / and ? search
cmp.setup.cmdline({ "/", "?" }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = { { name = "buffer" } },
})

-- : command line
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources(
    { { name = "path" } },
    { { name = "cmdline" } }
  ),
  matching = { disallow_symbol_nonprefix_matching = false },
})

-- ── C/C++ specific: boost clangd results ────────────────────
-- clangd provides the best C/C++ completion via LSP, but we
-- also keep tags as fallback for when clangd is indexing
cmp.setup.filetype({ "c", "cpp", "objc", "objcpp" }, {
  sources = cmp.config.sources({
    { name = "nvim_lsp", priority = 1000 },  -- clangd
    { name = "nvim_lsp_signature_help", priority = 900 },
    { name = "tags",     priority = 600,     -- ctags fallback
      keyword_length = 3,
    },
    { name = "luasnip",  priority = 500 },
  }, {
    { name = "buffer", keyword_length = 4 },
    { name = "path" },
  }),
})
