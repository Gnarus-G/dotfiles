-- some extra mcp servers to reinstall:
-- web_search: https://github.com/ihor-sokoliuk/mcp-searxng, https://github.com/Gnarus-G/ez-web-search-mcp



---@type MCPHub
local mcphub = require("mcphub");
mcphub.setup({
  port = 37373,                                            -- Default port for MCP Hub
  config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Absolute path to config file location (will create if not exists)
  native_servers = {},                                     -- add your native servers here

  auto_approve = true,                                     -- Auto approve mcp tool calls
  -- Extensions configuration
  extensions = {
    avante = {
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
  shutdown_delay = 600000,
  auto_toggle_mcp_servers = true,
  mcp_request_timeout = 60000
})

local plugins_dir = vim.fn.stdpath("data") .. "/site/pack/packer/start/"
vim.iter(vim.fn.readdir(plugins_dir))
    :each(function(name)
      local path = plugins_dir .. name
      mcphub.add_resource("nvim", {
        name        = name,
        mimeType    = "application/json",
        description = "Path to the source code of the installed neovim plugin",
        uri         = "nvim://plugin/" .. name,
        handler     = function(_req, res)
          local data = {
            name = name,
            path = path,
            is_dir = vim.fn.isdirectory(path) == 1,
          }
          res:text(vim.json.encode(data)):send()
        end
      })
    end)

mcphub.add_resource("minuet", {
  name = "minuet_ctx",
  description = "content files minuet is using",
  uri = "nvim://minuet_ctx",
  handler = function(_req, res)
    local minuet = require("minuet_ctx")
    local file_paths = minuet.files()
    res:text(vim.json.encode(file_paths))
        :send()
  end
})

mcphub.add_resource("git", {
  name = "unstaged",
  description = "list of files not staged for commit in current git repository",
  uri = "git://unstaged",
  mimeType = "application/json",
  handler = function(_req, res)
    local ok, output = pcall(vim.fn.system, "git status --porcelain")
    if not ok then
      res:error("Failed to get unstaged files", {
        error = output
      })
      return
    end
    local unstaged_files = {}
    for line in string.gmatch(output, "[^\r\n]+") do
      local status = string.sub(line, 1, 2)
      local file = string.sub(line, 4)
      if status:match("^ [MADRCU?]") or status:match("^[MADRCU?] ") then
        table.insert(unstaged_files, file)
      end
    end
    res:text(vim.json.encode(unstaged_files)):send()
  end
})

mcphub.add_prompt("nani?", {
  name = "dafuq",
  description = "Explain why this error is happening",
  arguments = { {
    name = "error",
    description = "Error message",
    type = "string",
    required = true,
  } },
  handler = function(req, res)
    res:system()
        :resource({
          uri = "neovim://buffer",
          mimeType = "text/plain"
        })
        :resource({
          uri = "git://unstaged",
          mimeType = "application/json"
        })
        :user()
        :text("Explain why this error is happening in great detail: \n```txt\n" .. req.params.error .. "\n```")
        :send()
  end
})

mcphub.add_prompt("refactor", {
  name = "translate",
  description = "Refactor by translating one pattern/library to another",
  arguments = { {
    name = "prompt",
    description = "Details about the desired refactor",
    type = "string",
    required = true,
  } },
  handler = function(req, res)
    res
        :system()
        :resource({
          uri = "neovim://buffer",
          mimeType = "text/plain"
        })
        :user()
        :text("Refactor code according to following details: \n---\n" .. req.params.prompt .. "\n---")
        :system()
        :text("Do not add uncessary comments, especially ones that don't add new information to the code.")
        :user()
        :text("Reference any docs if necessary through the `Context7` mcp server tools")

    return res:send()
  end
})

require "mcphub_servers.todo_server"
