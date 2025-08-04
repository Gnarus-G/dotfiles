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
        auto_trigger_ft = {},
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
              thinkingConfig = {
                thinkingBudget = 0,
              },
            },
          },
        },
        openai = {
          model = "gpt-4.1-nano",
          chat_input = {
            template = "{{{extra_context}}}\n" ..
                minuet_config.default_chat_input_prefix_first.template,
            extra_context = extra_context.get_formatted_context
          },
          optional = {
            max_tokens = 256,
          },
        },
        openai_fim_compatible = {
          name = "Ollama FIM",
          model = 'qwen2.5-coder:3b',
          api_key = "TERM",
          end_point = ollama_api_base .. '/v1/completions',
          optional = {
            max_tokens = 256,
            stop = { '\n\n' },
          },
        },
      },
      presets = {
        faster = {
          provider_options = {
            gemini = {
              model = 'gemini-2.0-flash',
              chat_input = {
                template = "{{{extra_context}}}\n" ..
                    minuet_config.default_chat_input_prefix_first.template,
                extra_context = extra_context.get_formatted_context
              },
            },
          }
        }
      }
    }

    local config                  = env_cascade({
      OPENAI_API_KEY = { "openai", 2 },
      GEMINI_API_KEY = { "gemini", 3 },
      __default = { "openai_fim_compatible", 1 }
    }, { "GEMINI_API_KEY", "OPENAI_API_KEY" })
    local provider, n_completions = config[1], config[2]
    vim.notify(string.format("Minuet AI configured with provider: %s, completions: %s", provider, n_completions))

    require('minuet').setup(vim.tbl_extend('force', opts, {
      provider = provider,
      n_completions = n_completions,
    }))
  end,
}
