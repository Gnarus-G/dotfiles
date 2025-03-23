require("OllamaCopilot").setup {
  model_name = "deepsoydev",
  stream_suggestion = false,
  python_command = vim.api.nvim_call_function("stdpath", { "data" }) .. "/site/pack/packer/start/Ollama-Copilot/viper.sh",
  filetypes = { "md", "make", "rust", "python", "dockerfile", "toml", "bash" },
  ollama_model_opts = {
    num_predict = 40,
    temperature = 0.7,
  },
  keymaps = {
    suggestion = '<leader>os',
    reject = '<leader>or',
    insert_accept = '<Tab>',
  },
}
