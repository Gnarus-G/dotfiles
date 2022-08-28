local map = require 'gnarus.keymap'.map;
local dap, dapui = require 'dap', require 'dapui'

local extend = function(t, e)
  return vim.tbl_deep_extend("force", t, e)
end

map("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<cr>")
map("n", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>")
map("n", "<leader>k", ":lua require'dapui'.eval()<cr>")
map("n", "<F5>", ":lua require'dap'.continue()<cr>")
map("n", "<F10>", ":lua require'dap'.step_over()<cr>")
map("n", "<F11>", ":lua require'dap'.step_into()<cr>")

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

local ts_specific_configs = {
  outFiles = { vim.fn.getcwd() .. "/dist/**/*.js", vim.fn.getcwd() .. "/build/**/*.js" }
}

dap.configurations.typescript = {
  extend(node_launcher, ts_specific_configs),
  extend(node_jest_launcher, ts_specific_configs),
  node_attach,
}

dap.configurations.typescriptreact = {
  chrome_attach
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

vim.highlight.create('DapBreakpoint', { ctermbg = 0, guifg = '#993939', guibg = '#31353f' }, false)
vim.highlight.create('DapLogPoint', { ctermbg = 0, guifg = '#61afef', guibg = '#31353f' }, false)
vim.highlight.create('DapStopped', { ctermbg = 0, guifg = '#98c379', guibg = '#31353f' }, false)

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
