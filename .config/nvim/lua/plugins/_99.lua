return {
  "ThePrimeagen/99",
  config = function()
    local _99 = require("99")

    -- For logging that is to a file if you wish to trace through requests
    -- for reporting bugs, i would not rely on this, but instead the provided
    -- logging mechanisms within 99.  This is for more debugging purposes
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)

    local model = require("gnarus.utils").env_var_cascade({
      { vars = { "GNARUS_ALLOW_VENDOR_LLM" }, value = "anthropic/claude-sonnet-4-5" },
    }, "ollama-cloud/glm-5")

    _99.setup({
      model = model,
      provider = _99.Providers.OpenCodeProvider,
      logger = {
        level = _99.DEBUG,
        path = "/tmp/" .. basename .. ".99.debug",
        print_on_error = true,
      },

      -- When setting this to something that is not inside the CWD tools
      -- such as claude code or opencode will have permission issues
      -- and generation will fail refer to tool documentation to resolve
      -- https://opencode.ai/docs/permissions/#external-directories
      -- https://code.claude.com/docs/en/permissions#read-and-edit
      tmp_dir = "./tmp",
      show_in_flight_requests = true,
      auto_add_skills = true,

      --- Completions: #rules and @files in the prompt buffer
      completion = {
        -- I am going to disable these until i understand the
        -- problem better.  Inside of cursor rules there is also
        -- application rules, which means i need to apply these
        -- differently
        -- cursor_rules = "<custom path to cursor rules>"

        --- A list of folders where you have your own SKILL.md
        --- Expected format:
        --- /path/to/dir/<skill_name>/SKILL.md
        ---
        --- Example:
        --- Input Path:
        --- "scratch/custom_rules/"
        ---
        --- Output Rules:
        --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
        --- ... the other rules in that dir ...
        ---
        custom_rules = {
          "~/.agents/skills/",
        },

        --- Configure @file completion (all fields optional, sensible defaults)
        files = {
          -- enabled = true,
          -- max_file_size = 102400,     -- bytes, skip files larger than this
          -- max_files = 5000,            -- cap on total discovered files
          -- exclude = { ".env", ".env.*", "node_modules", ".git", ... },
        },

        --- What autocomplete do you use.  We currently only
        --- support cmp and blink right now
        source = "cmp",
      },

      --- WARNING: if you change cwd then this is likely broken
      --- ill likely fix this in a later change
      ---
      --- md_files is a list of files to look for and auto add based on the location
      --- of the originating request.  That means if you are at /foo/bar/baz.lua
      --- the system will automagically look for:
      --- /foo/bar/AGENT.md
      --- /foo/AGENT.md
      --- assuming that /foo is project root (based on cwd)
      md_files = {
        "AGENTS.md",
      },
    })

    -- take extra note that i have visual selection only in v mode
    -- technically whatever your last visual selection is, will be used
    -- so i have this set to visual mode so i dont screw up and use an
    -- old visual selection
    --
    -- likely ill add a mode check and assert on required visual mode
    -- so just prepare for it now
    vim.keymap.set("v", "<leader>9v", function()
      _99.visual()
    end)

    --- if you have a request you dont want to make any changes, just cancel it
    vim.keymap.set("n", "<leader>9x", function()
      _99.stop_all_requests()
    end)

    local last_search_xid = nil

    vim.keymap.set("n", "<leader>9s", function()
      last_search_xid = _99.search()
    end)

    --- open quickfix with results from the last search
    vim.keymap.set("n", "<leader>9q", function()
      if last_search_xid then
        _99.qfix_search_results(last_search_xid)
      else
        vim.notify("99: no search results yet", vim.log.levels.WARN)
      end
    end)

    --- tutorial: ask AI to generate a tutorial on any topic
    vim.keymap.set("n", "<leader>9t", function()
      _99.tutorial({})
    end)

    --- open the last tutorial (or pick from list if multiple)
    vim.keymap.set("n", "<leader>9T", function()
      _99.open_tutorial(nil)
    end)

    --- add md_files via file picker (markdown only)
    vim.keymap.set("n", "<leader>9a", function()
      Snacks.picker.files({
        ft = "md",
        confirm = function(picker, _)
          picker:close()
          local selected = picker:selected({ fallback = true })
          for _, item in ipairs(selected) do
            _99.add_md_file(item.file)
            vim.notify("99: added md_file " .. item.file)
          end
        end,
      })
    end)

    --- remove md_files via picker from current list
    vim.keymap.set("n", "<leader>9d", function()
      local state = _99.__get_state()
      local items = {}
      for _, md in ipairs(state.md_files) do
        table.insert(items, { text = md, file = md })
      end
      if #items == 0 then
        vim.notify("99: no md_files to remove", vim.log.levels.WARN)
        return
      end
      Snacks.picker({
        title = "Remove md_file",
        items = items,
        confirm = function(picker, _)
          picker:close()
          local selected = picker:selected({ fallback = true })
          for _, item in ipairs(selected) do
            _99.rm_md_file(item.text)
            vim.notify("99: removed md_file " .. item.text)
          end
        end,
      })
    end)
  end,
}
