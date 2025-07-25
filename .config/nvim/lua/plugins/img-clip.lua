return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  config = function()
    require("img-clip").setup {
      -- recommended settings
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        -- required for Windows users
        use_absolute_path = true,
      },
    }
  end,
}