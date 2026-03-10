-- ~/.config/nvim/lua/configs/lspconfig.lua
-- LSP configuration using vim.lsp.config (Neovim 0.11+)

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

-- ── Shared capabilities (nvim-cmp integration) ─────────────
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
end

-- ── Shared on_attach ────────────────────────────────────────
local on_attach = function(client, bufnr)
  -- Enable navic breadcrumbs if supported
  local ok_navic, navic = pcall(require, "nvim-navic")
  if ok_navic and client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end
end

-- ── Wildcard: default config for ALL servers ────────────────
vim.lsp.config("*", {
  capabilities = capabilities,
  on_attach = on_attach,
})

-- ── Default-config servers (just enable, no special settings)
vim.lsp.config("html", {})
vim.lsp.config("cssls", {})
vim.lsp.config("tailwindcss", {})
vim.lsp.config("jsonls", {})
vim.lsp.config("yamlls", {})
vim.lsp.config("bashls", {})
vim.lsp.config("dockerls", {})
vim.lsp.config("terraformls", {})
vim.lsp.config("clangd", {})

-- ── TypeScript ──────────────────────────────────────────────
vim.lsp.config("ts_ls", {
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
vim.lsp.config("pyright", {
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
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
      },
      checkOnSave = { command = "clippy" },
      procMacro   = { enable = true },
      inlayHints  = {
        bindingModeHints       = { enable = true },
        closureReturnTypeHints = { enable = "always" },
        lifetimeElisionHints   = { enable = "always" },
      },
    },
  },
})

-- ── Go (gopls) ──────────────────────────────────────────────
vim.lsp.config("gopls", {
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
vim.lsp.config("lua_ls", {
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
        maxPreload      = 100000,
        preloadFileSize = 10000,
      },
      telemetry = { enable = false },
      hint      = { enable = true },
    },
  },
})

-- ── Enable all configured servers ───────────────────────────
vim.lsp.enable({
  "html",
  "cssls",
  "tailwindcss",
  "jsonls",
  "yamlls",
  "bashls",
  "dockerls",
  "terraformls",
  "clangd",
  "ts_ls",
  "pyright",
  "rust_analyzer",
  "gopls",
  "lua_ls",
})
