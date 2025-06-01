local ollama_adapter_opts = {
  env = {
    url = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"
  },
  schema = {
    model = {
      default = "qwen3"
    },
    choices = {
      "qwenn3",
      "qwenn2.5",
      "cogito"
    }
  },
  parameters = {
    sync = true
  }
}

-- Determine adapter names based on GEMINI_API_KEY
local chat_adapter_name = "gemini"
local inline_adapter_name = "gemini_flash"
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
        ["git_files"] = {
          description = "List git files",
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local handle = io.popen("git ls-files")
            if handle ~= nil then
              local result = handle:read("*a")
              handle:close()
              chat:add_reference({ role = "user", content = result }, "git", "<git_files>")
            else
              return vim.notify("No git files available", vim.log.levels.INFO, { title = "CodeCompanion" })
            end
          end,
          opts = {
            contains_code = false,
          },
        },
        ["git_changed_files"] = {
          description = "List git changed files",
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local handle = io.popen("git diff --name-only")
            if handle ~= nil then
              local result = handle:read("*a")
              handle:close()
              chat:add_reference({ role = "user", content = result }, "git", "<git_changed_files>")
            else
              return vim.notify("No git changed files available", vim.log.levels.INFO, { title = "CodeCompanion" })
            end
          end,
          opts = {
            contains_code = false,
          },
        },
        ["git_modified_or_added_files"] = {
          description = "List git modified or added files",
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local handle = io.popen("git status --porcelain | grep -v '^??' | awk '{ print $2 }'")
            if handle ~= nil then
              local result = handle:read("*a")
              handle:close()
              chat:add_reference({ role = "user", content = result }, "git", "<git_modified_or_added_files>")
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
    claude_haiku = adapter_and_default_model("anthropic", "claude-3-5-haiku-20241022"),
    gemini = adapter_and_default_model("gemini", "gemini-2.5-pro-preview-05-06"),
    gemini_flash = adapter_and_default_model("gemini", "gemini-2.0-flash"),
    ollama = adapter_and_default_model("ollama", "qwen3", ollama_adapter_opts),
  },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true,
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

vim.g.codecompanion_auto_tool_mode = true
