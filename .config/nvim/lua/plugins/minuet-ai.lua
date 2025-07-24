return {
  "milanglacier/minuet-ai.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "InsertEnter",
  config = function()
    local ollama_api_base = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

    local minuet_config = require('minuet.config')
    local extra_context = require('minuet_ctx')

    -- Base options defined separately
    local base_opts = {
      provider = 'gemini',
      n_completions = 2,
    }

    -- when no gemini api key then use ollama
    if os.getenv("GEMINI_API_KEY") == nil then
      base_opts = {
        provider = 'openai_fim_compatible',
        n_completions = 1
      }
    end

    -- Main configuration table for minuet.setup
    local setup_opts = {
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
          model = 'claude-3-5-haiku-20241022',
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

    require('minuet').setup(vim.tbl_extend('force', setup_opts, base_opts))
  end,
}
