local function gemini_pro()
  return require("codecompanion.adapters").extend("gemini", {
    schema = {
      model = {
        default = "gemini-2.5-pro-exp-03-25",
      },
    },
  })
end

local function gemini_flash()
  return require("codecompanion.adapters").extend("gemini", {
    schema = {
      model = {
        default = "gemini-2.0-flash",
      },
    },
  })
end

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "gemini",
    },
    inline = {
      adapter = "gemini_flash",
    },
  },
  display = { chat = { window = { position = "right" } } },
  opts = {
    log_level = "ERROR", -- TRACE|DEBUG|ERROR|INFO
  },
  adapters = {
    gemini = gemini_pro,
    gemini_flash = gemini_flash,
  },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true,
      },
    },
  },
})
