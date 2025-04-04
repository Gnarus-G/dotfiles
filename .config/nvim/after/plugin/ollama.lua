require("OllamaCopilot").setup {
  model_name = "deepseek-coder-v2:16b-lite-base-q4_0",
  stream_suggestion = true,
  python_command = vim.api.nvim_call_function("stdpath", { "data" }) .. "/site/pack/packer/start/Ollama-Copilot/viper.sh",
  filetypes = { "md", "make", "rust", "python", "dockerfile", "toml", "bash" },
  ollama_model_opts = {
    num_predict = 40,
    temperature = 0,
    num_ctx = 4096 -- deepseek-coder-v2 is up to 163840
  },
  keymaps = {
    suggestion = '<leader>os',
    reject = '<leader>or',
    insert_accept = '<Tab>',
  },
}
