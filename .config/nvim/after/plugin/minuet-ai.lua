require('minuet').setup {
  provider = 'gemini',
  n_completions = 3, -- The less the faster, but it's nice to cycle through some options sometimes I guess
  cmp = {
    enable_auto_complete = true,
  },
  virtualtext = {
    auto_trigger_ft = { "rust", "python", "lua" },
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
    gemini = {
      model = 'gemini-2.5-flash-preview-04-17', -- 'gemini-2.0-flash' or 'gemini-2.0-flash-lite' would be even faster
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
  }
}
