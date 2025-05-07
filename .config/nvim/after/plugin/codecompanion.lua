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

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = chat_adapter_name,
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
  display = { chat = { window = { position = "right" } } },
  opts = {
    log_level = "ERROR", -- TRACE|DEBUG|ERROR|INFO
  },
  adapters = {
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
        continue_last_chat = false,
        ---When chat is cleared with `gx` delete the chat from history
        delete_on_clearing_chat = true,
        -- Picker interface ("telescope" or "default")
        picker = "telescope",
        ---Enable detailed logging for history extension
        enable_logging = false,
        ---Directory path to save the chats
        dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
      }
    },
  }
})
