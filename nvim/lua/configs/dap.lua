-- ~/.config/nvim/lua/configs/dap.lua
-- Debug Adapter Protocol configurations

local dap = require("dap")

-- ── Breakpoint appearance ───────────────────────────────────
vim.fn.sign_define("DapBreakpoint",          { text = " ", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = " ", texthl = "DapBreakpointCondition" })
vim.fn.sign_define("DapLogPoint",            { text = " ", texthl = "DapLogPoint" })
vim.fn.sign_define("DapStopped",             { text = "→ ", texthl = "DapStopped", linehl = "DapStoppedLine" })

-- ── Python (debugpy) ────────────────────────────────────────
dap.adapters.python = {
  type    = "executable",
  command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
  args    = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
  {
    type    = "python",
    request = "launch",
    name    = "Launch file",
    program = "${file}",
    cwd     = vim.fn.getcwd(),
    pythonPath = function()
      local venv = os.getenv("VIRTUAL_ENV")
      if venv then return venv .. "/bin/python" end
      return "/usr/bin/python3"
    end,
  },
  {
    type    = "python",
    request = "launch",
    name    = "Launch with arguments",
    program = "${file}",
    args    = function()
      local input = vim.fn.input("Arguments: ")
      return vim.split(input, " ", { trimempty = true })
    end,
  },
}

-- ── Go (delve) ──────────────────────────────────────────────
dap.adapters.delve = {
  type    = "server",
  port    = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/dlv",
    args    = { "dap", "-l", "127.0.0.1:${port}" },
  },
}

dap.configurations.go = {
  {
    type    = "delve",
    name    = "Debug",
    request = "launch",
    program = "${file}",
  },
  {
    type    = "delve",
    name    = "Debug (test)",
    request = "launch",
    mode    = "test",
    program = "${file}",
  },
  {
    type    = "delve",
    name    = "Debug (test function)",
    request = "launch",
    mode    = "test",
    program = "${file}",
    args    = function()
      local name = vim.fn.input("Test name: ")
      return { "-test.run", name }
    end,
  },
}

-- ── C / C++ / Rust (codelldb) ───────────────────────────────
dap.adapters.codelldb = {
  type    = "server",
  port    = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
    args    = { "--port", "${port}" },
  },
}

local codelldb_config = {
  {
    type    = "codelldb",
    request = "launch",
    name    = "Launch executable",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd     = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

dap.configurations.c    = codelldb_config
dap.configurations.cpp  = codelldb_config
dap.configurations.rust = codelldb_config

-- ── JavaScript / TypeScript (js-debug) ──────────────────────
dap.adapters["pwa-node"] = {
  type    = "server",
  host    = "localhost",
  port    = "${port}",
  executable = {
    command = "node",
    args    = {
      vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
      "${port}",
    },
  },
}

local js_config = {
  {
    type    = "pwa-node",
    request = "launch",
    name    = "Launch file",
    program = "${file}",
    cwd     = "${workspaceFolder}",
  },
  {
    type    = "pwa-node",
    request = "attach",
    name    = "Attach to process",
    processId = require("dap.utils").pick_process,
    cwd     = "${workspaceFolder}",
  },
}

dap.configurations.javascript      = js_config
dap.configurations.typescript      = js_config
dap.configurations.javascriptreact = js_config
dap.configurations.typescriptreact = js_config
