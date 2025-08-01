local ollama_adapter_opts = {
  env = {
    url = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"
  },
  parameters = {
    sync = true
  }
}

-- Determine adapter names based on GEMINI_API_KEY
local chat_adapter_name = "gemini"
local inline_adapter_name = "gemini_fastest"
local cmd_adapter_name = "gemini"

if os.getenv("GEMINI_API_KEY") == nil then
  chat_adapter_name = "ollama"
  inline_adapter_name = "ollama"
  cmd_adapter_name = "ollama"
end

---@param adapter string
---@param model string
---@param extra_opts table?
local function adapter_and_default_model(adapter, model, extra_opts)
  local opts = vim.tbl_deep_extend("force", extra_opts or {},
    {
      schema = {
        model = {
          default = model
        }
      },
    }
  );
  return require("codecompanion.adapters").extend(adapter, opts)
end

---@param filepath string should be relative
local function add_file_to_codecompanion_chat(filepath, chat)
  local filetype = vim.fn.getbufvar(vim.api.nvim_get_current_buf(), "&filetype")
  local content = io.open(filepath, "r"):read("*a")
  local title = "<attachment filepath=\"" .. filepath .. "\">"
  local body = "Here is the content from the file:\n\n" .. "```" .. filetype .. "\n" .. content
  local footer = "```\n</attachment>"

  chat:add_reference({ role = "user", content = title .. body .. footer }, filepath,
    "<file>" .. filepath .. "</file>")
end

local opts = {
  strategies = {
    chat = {
      adapter = chat_adapter_name,
      roles = {
        ---The header name for the LLM's messages
        ---@type string|fun(adapter: CodeCompanion.Adapter): string
        llm = function(adapter)
          return "CodeCompanion (" .. adapter.name .. ")"
        end,
      },
      slash_commands = {
        ["dir"] = {
          description = "Select files from your home and add them as references to the current chat",
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local home = vim.loop.os_homedir()
            local dirs_therein = vim.fn.systemlist("find " .. home .. " -maxdepth 5 -type d")

            vim.ui.select(dirs_therein, {
                prompt = "Select"
              },
              function(dir)
                local files_in_dir = vim.fn.systemlist("find " .. dir .. " -maxdepth 1 -type f")
                vim.iter(files_in_dir)
                    :each(function(file)
                      local content_as_string = io.open(file, "r"):read("*a")
                      chat:add_reference({ role = "user", content = content_as_string }, file,
                        "<file>" .. file .. "</file>")
                    end)
              end)
          end,
          opts = {
            contains_code = false,
          },
        },
        ["files"] = {
          description =
          'Select from under $HOME, under specific directories: "d", ".local", ".config", "bin"',
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local home = os.getenv("HOME") .. "/"
            Snacks.picker.files({
              prompt = "Select files:",
              hidden = true,
              dirs = vim.iter({ "d", ".local", ".config", "bin" })
                  :filter(function(dir) return dir ~= nil end)
                  :map(function(dir) return home .. dir end)
                  :totable(),
              confirm = function(picker)
                picker:close()
                local selected = picker:selected({ fallback = true }) or {}
                vim.iter(selected)
                    :map(function(item)
                      return item.path or item.file or item.text
                    end)
                    :each(function(file)
                      local content_as_string = io.open(file, "r"):read("*a")
                      chat:add_reference({ role = "user", content = content_as_string }, file,
                        "<file>" .. file .. "</file>")
                    end)
              end,
            })
          end,
          opts = {
            contains_code = false,
          },
        },
        ["minuet_selected_files"] = {
          description = "Load in minuet extra files",
          callback = function(chat)
            local minuet_ctx = require("minuet_ctx")
            for _, filepath in ipairs(minuet_ctx.files()) do
              add_file_to_codecompanion_chat(filepath, chat)
            end
          end,
          opts = {
            contains_code = false,
          },
        },
        ["git_unstaged_files"] = {
          description = "List git unstaged files",
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local handle = io.popen("git diff --name-only")
            if handle ~= nil then
              local result = handle:read("*a")
              handle:close()
              chat:add_reference({ role = "user", content = result }, "git", "<git_changed_files/>")
            else
              return vim.notify("No git changed files available", vim.log.levels.INFO, { title = "CodeCompanion" })
            end
          end,
          opts = {
            contains_code = false,
          },
        },
        ["git_modified_or_added_files"] = {
          description = "List git unstaged or staged files",
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local handle = io.popen("git status --porcelain | grep -v '^??' | awk '{ print $2 }'")
            if handle ~= nil then
              local result = handle:read("*a")
              handle:close()
              chat:add_reference({ role = "user", content = result }, "git", "<git_modified_or_added_files/>")
            else
              return vim.notify("No git modified or added files available", vim.log.levels.INFO,
                { title = "CodeCompanion" })
            end
          end,
          opts = {
            contains_code = false,
          },
        }
      },
    },
    inline = {
      adapter = inline_adapter_name,
      keymaps = {
        accept_change = {
          modes = { n = "ga" },
          description = "Accept the suggested change",
        },
        reject_change = {
          modes = { n = "gr" },
          description = "Reject the suggested change",
        },
      },
    },
    cmd = {
      adapter = cmd_adapter_name
    }
  },
  display = {
    diff = {
      enabled = true,
      close_chat_at = 80,   -- Close an open chat buffer if the total columns of your display are less than...
      layout = "vertical",  -- vertical|horizontal split for default provider
      opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
      provider = "default", -- default|mini_diff
    },
    chat = { window = { position = "right" }, show_settings = true }
  },
  opts = {
    log_level = "ERROR", -- TRACE|DEBUG|ERROR|INFO
  },
  adapters = {
    gemini = adapter_and_default_model("gemini", "gemini-2.5-flash"),
    gemini_pro = adapter_and_default_model("gemini", "gemini-2.5-pro"),
    gemini_fastest = adapter_and_default_model("gemini", "gemini-2.0-flash"),
    claude_haiku = adapter_and_default_model("anthropic", "claude-3-5-haiku-20241022"),
    ollama = adapter_and_default_model("ollama", "qwen3", ollama_adapter_opts),
  },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        -- MCP Tools
        make_tools = true,                    -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
        show_server_tools_in_chat = true,     -- Show individual tools in chat completion (when make_tools=true)
        add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
        show_result_in_chat = true,           -- Show tool results directly in chat buffer
        format_tool = nil,                    -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
        -- MCP Resources
        make_vars = true,                     -- Convert MCP resources to #variables for prompts
        -- MCP Prompts
        make_slash_commands = true,           -- Add MCP prompts as /slash commands
      },
    },
    history = {
      enabled = true,
      opts = {
        -- Keymap to open history from chat buffer
        keymap = "gh",
        -- Automatically generate titles for new chats
        auto_generate_title = true,
        ---On exiting and entering neovim, loads the last chat on opening chat
        continue_last_chat = true,
        ---When chat is cleared with `gx` delete the chat from history
        delete_on_clearing_chat = true,
        -- Picker interface ("telescope" or "default")
        picker = "telescope",
        ---Enable detailed logging for history extension
        enable_logging = false,
        ---Directory path to save the chats
        dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",

        max_history = 10
      }
    },
  }
}

require("codecompanion").setup(opts)

vim.keymap.set("n", "<leader>cc", function()
  local models = vim.iter(pairs(opts.adapters)):map(
        function(key, value)
          return {
            name = key,
            model = value.schema.model.default
          }
        end)
      :totable()

  vim.ui.select(models, {
    prompt = "Select an adapter:",
    format_item = function(item) return item.name .. " (" .. item.model .. ")" end,
  }, function(item)
    if item then
      return vim.cmd(":CodeCompanionChat " .. item.name .. " <cr>")
    end
    vim.notify("No adapter selected", vim.log.levels.WARN)
  end)
end, { desc = "CodeCompanion Chat" })

vim.keymap.set({ "n", "v" }, "<leader>cs", "<cmd>CodeCompanion<cr>", { desc = "CodeCompanion Inline" })
vim.keymap.set("n", "<leader>cp", "<cmd>CodeCompanionActions<cr>", { desc = "CodeCompanion Actions" })

vim.g.codecompanion_auto_tool_mode = true
