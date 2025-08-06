---@param mcphub MCPHub
local function add_prompts_and_resources(mcphub)
  -- Add plugin resources
  local plugins_dir = vim.fn.stdpath("data") .. "/lazy/"
  if vim.fn.isdirectory(plugins_dir) == 1 then
    vim.iter(vim.fn.readdir(plugins_dir))
        :each(function(name)
          local path = plugins_dir .. name
          mcphub.add_resource("gnarus", {
            name        = name,
            mimeType    = "application/json",
            description = "Path to the source code of the installed neovim plugin",
            uri         = "nvim://plugin/" .. name,
            handler     = function(_, res)
              local data = {
                name = name,
                path = path,
                is_dir = vim.fn.isdirectory(path) == 1,
              }
              res:text(vim.json.encode(data)):send()
            end
          })
        end)
  end

  mcphub.add_resource("gnarus", {
    name = "fp-guide",
    description = "A Markdown document outlining principles and guidelines for functional programming.",
    uri = "guide://fp/guidelines-prompt",
    mimeType = "text/markdown",
    handler = function(_, res)
      local r, err = require("gnarus.utils").read_fp_guide_system_prompt_file()
      if not r then
        return res:error("Failed to read FP guide system prompt file", { error = err }):send()
      end
      local content = r[2]
      res:text(content, "text/markdown"):send()
    end
  })

  mcphub.add_resource("gnarus", {
    name        = "minuet_ctx",
    description = "content files minuet is using",
    uri         = "nvim://minuet_ctx",
    mimeType    = "application/json",
    handler     = function(_, res)
      local minuet = require("minuet_ctx")
      local file_paths = minuet.files()
      res:text(vim.json.encode(file_paths))
          :send()
    end
  })

  mcphub.add_prompt("gnarus", {
    name = "use_functional_programming",
    description = "This prompt provides a system-level instruction to enforce functional programming principles.",
    handler = function(_, res)
      local r, err = require("gnarus.utils").read_fp_guide_system_prompt_file()
      if not r then
        return res:error("Failed to read FP guide system prompt file", { error = err }):send()
      end
      local prompt, fp_guide_content = r[1], r[2]
      res:system()
          :text(prompt ..
            "\nAll your responses must adhere strictly to the functional programming principles provided above. " ..
            "Prioritize pure functions, immutability, and declarative transformations. Avoid side effects. " ..
            "Ensure that any code examples provided are idiomatic Rust and demonstrate these principles clearly. " ..
            "If I ask for something that contradicts FP principles, gently guide me back to the correct approach.")
          :text("<guide>" .. fp_guide_content .. "</guide>")
          :send()
    end
  })

  mcphub.add_resource("gnarus", {
    name = "working-files",
    description = "list of files not yet committed in current git repository, excluding untracked files.",
    uri = "git://status",
    mimeType = "application/json",
    handler = function(_, res)
      local files, err = require "gnarus.utils".git_modified_or_added_files()
      if err then
        res:error("Failed to get unstaged files", {
          error = err
        })
        return
      end
      res:text(vim.json.encode(files)):send()
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

  mcphub.add_resource("gnarus", {
    name        = "branch-diff",
    description = "Git diff between current branch and origin/main",
    uri         = "git://branch-diff",
    mimeType    = "text/plain",
    handler     = function(_, res)
      local ok, diff_output = pcall(vim.fn.system,
        "git fetch --prune --all && git diff $(git merge-base origin/main HEAD)")
      if not ok then
        res:error("Failed to get git diff", { error = diff_output })
        return
      end
      res:text(diff_output):send()
    end
  })

  mcphub.add_prompt("gnarus", {
    name = "PR-summary",
    description = "Create a summary of PR with the changes in the current branch",
    handler = function(_, res)
      local ok, diff_output = pcall(vim.fn.system,
        "git fetch --prune --all && git diff $(git merge-base origin/main HEAD)")
      if not ok then
        res:error("Failed to get git diff", { error = diff_output })
        return
      end

      return res:system()
          :text(
            "You are an expert software engineer responsible for generating concise and informative pull request summaries.")
          :text(
            "Your goal is to summarize the provided git diff into a clear and comprehensive pull request description. Focus on the main changes, their purpose, and any significant impacts.")
          :user()
          :text("Create a PR summary based on the following git diff:\n```diff\n" .. diff_output .. "\n```")

          :send()
    end
  })

  mcphub.add_prompt("gnarus", {
    name = "git-commit-summary",
    description = "Genearate a commit message based on the changes against the provided git branch.",
    arguments = function()
      -- Get git branches
      local branches = vim.fn.systemlist("git branch --all --format='%(refname:short)'")
      local current_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD")
      current_branch = vim.trim(current_branch)
      return {
        {
          name = "branch",
          description = "Target branch (defaults to the current one)",
          default = current_branch,
          enum = branches
        }
      }
    end,
    handler = function(req, res)
      local ok, diff_output = pcall(vim.fn.system, "git fetch --prune --all && git diff --staged " .. req.params.branch);
      if not ok then
        return res:error("Failed to get git diff", { error = diff_output })
      end

      if vim.fn.empty(diff_output) == 1 then
        return res:error("There are no staged changes in the git repo")
      end

      return res
          :system()
          :text(
            "You are a knowledgeable and experienced software developer. Your task is to provide helpful and accurate information about Git commit messages. " ..
            "The subject line of a commit should be 50 characters max, and should start with an imperative verb. (e.g. 'Add frontend unit tests')\n\nBody: The body of a commit should explain the 'what' and 'why' of the commit, not the 'how'. It should be wrapped at 72 characters." ..
            "\n\nFooter: The footer of a commit should contain any information that is not part of the subject or body. (e.g. 'Fixes #123', 'Closes #456', 'BREAKING CHANGE: ...')")
          :user()
          :text("Git diff:\n```diff\n" .. diff_output .. "\n```\n")
          :send()
    end
  })

  mcphub.add_prompt("gnarus", {
    name = "curlify",
    description = "Parse and convert text to a `curl` command.",
    arguments = {
      {
        name = "text",
        description = "Text to convert to curl command",
        type = "string",
        required = true,
      },
    },
    handler = function(req, res)
      res:system()
          :text(
            "You are an expert at parsing text and converting it to a `curl` command. You will receive an arbitrary text and you will generate a `curl` command based on it.")
          :user()
          :text("Convert the following text to a `curl` command: \n```\n" .. req.params.text .. "\n```")
      return res:send()
    end
  })

  mcphub.add_prompt("gnarus", {
    name = "enhance-prompt",
    description = "Enhance a prompt of the user to make it more effective",
    arguments = {
      {
        name = "prompt",
        description = "Prompt to be improved",
        type = "string",
        required = true,
      },
    },
    handler = function(req, res)
      return res:system()
          :text("You are an expert prompt engineer who understands context and communication strategies.")
          :text("Improve the given prompt by making it more specific, clear, and actionable.")
          :user()
          :text("Enhance this prompt:\n" .. req.params.prompt .. "\n")
    end
  })

  mcphub.add_prompt("gnarus", {
    name = "prompt_sum",
    description =
    "Generate an effective prompt that captures the user's desires expressed throughout the current chat.",
    handler = function(_, res)
      local full_prompt = "You are a master at generating high-quality prompts. " ..
          "Your task is to take a summary of a conversation and generate a single, concise, and effective prompt " ..
          "that captures the user's ultimate goal or desire expressed throughout that conversation. " ..
          "The generated prompt should be suitable for use with a powerful language model to achieve the user's objective. " ..
          "Please provide only the optimized prompt, without any additional explanations or formatting."
      return res:system()
          :text(full_prompt)
          :user()
          :text(
            "Summarize the following conversation to extract the my ultimate goal and generate a single, concise, and effective prompt based on it:")
          :send()
    end
  })
end

return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
  config = function()
    ---@type MCPHub
    local mcphub = require("mcphub")
    mcphub.setup({
      --- `mcp-hub` binary related options-------------------
      config = vim.fn.expand("~/.config/mcphub/servers.json"),                         -- Absolute path to MCP Servers config file (will create if not exists)
      port = 37373,                                                                    -- The port `mcp-hub` server listens to
      shutdown_delay = 5 * 60 * 000,                                                   -- Delay in ms before shutting down the server when last instance closes (default: 5 minutes)
      use_bundled_binary = false,                                                      -- Use local `mcp-hub` binary (set this to true when using build = "bundled_build.lua")
      mcp_request_timeout = 60000,                                                     --Max time allowed for a MCP tool or resource to execute in milliseconds, set longer for long running tasks
      global_env = {},                                                                 -- Global environment variables available to all MCP servers (can be a table or a function returning a table)
      workspace = {
        enabled = true,                                                                -- Enable project-local configuration files
        look_for = { ".mcphub/servers.json", ".vscode/mcp.json", ".cursor/mcp.json" }, -- Files to look for when detecting project boundaries (VS Code format supported)
        reload_on_dir_changed = true,                                                  -- Automatically switch hubs on DirChanged event
        port_range = { min = 40000, max = 41000 },                                     -- Port range for generating unique workspace ports
        get_port = nil,                                                                -- Optional function returning custom port number. Called when generating ports to allow custom port assignment logic
      },

      ---Chat-plugin related options-----------------
      auto_approve = false,           -- Auto approve mcp tool calls
      auto_toggle_mcp_servers = true, -- Let LLMs start and stop MCP servers automatically
      extensions = {
        avante = {
          make_slash_commands = true, -- make /slash commands from MCP server prompts
        }
      },

      --- Plugin specific options-------------------
      native_servers = {}, -- add your custom lua native servers here
      builtin_tools = {
        edit_file = {
          parser = {
            track_issues = true,
            extract_inline_content = true,
          },
          locator = {
            fuzzy_threshold = 0.8,
            enable_fuzzy_matching = true,
          },
          ui = {
            go_to_origin_on_complete = true,
            keybindings = {
              accept = ".",
              reject = ",",
              next = "n",
              prev = "p",
              accept_all = "ga",
              reject_all = "gr",
            },
          },
        },
      },
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
      json_decode = nil, -- Custom JSON parser function (e.g., require('json5').parse for JSON5 support)
      ---@param hub MCPHub.Hub
      on_ready = function(hub)
        -- Called when hub is ready
        vim.notify("MCPHub is ready and listening on port " .. hub.port, vim.log.levels.INFO)
      end,
      on_error = function(err)
        -- Called on errors
        vim.notify("MCPHub error: " .. vim.inspect(err), vim.log.levels.ERROR)
      end,
      log = {
        level = vim.log.levels.WARN,
        to_file = false,
        file_path = nil,
        prefix = "MCPHub",
      },
    })

    add_prompts_and_resources(mcphub)
  end
}
