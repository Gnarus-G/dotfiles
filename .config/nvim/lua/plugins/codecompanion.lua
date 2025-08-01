return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
    "stevearc/dressing.nvim",
    "ravitemer/codecompanion-history.nvim",
  },
  config = function()
    local ollama_adapter_opts = {
      env = {
        url = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434"
      },
      schema = {
        temperature = {
          default = 0
        },
        keep_alive = {
          default = '30m',
        }
      },
      parameters = {
        sync = true
      }
    }

    -- Determine adapter names based on GEMINI_API_KEY
    local chat_adapter_name = "gemini"
    local inline_adapter_name = "gemini_fast"
    local cmd_adapter_name = "gemini"

    if os.getenv("GEMINI_API_KEY") == nil then
      chat_adapter_name = "ollama"
      inline_adapter_name = "ollama"
      cmd_adapter_name = "ollama"
    end

    ---@param adapter string
    ---@param model string
    ---@param extra_opts table?
    local function adapter_and_default_model(adapter, model, extra_opts)
      local opts = vim.tbl_deep_extend("force", extra_opts or {},
        {
          schema = {
            model = {
              default = model
            }
          },
        }
      );
      return require("codecompanion.adapters").extend(adapter, opts)
    end

    ---@param filepath string should be relative
    local function add_file_to_codecompanion_chat(filepath, chat)
      local filetype = vim.fn.getbufvar(vim.api.nvim_get_current_buf(), "&filetype")
      local content = io.open(filepath, "r"):read("*a")
      local title = "<attachment filepath=\"" .. filepath .. "\">"
      local body = "Here is the content from the file:\n\n" .. "```" .. filetype .. "\n" .. content
      local footer = "```\n</attachment>"

      chat:add_reference({ role = "user", content = title .. body .. footer }, filepath,
        "<file>" .. filepath .. "</file>")
    end

    local opts = {
      strategies = {
        chat = {
          adapter = chat_adapter_name,
          roles = {
            ---The header name for the LLM's messages
            ---@type string|fun(adapter: CodeCompanion.Adapter): string
            llm = function(adapter)
              return "CodeCompanion (" .. adapter.name .. ")"
            end,
          },
          tools = {
            groups = {
              ["read_only"] = {
                description = "A custom agent combining tools",
                system_prompt = "Read files from the filesystem to acquire any missing context.",
                tools = {
                  "neovim__list_directory",
                  "neovim__find_files",
                  "neovim__read_file",
                  "neovim__read_multiple_files",
                },
                opts = {
                  collapse_tools = false, -- When true, show as a single group reference instead of individual tools
                },
              },
              ["smart_dev"] = {
                description = "A custom agent combining tools",
                system_prompt =
                "You're a meticulous software engineer who always looks things up before making decisions.",
                tools = {
                  "neovim__list_directory",
                  "neovim__find_files",
                  "neovim__read_file",
                  "neovim__read_multiple_files",
                  "neovim__write_file",
                  "neovim__edit_file",
                  "context7_mcp__resolve_library_id",
                  "context7_mcp__get_library_docs",
                  "ez_web_search_mcp__search"
                },
                opts = {
                  collapse_tools = false, -- When true, show as a single group reference instead of individual tools
                },
              },
            }
          },
          slash_commands = {
            ["dir"] = {
              description = "Select files from your home and add them as references to the current chat",
              ---@param chat CodeCompanion.Chat
              callback = function(chat)
                local home = vim.loop.os_homedir()
                local dirs_therein = vim.fn.systemlist("find " .. home .. " -maxdepth 5 -type d")

                vim.ui.select(dirs_therein, {
                    prompt = "Select"
                  },
                  function(dir)
                    local files_in_dir = vim.fn.systemlist("find " .. dir .. " -maxdepth 1 -type f")
                    vim.iter(files_in_dir)
                        :each(function(file)
                          local content_as_string = io.open(file, "r"):read("*a")
                          chat:add_reference({ role = "user", content = content_as_string }, file,
                            "<file>" .. file .. "</file>")
                        end)
                  end)
              end,
              opts = {
                contains_code = false,
              },
            },
            ["files"] = {
              description =
              'Select from under $HOME, under specific directories: "d", ".local", ".config", "bin"',
              ---@param chat CodeCompanion.Chat
              callback = function(chat)
                local home = os.getenv("HOME") .. "/"
                Snacks.picker.files({
                  prompt = "Select files:",
                  hidden = true,
                  dirs = vim.iter({ "d", ".local", ".config", "bin" })
                      :filter(function(dir) return dir ~= nil end)
                      :map(function(dir) return home .. dir end)
                      :totable(),
                  confirm = function(picker)
                    picker:close()
                    local selected = picker:selected({ fallback = true }) or {}
                    vim.iter(selected)
                        :map(function(item)
                          return item.path or item.file or item.text
                        end)
                        :each(function(file)
                          local content_as_string = io.open(file, "r"):read("*a")
                          chat:add_reference({ role = "user", content = content_as_string }, file,
                            "<file>" .. file .. "</file>")
                        end)
                  end,
                })
              end,
              opts = {
                contains_code = false,
              },
            },
            ["minuet_selected_files"] = {
              description = "Load in minuet extra files",
              callback = function(chat)
                local minuet_ctx = require("minuet_ctx")
                for _, filepath in ipairs(minuet_ctx.files()) do
                  add_file_to_codecompanion_chat(filepath, chat)
                end
              end,
              opts = {
                contains_code = false,
              },
            },
            ["git_modified_or_added_files"] = {
              description = "List git unstaged or staged files",
              ---@param chat CodeCompanion.Chat
              callback = function(chat)
                local result, err = require("gnarus.utils").git_modified_or_added_files()
                if result == nil then
                  return vim.notify("No git modified or added files available: " .. err, vim.log.levels.INFO,
                    { title = "CodeCompanion" })
                end
                for _, filepath in ipairs(result) do
                  add_file_to_codecompanion_chat(filepath, chat)
                end
              end,
              opts = {
                contains_code = false,
              },
            }
          },
        },
        inline = {
          adapter = inline_adapter_name,
          keymaps = {
            accept_change = {
              modes = { n = "ga" },
              description = "Accept the suggested change",
            },
            reject_change = {
              modes = { n = "gr" },
              description = "Reject the suggested change",
            },
          },
        },
        cmd = {
          adapter = cmd_adapter_name
        }
      },
      display = {
        diff = {
          enabled = true,
          close_chat_at = 80,     -- Close an open chat buffer if the total columns of your display are less than...
          layout = "vertical",    -- vertical|horizontal split for default provider
          opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
          provider = "mini_diff", -- default|mini_diff
        },
        chat = { window = { position = "right" }, show_settings = true }
      },
      opts = {
        log_level = "ERROR", -- TRACE|DEBUG|ERROR|INFO
      },
      adapters = {
        gemini = adapter_and_default_model("gemini", "gemini-2.5-flash"),
        gemini_fast = adapter_and_default_model("gemini", "gemini-2.5-flash", {
          schema = {
            temperature = {
              default = 0
            },
            reasoning_effort = {
              default = "none"
            }
          }
        }),
        gemini_pro = adapter_and_default_model("gemini", "gemini-2.5-pro"),
        claude_haiku = adapter_and_default_model("anthropic", "claude-3-5-haiku-20241022"),
        claude_sonnet = adapter_and_default_model("anthropic", "claude-sonnet-4-20250514"),
        claude_opus = adapter_and_default_model("anthropic", "claude-opus-4-20250514"),
        ollama = adapter_and_default_model("ollama", "qwen3", ollama_adapter_opts),
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            -- MCP Tools
            make_tools = true,                    -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
            show_server_tools_in_chat = true,     -- Show individual tools in chat completion (when make_tools=true)
            add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
            show_result_in_chat = true,           -- Show tool results directly in chat buffer
            format_tool = nil,                    -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
            -- MCP Resources
            make_vars = true,                     -- Convert MCP resources to #variables for prompts
            -- MCP Prompts
            make_slash_commands = true,           -- Add MCP prompts as /slash commands
          },
        },
        history = {
          enabled = true,
          opts = {
            -- Keymap to open history from chat buffer (default: gh)
            keymap = "gh",
            -- Keymap to save the current chat manually (when auto_save is disabled)
            save_chat_keymap = "sc",
            -- Save all chats by default (disable to save only manually using 'sc')
            auto_save = true,
            -- Number of days after which chats are automatically deleted (0 to disable)
            expiration_days = 0,
            -- Picker interface (auto resolved to a valid picker)
            picker = "telescope", --- ("telescope", "snacks", "fzf-lua", or "default")
            ---Optional filter function to control which chats are shown when browsing
            chat_filter = nil,    -- function(chat_data) return boolean end
            -- Customize picker keymaps (optional)
            picker_keymaps = {
              rename = { n = "r", i = "<M-r>" },
              delete = { n = "d", i = "<M-d>" },
              duplicate = { n = "<C-y>", i = "<C-y>" },
            },
            ---Automatically generate titles for new chats
            auto_generate_title = true,
            title_generation_opts = {
              ---Adapter for generating titles (defaults to current chat adapter)
              adapter = nil,               -- "copilot"
              ---Model for generating titles (defaults to current chat model)
              model = nil,                 -- "gpt-4o"
              ---Number of user prompts after which to refresh the title (0 to disable)
              refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
              ---Maximum number of times to refresh the title (default: 3)
              max_refreshes = 3,
              format_title = function(original_title)
                -- this can be a custom function that applies some custom
                -- formatting to the title.
                return original_title
              end
            },
            ---On exiting and entering neovim, loads the last chat on opening chat
            continue_last_chat = false,
            ---When chat is cleared with `gx` delete the chat from history
            delete_on_clearing_chat = false,
            ---Directory path to save the chats
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            ---Enable detailed logging for history extension
            enable_logging = false,

            -- Summary system
            summary = {
              -- Keymap to generate summary for current chat (default: "gcs")
              create_summary_keymap = "gcs",
              -- Keymap to browse summaries (default: "gbs")
              browse_summaries_keymap = "gbs",

              generation_opts = {
                adapter = nil,               -- defaults to current chat adapter
                model = nil,                 -- defaults to current chat model
                context_size = 90000,        -- max tokens that the model supports
                include_references = true,   -- include slash command content
                include_tool_outputs = true, -- include tool execution results
                system_prompt = nil,         -- custom system prompt (string or function)
                format_summary = nil,        -- custom function to format generated summary e.g to remove <think/> tags from summary
              },
            },

            -- Memory system (requires VectorCode CLI)
            memory = {
              -- Automatically index summaries when they are generated
              auto_create_memories_on_summary_generation = true,
              -- Path to the VectorCode executable
              vectorcode_exe = "vectorcode",
              -- Tool configuration
              tool_opts = {
                -- Default number of memories to retrieve
                default_num = 10
              },
              -- Enable notifications for indexing progress
              notify = true,
              -- Index all existing memories on startup
              -- (requires VectorCode 0.6.12+ for efficient incremental indexing)
              index_on_startup = false,
            },
          }
        }
      }
    }

    require("codecompanion").setup(opts)

    vim.keymap.set("n", "<leader>cc", function()
      local models = vim.iter(pairs(opts.adapters))
          :filter(
          ---@param key string
            function(key)
              return not key:find("claude")
            end)
          :map(
            function(key, value)
              return {
                name = key,
                model = value.schema.model.default
              }
            end)
          :totable()

      vim.ui.select(models, {
        prompt = "Select an adapter:",
        format_item = function(item) return item.name .. " (" .. item.model .. ")" end,
      }, function(item)
        if item then
          -- Execute the CodeCompanionChat command directly with the selected adapter name.
          vim.cmd("CodeCompanionChat " .. item.name)
        else
          vim.notify("No adapter selected", vim.log.levels.WARN)
        end
      end)
    end, { desc = "CodeCompanion Chat" })

    vim.keymap.set("n", "<leader>cs", "<cmd>CodeCompanion<cr>", { desc = "CodeCompanion Inline" })
    vim.keymap.set({ "v" }, "<leader>cs", ":'<,'>CodeCompanion<cr>", { desc = "CodeCompanion Inline" })

    vim.keymap.set({ "n", "v" }, "<leader>ct", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "CodeCompanion Toggle" })

    vim.keymap.set({ "n", "v" }, "<leader>cp", "<cmd>CodeCompanionActions<cr>",
      { desc = "CodeCompanion Actions", noremap = true, silent = true })

    vim.g.codecompanion_auto_tool_mode = true
  end,
}
