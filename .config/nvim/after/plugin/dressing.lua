-- For those basic inputs from vim.ui.input
-- Force nvim-cmp setup for DressingInput buffers
vim.api.nvim_create_autocmd("FileType", {
  pattern = "DressingInput",
  group = vim.api.nvim_create_augroup("CmpDressingInputOverride", { clear = true }), -- New group name
  callback = function(_)
    local cmp_ok, cmp_instance = pcall(require, "cmp")
    if not cmp_ok then
      print("CMP_AUTOCMD_ERROR: Failed to require 'cmp' for DressingInput")
      return
    end

    -- This function will be called potentially *after* dressing.nvim has already configured cmp.
    -- We need to re-configure it with our desired settings.
    local setup_dressing_cmp = function()
      cmp_instance.setup.buffer({
        enabled = true, -- Crucial: ensure it's enabled
        sources = cmp_instance.config.sources({
          { name = "path" },
          { name = "buffer", option = { get_bufnrs = require("cmp_utils").get_visible_buffers } }
        }),
        window = {
          completion = cmp_instance.config.window.bordered(),
          documentation = cmp_instance.config.window.bordered(),
        },
      })
    end

    -- Defer this setup to try and ensure it runs *after* dressing.nvim's own setup.
    -- This is a bit of a race, but a common workaround.
    -- Increased delay to 100ms, might need adjustment.
    vim.defer_fn(setup_dressing_cmp, 100)
  end,
})
