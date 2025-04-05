require("avante").setup {
  provider = "claude",

  auto_suggestions_provider = "claude",
  suggestion = {
    debounce = 300,
    throttle = 600,
  },
  ollama = {
    endpoint = "http://localhost:11434",
    model = "deepseek-coder-v2",
    temperature = 0,
    timeout = 30000,              -- Timeout in milliseconds, increase this for reasoning models
    max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
    reasoning_effort = "medium",  -- low|medium|high, only used for reasoning models
    num_ctx = 4096,               -- deepseek-coder-v2 is up to 163840
  },
  behaviour = {
    auto_suggestions = true,            -- Experimental stage
    enable_cursor_planning_mode = true, -- enable cursor planning mode!
  },
  rag_service = {
    enabled = true,                         -- Enables the RAG service
    host_mount = os.getenv("HOME") .. "/d", -- Host mount path for the rag service
    provider = "ollama",                    -- The provider to use for RAG service (e.g. openai or ollama)
    llm_model = "gemma3",                   -- The LLM model to use for RAG service
    embed_model = "nomic-embed-text",       -- The embedding model to use for RAG service
  },
  vendors = {},
  mappings = {
    suggestion = {
      accept = "<M-l>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
  }
}

-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3
