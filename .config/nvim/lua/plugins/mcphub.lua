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
          :user()
          :text("Explain why this error is happening in great detail: \n```txt\n" .. req.params.error .. "\n```")
          :send()
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
    name = "commit",
    description = "Genearate a commit message based on the changes against the provided git branch.",
    handler = function(_, res)
      local current_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD")
      current_branch = vim.trim(current_branch)

      local ok, diff_output = pcall(vim.fn.system, "git fetch --prune --all && git diff --staged " .. current_branch);
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
            "The subject line of a commit should be 50 characters max, and should start with an imperative verb. (e.g. 'Add frontend unit tests'). The subject line must not be prefixed with a type like 'feat:', 'fix:', or 'refactor:'.\n\nBody: The body of a commit should explain the 'what' and 'why' of the commit, not the 'how'. It should be wrapped at 72 characters." ..
            "\n\nFooter: The footer of a commit should contain any information that is not part of the subject or body. (e.g. 'Fixes #123', 'Closes #456', 'BREAKING CHANGE: ...')")
          :user()
          :text("@{gnarus__git_commit} Git diff:\n```diff\n" .. diff_output .. "\n```\n")
          :send()
    end
  })

  -- Tool: git-commit
  -- Wraps `git commit -F <file>` to allow multi-line commit messages composed of subject, body and footer.
  mcphub.add_tool("gnarus", {
    name = "git-commit",
    description = "Create a git commit using provided subject, body and footer. Runs `git commit -F <tmpfile>`.",
    inputSchema = {
      type = "object",
      properties = {
        subject = {
          type = "string",
          description =
          "Commit subject: single-line (max 50 chars), start with an imperative verb, no type prefixes like 'feat:' or 'fix:'",
        },
        body = {
          type = "string",
          description = "Commit body (optional, can be multi-line)",
        },
        footer = {
          type = "string",
          description = "Commit footer (optional)",
        },
      },
      required = { "subject" }
    },
    handler = function(req, res)
      local subject = req.params.subject or ""
      local body = req.params.body or ""
      local footer = req.params.footer or ""

      -- Build commit message
      local parts = {}
      table.insert(parts, subject)
      if body ~= "" then
        table.insert(parts, "\n" .. body)
      end
      if footer ~= "" then
        table.insert(parts, "\n" .. footer)
      end
      local message = table.concat(parts, "\n")

      -- Pass commit message via stdin to `git commit -F -` (no temp file)
      local cmd = "git commit -F -"
      -- vim.fn.system can accept input as second argument
      local ok, output = pcall(vim.fn.system, cmd, message)

      if not ok then
        return res:error("git commit failed", { error = output })
      end

      -- Check git exit status: use vim.v.shell_error which git sets
      local shell_err = tonumber(vim.v.shell_error) or 0
      if shell_err ~= 0 then
        return res:error("git commit failed", { output = output, code = shell_err })
      end

      return res:text(output):send()
    end,
  })

  mcphub.add_tool("gnarus", {
    name = "shotgun",
    description = "Take a screenshot of the current monitor screen or specific area/window.",
    inputSchema = {
      type = "object",
      properties = {
        output_file = {
          type = "string",
          description = "Output file path for the screenshot"
        },
        single_screen = {
          type = "boolean",
          description = "Capture only the screen determined by the cursor location"
        },
        geometry = {
          type = "string",
          description = "Area to capture in WxH+X+Y format (e.g., 800x600+100+100)"
        },
        window_id = {
          type = "string",
          description = "Window ID to capture"
        },
        format = {
          type = "string",
          enum = { "png", "pam" },
          description = "Output format (default: png)"
        }
      },
      required = { "output_file" }
    },
    handler = function(req, res)
      local params = req.params or {}
      local output_file = params.output_file
      local single_screen = params.single_screen
      local geometry = params.geometry
      local window_id = params.window_id
      local format = params.format

      -- Build command with options
      local cmd_parts = { "shotgun" }

      if single_screen then
        table.insert(cmd_parts, "-s")
      end

      if geometry then
        table.insert(cmd_parts, "-g")
        table.insert(cmd_parts, geometry)
      end

      if window_id then
        table.insert(cmd_parts, "-i")
        table.insert(cmd_parts, window_id)
      end

      if format then
        table.insert(cmd_parts, "-f")
        table.insert(cmd_parts, format)
      end

      table.insert(cmd_parts, output_file)

      local cmd = table.concat(cmd_parts, " ")
      local ok, output = pcall(vim.fn.system, cmd)

      if not ok or vim.v.shell_error ~= 0 then
        return res:error("Failed to take screenshot", { error = output, code = vim.v.shell_error })
      end

      res:text("Screenshot saved to " .. output_file):send()
    end
  })

  mcphub.add_tool("gnarus",
    {
      name = "todolist_add",
      description = "Add an item to the user's personal todolist",
      inputSchema = {
        type = "object",
        properties = {
          item = {
            type = "string",
            description = "description of the item todo"
          }
        },
        required = { "item" }
      },
      handler = function(req, res)
        local item = req.params.item
        local output = vim.fn.system("todo " .. item)

        local shell_err = tonumber(vim.v.shell_error) or 0
        if shell_err ~= 0 then
          return res:error("todo commit failed", { output = output, code = shell_err })
        end

        return res:text("Done!"):send()
      end
    })

  mcphub.add_tool("gnarus",
    {
      name = "todolist_mark-done",
      description = "Mark an item the user's personal todolist as completed.",
      inputSchema = {
        type = "object",
        properties = {
          id = {
            type = "string",
            description = "ID (hash) of the item to mark as completed."
          }
        },
        required = { "id" }
      },
      handler = function(req, res)
        local id = req.params.id
        local job = vim.system({ "todo", "done", id }, { text = true }):wait()
        local stdout = table.concat({ job.stdout }, "\n")
        local stderr = table.concat({ job.stderr }, "\n")

        if job.code ~= 0 then
          return res:error("todo command failed", { stdout = stdout, stderr = stderr, code = job.code })
        end

        return res:text("Done!"):send()
      end
    })


  mcphub.add_tool("gnarus",
    {
      name = "todolist_view",
      description = "View items in the user's personal todolist",
      inputSchema = {
        type = "object",
        properties = {},
      },
      handler = function(_, res)
        local output = vim.fn.system({ "todo", "dump" })

        local shell_err = tonumber(vim.v.shell_error) or 0
        if shell_err ~= 0 then
          return res:error("todo ls command failed", { output = output, code = shell_err })
        end

        return res:text(output):send()
      end
    })

  -- Tool: calculator
  -- Safely evaluate arithmetic expressions with support for Lua math functions (e.g., math.sin, math.cos) and constants.
  mcphub.add_tool("gnarus", {
    name = "calculator",
    description =
    "Evaluate arithmetic expressions. Supports +, -, *, /, %, ^, parentheses, decimals, and math.<fn> like math.sin(x). Also supports constants: pi, e, tau.",
    inputSchema = {
      type = "object",
      properties = {
        expression = { type = "string", description = "Expression to evaluate (e.g., '3*(2+5) - math.sin(math.pi/2)')" },
        precision = { type = "number", description = "Optional decimal places to format the result" },
      },
      required = { "expression" },
    },
    handler = function(req, res)
      local expr = (req.params and req.params.expression) or ""
      local precision = req.params and req.params.precision

      if type(expr) ~= "string" or vim.trim(expr) == "" then
        return res:error("`expression` must be a non-empty string"):send()
      end

      -- Basic safety checks: disallow quotes/backticks/assignments and unexpected letters
      if expr:find("[\"'`=]") then
        return res:error("Expression contains disallowed characters"):send()
      end

      -- Remove spaces for simpler inspection
      local compact = expr:gsub("%s+", "")
      -- Start by removing allowed identifiers while the dot is intact
      local remainder = compact
      -- Allow math.<identifier> (e.g., math.sin, math.pi, math.log)
      remainder = remainder:gsub("math%.[%a_][%w_]*", "")
      -- Allow constants pi, e, tau as bare identifiers (use frontiers to avoid matching inside numbers like 1e-3)
      remainder = remainder:gsub("(%f[%a])pi(%f[%A])", "")
      remainder = remainder:gsub("(%f[%a])tau(%f[%A])", "")
      remainder = remainder:gsub("(%f[%a])e(%f[%A])", "")
      -- Allow scientific notation (e.g., 1e-3, 2.5E10, .5e2) by removing the exponent marker when attached to a number
      remainder = remainder:gsub("([%d%.])[eE][%+%-]?%d+", "%1")
      -- Now strip allowed numeric and operator characters
      remainder = remainder:gsub("[%d%.%+%-%*/%%%^%(%),]", "")

      if remainder:find("[%a_]") then
        return res:error("Expression contains unknown identifiers"):send()
      end

      -- Restricted evaluation environment
      local env = {
        math = math,
        pi = math.pi,
        e = math.exp(1),
        tau = 2 * math.pi,
      }

      local chunk, load_err = load("return " .. expr, "calculator", "t", env)
      if not chunk then
        return res:error("Failed to parse expression", { error = load_err }):send()
      end

      local ok, result = pcall(chunk)
      if not ok then
        return res:error("Failed to evaluate expression", { error = result }):send()
      end

      if type(result) ~= "number" then
        return res:error("Expression did not evaluate to a number"):send()
      end

      if type(precision) == "number" and precision >= 0 and precision <= 12 then
        return res:text(string.format("%0." .. tostring(math.floor(precision)) .. "f", result)):send()
      else
        return res:text(tostring(result)):send()
      end
    end,
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
    name = "include-chatgpt-chat",
    description = "Include a conversation with ChatGPT in the prompt",
    arguments = {
      {
        name = "chat",
        description = "A conversation with ChatGPT from earlier",
        type = "string",
        required = true,
      },
    },
    handler = function(req, res)
      return res:system()
          :text("Consider this conversation that the user had with ChatGPT earlier.\n```\n" .. req.params.chat .. "\n```")
    end
  })

  mcphub.add_prompt("gnarus", {
    name = "prompt-summarize",
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
