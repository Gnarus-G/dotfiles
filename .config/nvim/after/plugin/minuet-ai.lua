local ollama_api_base = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

local minuet_config = require('minuet.config')
local extra_context = require('minuet_extra_context')
local chat_context = require('minuet_chat_context')

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
      chat_input = {
        -- New template with placeholders for dynamic content
        -- The order here dictates where your custom content will appear relative to the standard context.
        -- This example places it BEFORE the standard {{{language}}}, {{{tab}}}, etc.
        template = "{{{chat_context}}}\n{{{extra_files_content}}}\n" ..
            minuet_config.default_chat_input_prefix_first.template,
        -- Function for the new placeholder
        extra_files_content = function()
          local content = extra_context.get_formatted_context()
          if content ~= '' then
            content = '<extra_files_content>\n' .. content .. '\n</extra_files_content>'
          end
          return content
        end,
        chat_context = function()
          local content = chat_context.get_formatted_context("codecompanion")
          content = table.concat({ content, chat_context.get_formatted_context("avante") }, "\n")
          return "<chat_context>\n" .. content .. "\n</chat_context>"
        end
      },
      model = 'gemini-2.5-flash-preview-05-20',
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

vim.api.nvim_create_user_command('MinuetClear', function()
  extra_context.clear()
  chat_context.clear()
end, { nargs = 0 })

vim.api.nvim_create_user_command('MinuetShowContext', function()
  local files = extra_context.dynamic_files
  vim.notify("--- Dynamic Files ---", vim.log.levels.INFO)
  if #files > 0 then
    for _, f in ipairs(files) do vim.notify("- " .. f, vim.log.levels.INFO) end
  else
    vim.notify("(none)", vim.log.levels.INFO)
  end

  vim.notify("--- Chat Context Buffers ---", vim.log.levels.INFO)
  if not chat_context.is_empty() then
    for ft, b in pairs(chat_context.nofile_buffers) do
      vim.notify("- " .. b .. " " .. ft, vim.log.levels.INFO)
    end
  else
    vim.notify("(none)", vim.log.levels.INFO)
  end
end, { nargs = 0 })
