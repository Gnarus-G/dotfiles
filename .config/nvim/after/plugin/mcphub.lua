-- some extra mcp servers to reinstall:
-- web_search: https://github.com/ihor-sokoliuk/mcp-searxng, https://github.com/Gnarus-G/ez-web-search-mcp



---@type MCPHub
local mcphub = require("mcphub");
mcphub.setup({
  --- `mcp-hub` binary related options-------------------
  config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Absolute path to MCP Servers config file (will create if not exists)
  port = 37373,                                            -- The port `mcp-hub` server listens to
  shutdown_delay = 60 * 10 * 000,                          -- Delay in ms before shutting down the server when last instance closes (default: 10 minutes)
  use_bundled_binary = false,                              -- Use local `mcp-hub` binary (set this to true when using build = "bundled_build.lua")
  mcp_request_timeout = 60000,                             --Max time allowed for a MCP tool or resource to execute in milliseconds, set longer for long running tasks

  ---Chat-plugin related options-----------------
  auto_approve = false,           -- Auto approve mcp tool calls
  auto_toggle_mcp_servers = true, -- Let LLMs start and stop MCP servers automatically

  --- Plugin specific options-------------------
  native_servers = {}, -- add your custom lua native servers here
  ui = {
    window = {
      width = 0.8,      -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
      height = 0.8,     -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
      align = "center", -- "center", "top-left", "top-right", "bottom-left", "bottom-right", "top", "bottom", "left", "right"
      relative = "editor",
      zindex = 50,
      border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
    },
    wo = {                -- window-scoped options (vim.wo)
      winhl = "Normal:MCPHubNormal,FloatBorder:MCPHubBorder",
    },
  },
  on_ready = function(hub)
    -- Called when hub is ready
  end,
  on_error = function(err)
    -- Called on errors
  end,
  log = {
    level = vim.log.levels.WARN,
    to_file = false,
    file_path = nil,
    prefix = "MCPHub",
  },
  builtin_tools = {
    edit_file = {
      parser = {
        track_issues = true,           -- Track parsing issues for LLM feedback
        extract_inline_content = true, -- Handle content on marker lines
      },
      locator = {
        fuzzy_threshold = 0.8,        -- Minimum similarity for fuzzy matches (0.0-1.0)
        enable_fuzzy_matching = true, -- Allow fuzzy matching when exact fails
      },
      ui = {
        go_to_origin_on_complete = true, -- Jump back to original file on completion
        keybindings = {
          accept = ".",                  -- Accept current change
          reject = ",",                  -- Reject current change
          next = "n",                    -- Next diff
          prev = "p",                    -- Previous diff
          accept_all = "ga",             -- Accept all remaining changes
          reject_all = "gr",             -- Reject all remaining changes
        },
      },
      feedback = {
        include_parser_feedback = true,                       -- Include parsing feedback for LLM
        include_locator_feedback = true,                      -- Include location feedback for LLM
        include_ui_summary = true,                            -- Include UI interaction summary
        ui = {
          include_session_summary = true,                     -- Include session summary in feedback
          include_final_diff = true,                          -- Include final diff in feedback
          send_diagnostics = true,                            -- Include diagnostics after editing
          wait_for_diagnostics = 500,                         -- Wait time for diagnostics (ms)
          diagnostic_severity = vim.diagnostic.severity.WARN, -- Min severity to include
        },
      },
    },
  },
})

local plugins_dir = vim.fn.stdpath("data") .. "/site/pack/packer/start/"
vim.iter(vim.fn.readdir(plugins_dir))
    :each(function(name)
      local path = plugins_dir .. name
      mcphub.add_resource("gnarus", {
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

mcphub.add_resource("gnarus", {
  name        = "minuet_ctx",
  description = "content files minuet is using",
  uri         = "nvim://minuet_ctx",
  mimeType    = "application/json",
  handler     = function(_req, res)
    local minuet = require("minuet_ctx")
    local file_paths = minuet.files()
    res:text(vim.json.encode(file_paths))
        :send()
  end
})

mcphub.add_resource("gnarus", {
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

mcphub.add_prompt("gnarus", {
  name = "dafuq?",
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

mcphub.add_prompt("gnarus", {
  name = "refactor",
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
        :system()
        :text("You are an expert software engineer specializing in refactoring and code transformation.")
        :text(
          "Your goal is to assist the user in refactoring the provided code by translating patterns or libraries as requested.")
        :text(
          "You have access to a variety of tools and resources provided by connected MCP servers. You should leverage these tools, especially for searching documentation (e.g., via 'github.com/upstash/context7-mcp' for library documentation) or performing web searches (e.g., via 'ez-web-search-mcp'), to gather necessary information before making changes.")
        :text(
          "Always ensure your refactored code is complete and directly usable as a replacement. Avoid adding redundant comments or explanations that do not contribute new information to the code.")
        :user()
        :text("Refactor code according to following details: \n---\n" ..
          req.params.prompt .. "\n---")

    return res:send()
  end
})

mcphub.add_prompt("gnarus", {
  name = "PR-summary",
  description = "Create a summary of PR with the changes in the current branch",
  handler = function(_, res)
    local ok, diff_output = pcall(vim.fn.system, "git fetch --prune --all && git diff origin/main")
    if not ok then
      res:error("Failed to get git diff", { error = diff_output })
      return
    end

    res:system()
        :text(
          "You are an expert software engineer responsible for generating concise and informative pull request summaries.")
        :text(
          "Your goal is to summarize the provided git diff into a clear and comprehensive pull request description. Focus on the main changes, their purpose, and any significant impacts.")
        :user()
        :text("Create a PR summary based on the following git diff:\n```diff\n" .. diff_output .. "\n```")

    return res:send()
  end
})

require "mcphub_servers.todo_server"
