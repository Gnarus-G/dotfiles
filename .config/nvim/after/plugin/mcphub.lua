require("mcphub").setup({
  port = 37373,                                            -- Default port for MCP Hub
  config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Absolute path to config file location (will create if not exists)
  native_servers = {},                                     -- add your native servers here

  auto_approve = false,                                    -- Auto approve mcp tool calls
  -- Extensions configuration
  extensions = {
    avante = {
      make_slash_commands = true, -- make /slash commands from MCP server prompts
    },
    codecompanion = {
      -- Show the mcp tool result in the chat buffer
      -- NOTE:if the result is markdown with headers, content after the headers wont be sent by codecompanion
      show_result_in_chat = false,
      make_vars = true,           -- make chat #variables from MCP server resources
      make_slash_commands = true, -- make /slash commands from MCP server prompts
    },
  },

  -- Default window settings
  ui = {
    window = {
      width = 0.8,  -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
      height = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
      relative = "editor",
      zindex = 50,
      border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
    },
    wo = {                -- window-scoped options (vim.wo)
    },
  },

  -- Event callbacks
  on_ready = function(hub)
    -- Called when hub is ready
  end,
  on_error = function(err)
    -- Called on errors
  end,

  --set this to true when using build = "bundled_build.lua"
  use_bundled_binary = false, -- Uses bundled mcp-hub script instead of global installation

  --WARN: Use the custom setup if you can't use `npm install -g mcp-hub` or cant have `build = "bundled_build.lua"`
  -- Custom Server command configuration
  --cmd = "node", -- The command to invoke the MCP Hub Server
  --cmdArgs = {"/path/to/node_modules/mcp-hub/dist/cli.js"},    -- Additional arguments for the command
  -- In cases where mcp-hub server is hosted somewhere, set this to the server URL e.g `http://mydomain.com:customport` or `https://url_without_need_for_port.com`
  -- server_url = nil, -- defaults to `http://localhost:port`

  -- Logging configuration
  log = {
    level = vim.log.levels.WARN,
    to_file = false,
    file_path = nil,
    prefix = "MCPHub",
  },
})
