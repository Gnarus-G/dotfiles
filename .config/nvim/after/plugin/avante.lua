local Utils = require("avante.utils")
local ollama_api_base = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

-- Determine provider and models based on GEMINI_API_KEY
local provider_name = "gemini"
if os.getenv("GEMINI_API_KEY") == nil then
  provider_name = "ollama"
end

local disabled_tools = {
  "web_search",
  "replace_in_file",
  "view"
}

---@class avante.Config
local config = {
  provider = provider_name, -- Use the determined provider
  enable_claude_text_editor_tool_mode = false,
  suggestion = {
    debounce = 300,
    throttle = 300,
  },
  disabled_tools = disabled_tools,
  providers = {
    claude = {
      timeout = 30000, -- Timeout in milliseconds
      extra_request_body = {
        temperature = 0,
        max_tokens = 4096,
      }
    },
    gemini = {
      model = 'gemini-2.5-flash',
      timeout = 30000,
      use_ReAct_prompt = false,
      extra_request_body = {
        generationConfig = {
          temperature = 0.75,
        },
      },
    },
    gemini_next = {
      __inherited_from = 'gemini',
      model = 'gemini-2.5-pro',
    },
    gemini_fast = {
      __inherited_from = 'gemini',
      model = 'gemini-2.0-flash',
    },
    ollama = {
      __inherited_from = "ollama",
      endpoint = ollama_api_base,
      model = "qwen3:1.7b",
      extra_request_body = {
        think = true,
        keep_alive = "30m",
      },
    },
  },
  mode = "agentic",
  behaviour = {
    auto_suggestions = false,
    auto_apply_diff_after_generation = true,
  },
  rag_service = {
    enabled = false, -- Enables the RAG service
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
    local prompt =
    "---\nATTENTION: The `view` and `replace_in_file` tools are currently disabled due to known issues. Please refrain from using them.\n---"
    if not hub then return prompt end

    prompt = hub:get_active_servers_prompt() ..
        "\n----\nATTENTION: For **all** tool usage, you must *exclusively* use the `use_mcp_tool` and `access_mcp_resource` tools with the connected MCP servers." ..
        "\nATTENTION: For all file operations (read, write, delete, move, `replace_in_file`), you must use the `neovim` MCP server tools."
    return prompt
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
