local bufnr = vim.api.nvim_get_current_buf()
local opts = { buffer = bufnr, silent = true }

-- Hover actions (rustaceanvim-enhanced, replaces default K)
vim.keymap.set('n', 'K', function() vim.cmd.RustLsp { 'hover', 'actions' } end, opts)

-- Code actions (rust-specific, groups by category)
vim.keymap.set({ 'n', 'v' }, '<leader>ca', function() vim.cmd.RustLsp('codeAction') end, opts)

-- Run / Debug
vim.keymap.set('n', '<leader>rr', function() vim.cmd.RustLsp('runnables') end, opts)
vim.keymap.set('n', '<leader>rd', function() vim.cmd.RustLsp('debuggables') end, opts)
vim.keymap.set('n', '<leader>rt', function() vim.cmd.RustLsp('testables') end, opts)

-- Diagnostics
vim.keymap.set('n', '<leader>re', function() vim.cmd.RustLsp('explainError') end, opts)
vim.keymap.set('n', '<leader>rD', function() vim.cmd.RustLsp('renderDiagnostic') end, opts)

-- Code navigation
vim.keymap.set('n', '<leader>rp', function() vim.cmd.RustLsp('parentModule') end, opts)
vim.keymap.set('n', '<leader>rm', function() vim.cmd.RustLsp('expandMacro') end, opts)
vim.keymap.set('n', '<leader>ro', function() vim.cmd.RustLsp('openDocs') end, opts)
vim.keymap.set('n', '<leader>rc', function() vim.cmd.RustLsp('openCargo') end, opts)

-- Code transformation
vim.keymap.set('n', 'J', function() vim.cmd.RustLsp('joinLines') end, opts)
vim.keymap.set('n', '<leader>ru', function() vim.cmd.RustLsp { 'moveItem', 'up' } end, opts)
vim.keymap.set('n', '<leader>rj', function() vim.cmd.RustLsp { 'moveItem', 'down' } end, opts)
