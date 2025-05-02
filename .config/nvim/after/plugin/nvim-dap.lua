local dap, dapui = require 'dap', require 'dapui'

vim.keymap.set("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<cr>")
vim.keymap.set("n", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>")
vim.keymap.set("n", "<leader>k", ":lua require'dapui'.eval()<cr>")
vim.keymap.set("n", "<F5>", ":lua require'dap'.continue()<cr>")
vim.keymap.set("n", "<F10>", ":lua require'dap'.step_over()<cr>")
vim.keymap.set("n", "<F11>", ":lua require'dap'.step_into()<cr>")

dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = { os.getenv('HOME') .. '/dev/microsoft/vscode-node-debug2/out/src/nodeDebug.js' },
}

dap.adapters.chrome = {
  type = "executable",
  command = "node",
  args = { os.getenv("HOME") .. "/dev/microsoft/vscode-chrome-debug/out/src/chromeDebug.js" }
}

dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
}

local node_launcher = {
  name = 'Launch',
  type = 'node2',
  request = 'launch',
  program = '${file}',
  cwd = vim.fn.getcwd(),
  sourceMaps = true,
  protocol = 'inspector',
  console = 'integratedTerminal',
}

local node_jest_launcher = {
  name = 'Debug Jest Tests',
  type = 'node2',
  request = 'launch',
  program = '${file}',
  cwd = vim.fn.getcwd(),
  runtimeExecutable = "node",
  runtimeArgs = {
    "--inspect-brk",
    vim.fn.getcwd() .. "/node_modules/jest/bin/jest.js",
    "--runInBand",
    "--watch",
    "--coverage",
    "false"
  },
  port = 9229,
  sourceMaps = true,
  protocol = 'inspector',
  console = 'integratedTerminal',
  internalConsoleOptions = "neverOpen",
}

local node_attach = {
  -- For this to work you need to make sure the node process is started with the `--inspect` flag.
  name = 'Attach to process',
  type = 'node2',
  request = 'attach',
  processId = require 'dap.utils'.pick_process,
  cwd = vim.fn.getcwd(),
  sourceMaps = true,
  resolveSourceMapLocations = { "${workspaceFolder}/**",
    "!**/node_modules/**" },
  skipFiles = { "${workspaceFolder}/node_modules/**/*.js" },
}

local chrome_attach = {
  type = "chrome",
  request = "attach",
  program = "${file}",
  cwd = vim.fn.getcwd(),
  sourceMaps = true,
  protocol = "inspector",
  port = 9222,
  webRoot = vim.fn.getcwd()
}

dap.configurations.javascript = {
  node_launcher,
  node_jest_launcher,
  node_attach,
}

dap.configurations.javascriptreact = {
  chrome_attach
}

dap.configurations.typescript = {
  node_attach,
}

dap.configurations.typescriptreact = {
  chrome_attach
}

dap.configurations.svelte = {
  chrome_attach
}

local launch_c_debugger = {
  name = "Launch file",
  type = "gdb",
  request = "launch",
  program = function()
    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
  end,
  args = function()
    local function mysplit(inputstr, sep)
      if sep == nil then
        sep = "%s"
      end
      local t = {}
      for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
      end
      return t
    end

    local args = vim.fn.input('Args: ')
    local args_sequence = mysplit(args)

    return args_sequence
  end,
  cwd = '${workspaceFolder}',
  stopOnEntry = false,
}

dap.configurations.cpp = {
  launch_c_debugger
}
dap.configurations.c = {
  launch_c_debugger
}
dap.configurations.rust = {
  launch_c_debugger,
}
dap.configurations.asm = {
  launch_c_debugger,
}

dapui.setup();

dap.listeners.after.event_initialized["dapui_listener"] = function()
  dapui.open({})
end
dap.listeners.before.event_terminated["dapui_listener"] = function()
  dapui.close({})
end
dap.listeners.before.event_exited["dapui_listener"] = function()
  dapui.close({})
end

vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#993939', bg = '#31353f' })
vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#61afef', bg = '#31353f' })
vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#98c379', bg = '#31353f' })

vim.fn.sign_define('DapBreakpoint', { text = '🛑', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
--[[ vim.fn.sign_define('DapBreakpoint', ]]
--[[   { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' }) ]]
vim.fn.sign_define('DapBreakpointCondition',
  { text = 'ﳁ', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
vim.fn.sign_define('DapBreakpointRejected',
  { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })

require("nvim-dap-virtual-text").setup({})
