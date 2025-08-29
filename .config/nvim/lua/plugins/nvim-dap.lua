return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-dap.nvim",
      "nvim-neotest/nvim-nio",

      'mfussenegger/nvim-dap-python' -- for python
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      local dap_utils = require('dap.utils')

      require("dap-python").setup("uv")
      require("telescope").load_extension("dap")

      local function string_split(inputstr, sep)
        if sep == nil then
          sep = "%s"
        end
        local t = {}
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
          table.insert(t, str)
        end
        return t
      end

      -- Keymaps
      vim.keymap.set("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<cr>")
      vim.keymap.set("n", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>")
      vim.keymap.set("n", "<leader>k", ":lua require'dapui'.eval()<cr>")
      vim.keymap.set("n", "<F5>", ":lua require'dap'.continue()<cr>")
      vim.keymap.set("n", "<F10>", ":lua require'dap'.step_over()<cr>")
      vim.keymap.set("n", "<F11>", ":lua require'dap'.step_into()<cr>")

      -- Adapters
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

      dap.adapters.codelldb = {
        type = "executable",
        command = "codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"
      }

      -- Configurations
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
        processId = dap_utils.pick_process,
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

      ---@class dap.Adapter
      local launch_exe_debugger = {
        name = "Launch executable file",
        -- if codelldb is not available, use gdb
        type = vim.fn.executable("codelldb") == 1 and "codelldb" or "gdb",
        request = "launch",
        program = function()
          return dap_utils.pick_file({ executables = true, })
        end,
        args = function()
          local co = coroutine.running()
          vim.ui.input({ prompt = "Args: ", completion = "arglist" }, vim.schedule_wrap(function(input)
            coroutine.resume(co, string_split(input))
          end))
          local args_sequence = coroutine.yield()
          return args_sequence
        end,
        cwd = '${workspaceFolder}',
      }

      ---@class dap.Adapter
      local attach_exe_debugger = {
        name = "Select and attach to process",
        type = "codelldb",
        request = "attach", -- if attach isn't working, try: https://askubuntu.com/questions/41629/after-upgrade-gdb-wont-attach-to-process
        pid = function()
          return dap_utils.pick_process()
        end,
        cwd = '${workspaceFolder}',
      }

      dap.configurations.cpp = {
        launch_exe_debugger,
        attach_exe_debugger,
      }
      dap.configurations.c = {
        launch_exe_debugger,
        attach_exe_debugger,
      }
      dap.configurations.rust = {
        launch_exe_debugger,
        attach_exe_debugger,
      }
      dap.configurations.asm = {
        launch_exe_debugger,
        attach_exe_debugger,
      }

      -- DAP UI Configuration
      local configs = {
        layouts = {
          {
            -- You can change the order of elements in the sidebar
            elements = {
              -- Provide IDs as strings or tables with "id" and "size" keys
              {
                id = "scopes",
                size = 0.45, -- Can be float or integer > 1
              },
              { id = "breakpoints", size = 0.15 },
              { id = "stacks",      size = 0.25 },
              { id = "watches",     size = 0.15 },
            },
            size = 50,
            position = "left", -- Can be "left" or "right"
          },
          {
            elements = {
              "repl",
              "console",
            },
            size = 10,
            position = "bottom", -- Can be "bottom" or "top"
          },
        },
      }

      dapui.setup(configs)

      -- DAP UI Listeners
      dap.listeners.after.event_initialized["dapui_listener"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_listener"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_listener"] = function()
        dapui.close({})
      end

      -- Highlights
      vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#993939', bg = '#31353f' })
      vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#61afef', bg = '#31353f' })
      vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#98c379', bg = '#31353f' })

      -- Signs
      vim.fn.sign_define('DapBreakpoint', { text = '🛑', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
      vim.fn.sign_define('DapBreakpointCondition',
        { text = 'ﳁ', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
      vim.fn.sign_define('DapBreakpointRejected',
        { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
      vim.fn.sign_define('DapLogPoint',
        { text = '', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
      vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })

      -- Virtual Text Setup
      require("nvim-dap-virtual-text").setup({
        enabled = true,                     -- enable this plugin (the default)
        enable_commands = true,             -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
        highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
        highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
        show_stop_reason = true,            -- show stop reason when stopped for exceptions
        commented = false,                  -- prefix virtual text with comment string
        only_first_definition = true,       -- only show virtual text at first definition (if there are multiple)
        all_references = false,             -- show virtual text on all all references of the variable (not only definitions)
        clear_on_continue = false,          -- clear virtual text on "continue" (might cause flickering when stepping)
        text_prefix = " ",                  -- Prefix for the virtual text
        separator = " = ",                  -- Separator between variable name and value
        error_prefix = "Error: ",           -- Prefix for error messages
        info_prefix = "Info: ",             -- Prefix for info messages
        virt_lines_above = 0,               -- Number of virtual lines to show above the current line
        filter_references_pattern = nil,    -- Pattern to filter references
        --- A callback that determines how a variable is displayed or whether it should be omitted
        --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
        --- @param buf number
        --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
        --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
        --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
        --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
        display_callback = function(variable, buf, stackframe, node, options)
          -- by default, strip out new line characters
          if options.virt_text_pos == 'inline' then
            return ' = ' .. variable.value:gsub("%s+", " ")
          else
            return variable.name .. ' = ' .. variable.value:gsub("%s+", " ")
          end
        end,
        -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
        virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',

        -- experimental features:
        all_frames = false,     -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
        virt_lines = false,     -- show virtual lines instead of virtual text (will flicker!)
        virt_text_win_col = nil -- position the virtual text at a fixed window column (starting from the first text column) ,
        -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
      })

      -- Custom command
      local function refresh_dapui_layout()
        dapui.close({})
        dapui.setup(configs)
        dapui.open({})
      end

      vim.api.nvim_create_user_command('DapUIRefresh', refresh_dapui_layout, { desc = "Refresh DAP UI Layout" })
    end,
  },
}
