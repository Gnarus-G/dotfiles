require "gnarus.options"
require "gnarus.remaps"
require "gnarus.formatting"
require "gnarus.lazy"

-- highlight_yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 40 })
  end
})

-- clipboard register config
-- using my own clipboard cli https://github.com/Gnarus-G/clip
vim.g.clipboard = {
  name = "my-clipboard",
  copy = {
    ["+"] = { "clip" }
  },
  paste = {
    ["+"] = { "clip", "read" }
  },
  cache_enabled = 1
}

-- Create some new filetypes
vim.filetype.add({
  extension = {
    mdx = 'mdx',
    ["Modelfile"] = 'modelfile',
    todo = 'todolang',
    td = 'todolang',
  },
  filename = {
    ["Modelfile"] = 'modelfile',
  }
})
