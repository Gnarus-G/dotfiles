return {
  "milanglacier/minuet-ai.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "InsertEnter",
  config = function()
    local ollama_api_base = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

    local minuet_config   = require('minuet.config')
    local extra_context   = require('minuet_ctx')

    local opts            = {
      provider = "openai_compatible",
      n_completions = 3,
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
      -- request_timeout = 10,
      -- Model upgrade test flow:
      -- 1. Stream each candidate over the same Python insertion corpus in alternating order (2+ rounds).
      -- 2. Record time to first content token and total latency; compare median and p95 values.
      -- 3. Insert each response between its prefix/suffix, execute it, and score behavioral assertions.
      -- 4. Upgrade only when the candidate improves both latency and functional pass rate.
      -- 2026-08-04: DeepSeek 0731 passed 100% vs 50%, but had slower totals and an 18s tail; keep cloud.
      provider_options = {
        claude = {
          model = 'claude-haiku-4-5', -- $0.80/$4.00 per 1M tokens (input/output)
          chat_input = {
            template = "{{{extra_context}}}\n" ..
                minuet_config.default_chat_input_prefix_first.template,
            extra_context = extra_context.get_formatted_context
          },
        },
        openai_compatible = {
          -- Free (local/self-hosted via Ollama)
          name = "ollama",
          model = 'deepseek-v4.1-flash:cloud',
          chat_input = {
            template = "{{{extra_context}}}\n" ..
                minuet_config.default_chat_input_prefix_first.template,
            extra_context = extra_context.get_formatted_context
          },
          api_key = "TERM",
          stream = true,
          end_point = ollama_api_base .. '/v1/chat/completions',
          optional = {
            max_tokens = 256,
            top_p = 0.9,
            think = false,
            reasoning_effort = 'none',
          },
        },
        openai_fim_compatible = {
          -- Free (local/self-hosted via Ollama)
          name = "ollama-fim",
          model = 'qwen3-coder:480b-cloud', -- qwen2.5-coder:32b-base-q2_K
          chat_input = {
            template = "{{{extra_context}}}\n" ..
                minuet_config.default_chat_input_prefix_first.template,
            extra_context = extra_context.get_formatted_context
          },
          api_key = "TERM",
          end_point = ollama_api_base .. '/v1/completions',
          optional = {
            max_tokens = 256,
            top_p = 0.9,
            think = false,
            reasoning_effort = 'none',
          },
        },
      }
    }

    vim.notify(
      string.format("Minuet AI configured with provider: %s, completions: %s", opts.provider, opts.n_completions),
      vim.log.levels.DEBUG)

    require('minuet').setup(opts)
  end,
}
