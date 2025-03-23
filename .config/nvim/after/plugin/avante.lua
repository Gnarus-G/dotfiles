require("avante").setup {
  -- add any opts here
  -- for example
  provider = "ollama",
  ollama = {
    endpoint = "http://localhost:11434",
    model = "deepseek-coder-v2",
    timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
    temperature = 0,
    --[[ max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models) ]]
    --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
  },
}
