-- ~/.config/nvim/lua/configs/lspconfig.lua
-- Per-server LSP configuration

local on_attach    = require("nvchad.configs.lspconfig").on_attach
local on_init      = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities
local lspconfig    = require("lspconfig")

-- ── Diagnostic appearance ───────────────────────────────────
vim.diagnostic.config({
  virtual_text     = { prefix = "●", spacing = 4 },
  signs            = true,
  underline        = true,
  update_in_insert = false,
  severity_sort    = true,
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})

local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- ── Default-config servers (just attach & go) ───────────────
local default_servers = {
  "html",
  "cssls",
  "tailwindcss",
  "jsonls",
  "yamlls",
  "bashls",
  "dockerls",
  "terraformls",
  "clangd",
}

for _, server in ipairs(default_servers) do
  lspconfig[server].setup({
    on_attach    = on_attach,
    on_init      = on_init,
    capabilities = capabilities,
  })
end

-- ── TypeScript ──────────────────────────────────────────────
lspconfig.ts_ls.setup({
  on_attach    = on_attach,
  on_init      = on_init,
  capabilities = capabilities,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionParameterTypeHints = true,
      },
    },
  },
})

-- ── Python (Pyright) ────────────────────────────────────────
lspconfig.pyright.setup({
  on_attach    = on_attach,
  on_init      = on_init,
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        typeCheckingMode    = "basic",
        autoSearchPaths     = true,
        useLibraryCodeForTypes = true,
        diagnosticMode      = "openFilesOnly",
        autoImportCompletions = true,
      },
    },
  },
})

-- ── Rust Analyzer ───────────────────────────────────────────
lspconfig.rust_analyzer.setup({
  on_attach    = on_attach,
  on_init      = on_init,
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
      },
      checkOnSave = { command = "clippy" },
      procMacro   = { enable = true },
      inlayHints  = {
        bindingModeHints     = { enable = true },
        closureReturnTypeHints = { enable = "always" },
        lifetimeElisionHints = { enable = "always" },
      },
    },
  },
})

-- ── Go (gopls) ──────────────────────────────────────────────
lspconfig.gopls.setup({
  on_attach    = on_attach,
  on_init      = on_init,
  capabilities = capabilities,
  settings = {
    gopls = {
      gofumpt    = true,
      analyses   = {
        unusedparams = true,
        shadow       = true,
        nilness      = true,
        unusedwrite  = true,
        useany       = true,
      },
      staticcheck = true,
      hints = {
        assignVariableTypes    = true,
        compositeLiteralFields = true,
        constantValues         = true,
        functionTypeParameters = true,
        parameterNames         = true,
        rangeVariableTypes     = true,
      },
    },
  },
})

-- ── Lua ─────────────────────────────────────────────────────
lspconfig.lua_ls.setup({
  on_attach    = on_attach,
  on_init      = on_init,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime     = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace   = {
        library = {
          vim.fn.expand("$VIMRUNTIME/lua"),
          vim.fn.stdpath("data") .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
        },
        maxPreload    = 100000,
        preloadFileSize = 10000,
      },
      telemetry = { enable = false },
      hint      = { enable = true },
    },
  },
})
