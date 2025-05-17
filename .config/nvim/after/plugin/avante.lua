local ollama_api_base = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"

-- Determine provider and models based on GEMINI_API_KEY
local provider_name = "gemini"
local auto_suggestions_provider_name = "gemini_flash" -- Default suggestions provider
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
  claude = {
    model = "claude-3-5-sonnet-20241022",
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    max_tokens = 4096,
  },
  gemini = {
    model = "gemini-2.5-pro-preview-05-06",
    timeout = 30000,
    temperature = 0,
    max_tokens = 8192,
  },
  ollama = {
    endpoint = ollama_api_base,
    model = "qwen3",
    temperature = 0,
    timeout = 30000,              -- Timeout in milliseconds, increase this for reasoning models
    max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
    reasoning_effort = "medium",  -- low|medium|high, only used for reasoning models
    num_ctx = 4096,               -- deepseek-coder-v2 is up to 163840
  },
  disabled_tools = {
    "list_files",
    "search_files",
    "read_file",
    "create_file",
    "rename_file",
    "delete_file",
    "create_dir",
    "rename_dir",
    "delete_dir",
    "bash",
  },
  behaviour = {
    auto_suggestions = false,           -- Experimental stage
    enable_cursor_planning_mode = true, -- enable cursor planning mode!
  },
  rag_service = {
    enabled = false,                        -- Enables the RAG service
    host_mount = os.getenv("HOME") .. "/d", -- Host mount path for the rag service
    provider = "ollama",                    -- The provider to use for RAG service (e.g. openai or ollama)
    llm_model = "gemma3",                   -- The LLM model to use for RAG service
    embed_model = "nomic-embed-text",       -- The embedding model to use for RAG service
  },
  windows = {
    width = 40, -- Width as a percentage of screen width
  },
  vendors = {
    gemini_flash = {
      __inherited_from = 'gemini',
      model = 'gemini-2.5-flash-preview-04-17',
    },
    ollama_suggestions = {
      __inherited_from = "ollama",
      model = "qwen2.5-coder:3b"
    }
  },
  mappings = {
    suggestion = {
      accept = "<Tab>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
  },
  -- The system_prompt type supports both a string and a function that returns a string. Using a function here allows dynamically updating the prompt with mcphub
  system_prompt = function()
    local hub = require("mcphub").get_hub_instance()
    return hub:get_active_servers_prompt()
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
