local Utils = require("avante.utils")
local ollama_api_base = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

-- Determine provider and models based on GEMINI_API_KEY
local provider_name = "gemini_next"
local auto_suggestions_provider_name = "gemini" -- Default suggestions provider
if os.getenv("GEMINI_API_KEY") == nil then
  provider_name = "ollama"
  auto_suggestions_provider_name = "ollama_suggestions" -- Use ollama provider for suggestions
end

---@class avante.Config
local config = {
  provider = provider_name,                                   -- Use the determined provider
  enable_claude_text_editor_tool_mode = false,
  auto_suggestions_provider = auto_suggestions_provider_name, -- Use the determined suggestions provider
  suggestion = {
    debounce = 300,
    throttle = 300,
  },
  providers = {
    claude = {
      timeout = 30000, -- Timeout in milliseconds
      extra_request_body = {
        temperature = 0,
        max_tokens = 4096,
      }
    },
    gemini = {
      model = 'gemini-2.5-flash-preview-05-20',
      timeout = 30000,
      use_ReAct_prompt = false,
      extra_request_body = {
        generationConfig = {
          temperature = 0.75,
        },
      },
    },
    ollama = {
      endpoint = ollama_api_base,
      model = "qwen3",
      timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
      extra_request_body = {
        options = {
          max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
          reasoning_effort = "medium",  -- low|medium|high, only used for reasoning models
          num_ctx = 4096,               -- deepseek-coder-v2 is up to 163840
          keep_alive = "10m",
        },
      },
    },
    gemini_next = {
      __inherited_from = 'gemini',
      model = 'gemini-2.5-pro-preview-06-05',
    },
    ollama_suggestions = {
      __inherited_from = "ollama",
      model = "qwen2.5-coder:3b"
    }
  },
  mode = "legacy",
  disabled_tools = {
    "list_files",
    "search_files",
    "read_file",
    "create_file",
    "rename_file",
    "replace_in_file",
    "delete_file",
    "create_dir",
    "rename_dir",
    "delete_dir",
    "bash",
    "fetch"
  },
  behaviour = {
    auto_suggestions = false, -- Experimental stage
    auto_apply_diff_after_generation = true,
  },
  rag_service = {
    enabled = true,                         -- Enables the RAG service
    host_mount = os.getenv("HOME") .. "/d", -- Host mount path for the rag service
    provider = "ollama",                    -- The provider to use for RAG service (e.g. openai or ollama)
    llm_model = "gemma3",                   -- The LLM model to use for RAG service
    embed_model = "nomic-embed-text",       -- The embedding model to use for RAG service
  },
  web_search_engine = {
    provider = "searxng",
    proxy = nil
  },
  windows = {
    width = 40, -- Width as a percentage of screen width
  },
  mappings = {
    suggestion = {
      accept = "<Tab>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
  },
  input = {
    provider = "snacks",
    provider_opts = {},
  },
  ---@type AvanteSlashCommand[]
  slash_commands = {
    {
      name        = "files",
      description = "Select files",
      details     =
      'Select from under $HOME, under specific directories: "d", ".local", ".config", "bin", <...user-selected-ones>',
      callback    = function(sidebar, args, cb)
        local home = os.getenv("HOME") .. "/"
        Snacks.picker.files({
          prompt = "Select files:",
          hidden = true,
          dirs = vim.iter(vim.tbl_extend("keep", { "d", ".local", ".config", "bin" }, args and vim.split(args, ",") or {}))
              :filter(function(dir) return dir ~= nil end)
              :map(function(dir) return home .. dir end)
              :totable(),
          confirm = function(picker)
            picker:close()
            local selected = picker:selected({ fallback = true }) or {}
            selected = vim.iter(selected)
                :map(function(item)
                  return item.path or item.file or item.text
                end):totable()

            local file_selector = sidebar.file_selector;
            for _, file in ipairs(selected) do
              local project_root = Utils.get_project_root()
              local rel_path = Utils.make_relative_path(file, project_root)
              if not vim.tbl_contains(file_selector.selected_filepaths, rel_path) then
                table.insert(file_selector.selected_filepaths,
                  rel_path)
              end
            end
            file_selector:emit("update")

            if cb then cb(args) end
          end,
        })
      end,
    },
    {
      name = "minuet_selected_files",
      description = "Load in minuet extra files",
      details = "Load files from minuet_ctx into the selected files",
      callback = function(sidebar, args, cb)
        local minuet_ctx = require("minuet_ctx")
        local file_selector = sidebar.file_selector

        for _, file_path in ipairs(minuet_ctx.files()) do
          local project_root = Utils.get_project_root()
          local rel_path = Utils.make_relative_path(file_path, project_root)
          if not vim.tbl_contains(file_selector.selected_filepaths, rel_path) then
            table.insert(file_selector.selected_filepaths, rel_path)
          end
          file_selector:emit("update")
        end
        if cb then cb(args) end
      end,
    }
  },
  -- The system_prompt type supports both a string and a function that returns a string. Using a function here allows dynamically updating the prompt with mcphub
  system_prompt = function()
    local hub = require("mcphub").get_hub_instance()
    return hub and hub:get_active_servers_prompt() or ""
  end,
  -- The custom_tools type supports both a list and a function that returns a list. Using a function here prevents requiring mcphub before it's loaded
  custom_tools = function()
    return {
      require("mcphub.extensions.avante").mcp_tool(),
    }
  end,
}

require("avante").setup(config)

-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3

-- avante cmp settings
local cmp = require("cmp")
cmp.setup.filetype("AvanteInput", {
  sources = cmp.config.sources(
  -- Group 1: Avante's specific sources (queried first)
    {
      { name = 'avante_commands' }, -- Uses '/' trigger, can't overwrite
      { name = 'avante_mentions', },
    },
    -- Group 2: Your general purpose sources (fallback or complementary)
    {
      { name = 'path', },
      {
        name = 'buffer',
        option = {
          get_bufnrs = require("gnarus.utils").get_visible_buffers,
        }
      },
    },
    -- Group 3
    {
      { name = 'minuet' }
    }
  ),
  formatting = {
    format = require("lspkind").cmp_format({
      menu = {
        avante_commands = "[AvanteCommand]",
        avante_mentions = "[AvanteMention]",
      }
    })
  },
})

cmp.setup.filetype("AvantePromptInput", {
  sources = cmp.config.sources(
    {
      { name = 'avante_prompt_mentions', },
    },
    {
      { name = 'path', },
      {
        name = 'buffer',
        option = {
          get_bufnrs = require("gnarus.utils").get_visible_buffers,
        }
      },
    },
    {
      { name = 'minuet' }
    }
  ),
  formatting = {
    format = require("lspkind").cmp_format({
      menu = {
        avante_prompt_mentions = "[AvantePromptMention]",
      }
    })
  },
})

-- Using `#` in the avante input often changes the filetype to `conf`
-- This mitigates that issue
local avante_ft_group = vim.api.nvim_create_augroup("AvanteFiletypeLock", { clear = true })
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = avante_ft_group,
  pattern = "AvanteInput", -- Only act when the filetype is initially AvanteInput
  callback = function(args)
    -- This nested autocmd will run when text changes IN an AvanteInput buffer
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      buffer = args.buf, -- Act only on this specific buffer
      once = false,      -- Keep this active for the buffer's lifetime
      callback = function()
        if vim.bo[args.buf].filetype ~= "AvanteInput" then
          vim.schedule(function() -- vim.schedule to avoid issues during event processing
            vim.bo[args.buf].filetype = "AvanteInput"
            --[[ vim.notify("Filetype reset to AvanteInput for buffer " .. args.buf, vim.log.levels.INFO) ]]
          end)
        end
      end,
    })
  end,
})
