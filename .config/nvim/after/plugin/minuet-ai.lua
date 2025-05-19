local ollama_api_base = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

-- Base options defined separately
local base_opts = {
  provider = 'gemini',
  n_completions = 2, -- The less the faster, but it's nice to cycle through some options sometimes I guess
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
    auto_trigger_ft = {
      "rust",
      "python",
      "lua",
      "typescript",
      "typescriptreact",
      "go",
      "javascript",
      "javascripttreact",
      "html",
      "css",
    },
    show_on_completion_menu = true,
    keymap = {
      -- accept whole completion
      accept = '<Tab>',
      -- accept one line
      accept_line = '<M-l>',
      -- accept n lines (prompts for number)
      -- e.g. "A-z 2 CR" will accept 2 lines
      accept_n_lines = '<M-z>',
      -- Cycle to prev completion item, or manually invoke completion
      prev = '<M-[>',
      -- Cycle to next completion item, or manually invoke completion
      next = '<M-]>',
      dismiss = '<M-e>',
    },
  },
  provider_options = {
    claude = {
      model = 'claude-3-5-haiku-20241022',
    },
    gemini = {
      model = 'gemini-2.0-flash',
      optional = {
        generationConfig = {
          -- When using `gemini-2.5-flash`, it is recommended to entirely
          -- disable thinking for faster completion retrieval.
          thinkingConfig = {
            thinkingBudget = 0,
          },
        },
      },
    },
    openai_fim_compatible = {
      name = "Ollama",
      model = 'qwen2.5-coder:3b',
      api_key = "TERM",
      end_point = ollama_api_base .. '/v1/completions',
      optional = {
        max_tokens = 56,
        top_p = 0.9,
      },
    },
  }
}

require('minuet').setup(vim.tbl_extend('force', setup_opts, base_opts))
