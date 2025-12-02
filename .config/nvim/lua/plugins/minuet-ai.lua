local env_cascade = require("gnarus.utils").env_var_cascade

return {
  "milanglacier/minuet-ai.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "InsertEnter",
  config = function()
    local ollama_api_base         = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

    local minuet_config           = require('minuet.config')
    local extra_context           = require('minuet_ctx')

    local opts                    = {
      cmp = {
        enable_auto_complete = true,
      },
      virtualtext = {
        auto_trigger_ft = { "python" },
        show_on_completion_menu = true,
        keymap = {
          accept = '<Tab>',
          accept_line = '<M-l>',
          accept_n_lines = '<M-z>',
          prev = '<M-[>',
          next = '<M-]>',
          dismiss = '<M-e>',
        },
      },
      -- Increase timeout slightly since non-streamed responses arrive in one chunk
      request_timeout = 5,
      provider_options = {
        claude = {
          max_tokens = 512,
          model = 'claude-3-5-haiku-20241022',
          chat_input = {
            template = "{{{extra_context}}}\n" ..
                minuet_config.default_chat_input_prefix_first.template,
            extra_context = extra_context.get_formatted_context
          },
        },
        gemini = {
          model = "gemini-2.5-flash",
          chat_input = {
            template = "{{{extra_context}}}\n" ..
                minuet_config.default_chat_input_prefix_first.template,
            extra_context = extra_context.get_formatted_context
          },
          optional = {
            generationConfig = {
              maxOutputTokens = 256,
              thinkingConfig = {
                thinkingBudget = 0,
              },
            },
          },
        },
        openai = {
          model = "gpt-5.1",
          chat_input = {
            template = "{{{extra_context}}}\n" ..
                minuet_config.default_chat_input_prefix_first.template,
            extra_context = extra_context.get_formatted_context
          },
          stream = true,
          optional = {
            max_completion_tokens = 128,
            reasoning_effort = "none",
          },
        },
        openai_fim_compatible = {
          name = "ollama",
          model = 'qwen2.5-coder:3b',
          api_key = "TERM",
          end_point = ollama_api_base .. '/v1/completions',
          optional = {
            max_tokens = 256,
            top_p = 0.9,
            stop = { '\n\n' },
          },
        },
      }
    }

    local config                  = env_cascade({
      { vars = { "GNARUS_ALLOW_VENDOR_LLM", "GEMINI_API_KEY" }, value = { "gemini", 3 } },
      { vars = { "GNARUS_ALLOW_VENDOR_LLM", "OPENAI_API_KEY" }, value = { "openai", 2 } },
    }, { "openai_fim_compatible", 1 })
    local provider, n_completions = config[1], config[2]
    vim.notify(string.format("Minuet AI configured with provider: %s, completions: %s", provider, n_completions),
      vim.log.levels.DEBUG)

    require('minuet').setup(vim.tbl_extend('force', opts, {
      provider = provider,
      n_completions = n_completions,
    }))
  end,
}
