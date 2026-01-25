local env_cascade = require("gnarus.utils").env_var_cascade

local chat_adapter = env_cascade({
  { vars = { "GNARUS_ALLOW_VENDOR_LLM", "GEMINI_API_KEY" },    value = { name = "gemini" } },
  { vars = { "GNARUS_ALLOW_VENDOR_LLM" },                      value = { name = "ollama", model = "minimax-m2.1:cloud" } },
  { vars = { "GNARUS_ALLOW_VENDOR_LLM", "OPENAI_API_KEY" },    value = { name = "openai" } },
  { vars = { "GNARUS_ALLOW_VENDOR_LLM", "ANTHROPIC_API_KEY" }, value = { name = "anthropic", model = "claude-opus-4-5" } },
}, { name = "ollama" })

local inline_adapter = env_cascade({
  { vars = { "GNARUS_ALLOW_VENDOR_LLM" },                      value = { name = "ollama", model = "devstral-2:123b-cloud" } },
  { vars = { "GNARUS_ALLOW_VENDOR_LLM", "GEMINI_API_KEY" },    value = { name = "gemini_fast" } },
  { vars = { "GNARUS_ALLOW_VENDOR_LLM", "OPENAI_API_KEY" },    value = { name = "openai_fast" } },
  { vars = { "GNARUS_ALLOW_VENDOR_LLM", "ANTHROPIC_API_KEY" }, value = { name = "anthropic", model = "claude-haiku-4-5" } },
}, { name = "ollama" })

---@param adapter CodeCompanion.HTTPAdapter
---@return string
local function llm_role_title(adapter)
  return "CodeCompanion (" .. adapter.name .. ")"
end

--- Detect filetype from a filepath and optional content
---@param filepath string
---@param content string?
---@return string
local function detect_filetype(filepath, content)
  -- 1) filename-based detection
  local ft = vim.filetype.match({ filename = filepath })
  if ft and ft ~= "" then return ft end

  -- 2) content-based detection
  if content and content ~= "" then
    local lines = vim.split(content, "\n", { plain = true })
    ft = vim.filetype.match({ contents = lines })
    if ft and ft ~= "" then return ft end
  end

  -- 3) fallback to cleaned basename (strip leading dots), else "text"
  local basename = vim.fs.basename(filepath or "")
  local fallback = basename and basename:gsub("^%.+", "") or nil
  if fallback and fallback ~= "" then
    return fallback
  end

  return "text"
end

---@param filepath string should be relative
---@param chat CodeCompanion.Chat
local function add_file_to_codecompanion_chat(filepath, chat)
  local file, err = io.open(filepath, "r")
  if not file then
    return vim.notify("Error opening file: " .. err, vim.log.levels.ERROR)
  end
  local content = file:read("*a")
  file:close()

  local filetype = detect_filetype(filepath, content)
  local title    = "<attachment filepath=\"" .. filepath .. "\">"
  local body     = "Here is the content from the file:\n\n" .. "```" .. filetype .. "\n" .. content
  local footer   = "```\n</attachment>"

  local filename = vim.fn.fnamemodify(filepath, ":~:.")
  chat:add_context({ role = "user", content = title .. body .. footer }, filepath,
    "<file>" .. filename .. "</file>")
end

---@param codecompanion CodeCompanion
local function setup_extra_keymaps(codecompanion)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "NvimTree",
    callback = function()
      vim.keymap.set("n",
        "<leader>cf",
        function()
          ---@type boolean, nvim_tree.api.Node
          local ok, node = pcall(require("nvim-tree.api").tree.get_node_under_cursor);
          if not ok or node == nil then
            return vim.notify("Could not get node under cursor in NvimTree", vim.log.levels.WARN,
              { title = "CodeCompanion" })
          end

          local chat = codecompanion.last_chat() or codecompanion.chat();
          if not chat then
            return vim.notify("Failed to get chat instance.", vim.log.levels.ERROR, { title = "CodeCompanion" })
          end

          chat.ui:open();

          if node.type == "file" then
            add_file_to_codecompanion_chat(node.absolute_path, chat)
          elseif node.type == "directory" then
            local all_files = vim.tbl_filter(function(f) return vim.fn.filereadable(f) == 1 end,
              vim.fn.systemlist("fd --type f --max-depth 2 . " .. node.absolute_path))

            if all_files and #all_files > 0 then
              vim.iter(all_files)
                  :each(function(file)
                    add_file_to_codecompanion_chat(file, chat)
                  end)
            else
              vim.notify("No files found in directory: " .. node.absolute_path, vim.log.levels.INFO,
                { title = "CodeCompanion" })
            end
          end
        end,
        { desc = "Select file in NvimTree and add to codecompanion chat", buffer = true }
      )
    end
  })

  ---@param cb fun(prompt: string)
  local function inline_prompt_input_with_cmd(cb)
    return function()
      vim.ui.input({
        prompt = "Prompt",
        win = {
          bo = {
            filetype = "codecompanion"
          }
        }
      }, function(value)
        if value and value ~= "" then
          cb(value)
        end
      end)
    end
  end

  vim.keymap.set("n", "<leader>cs", inline_prompt_input_with_cmd(function(value)
      vim.cmd.CodeCompanion(value)
    end),
    { desc = "CodeCompanion Inline", noremap = true, silent = true })

  vim.keymap.set({ "v" }, "<leader>cs", inline_prompt_input_with_cmd(function(value)
      vim.cmd(":'<,'>CodeCompanion " .. value)
    end),
    { desc = "CodeCompanion Inline", noremap = true, silent = true })

  vim.keymap.set({ "n", "v" }, "<leader>cc", "<cmd>CodeCompanionChat<cr>",
    { desc = "CodeCompanion Chat", noremap = true, silent = true })

  vim.keymap.set({ "n", "v" }, "<leader>ct", "<cmd>CodeCompanionChat Toggle<cr>",
    { desc = "CodeCompanion Toggle", noremap = true, silent = true })

  vim.keymap.set({ "n", "v" }, "<leader>cl", "<cmd>CodeCompanionHistory<cr>",
    { desc = "CodeCompanion Browse Last Chat", noremap = true, silent = true })

  vim.keymap.set({ "n", "v" }, "<leader>cp", "<cmd>CodeCompanionActions<cr>",
    { desc = "CodeCompanion Actions", noremap = true, silent = true })
end

local function extend_cmp_completions()
  local cmp = require("cmp")
  cmp.setup.filetype("codecompanion", {
    formatting = {
      format = require("lspkind").cmp_format({
        menu = {
          codecompanion_tools = "[tool]",
          codecompanion_variables = "[var]",
          codecompanion_models = "[model]",
          codecompanion_slash_commands = "[cmd]",
        },
      })
    },
  })
end

return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim", branch = "master" },
    "nvim-treesitter/nvim-treesitter",
    "ravitemer/codecompanion-history.nvim",
  },
  config = function()
    local opts = {
      rules = {
        opts = {
          chat = {
            enabled = true,
            autoload = { "default", "gnarus" }
          },
        },
        gnarus = {
          description = "Gnarus memory files",
          files = {
            "~/.config/nvim/lua/gnarus/fp-system-prompt.md",
          },
        },
      },
      interactions = {
        chat = {
          adapter = chat_adapter,
          roles = {
            ---The header name for the LLM's messages
            ---@type string|fun(adapter: CodeCompanion.HTTPAdapter): string
            llm = llm_role_title,
          },
          tools = {
            ["insert_edit_into_file"] = {
              opts = {
                require_approval_before = false,
              },
            },
            groups = {
              ["smart"] = {
                prompt =
                "You're a meticulous software engineer who is proactive about filling knowledge gaps before making assumptions, using tools like ${tools}",
                tools = {
                  "neovim__list_directory",
                  "neovim__find_files",
                  "neovim__read_file",
                  "neovim__read_multiple_files",
                  "context7_mcp__resolve_library_id",
                  "context7_mcp__get_library_docs",
                  "ez_web_search_mcp__search",
                  "fetch_mcp__fetch_html",
                  "fetch_mcp__fetch_markdown",
                  "fetch_mcp__fetch_markdown",
                  "fetch_mcp__fetch_txt",
                  "sequentialthinking__sequentialthinking",
                },
                opts = {
                  collapse_tools = false, -- When true, show as a single group reference instead of individual tools
                },
              },
              ["smart_dev"] = {
                prompt =
                "You're a meticulous software engineer who always looks things up before making decisions, using tools like ${tools}",
                tools = {
                  "neovim__list_directory",
                  "neovim__find_files",
                  "neovim__read_file",
                  "neovim__read_multiple_files",
                  "context7_mcp__resolve_library_id",
                  "context7_mcp__get_library_docs",
                  "ez_web_search_mcp__search",
                  "fetch_mcp__fetch_html",
                  "fetch_mcp__fetch_markdown",
                  "fetch_mcp__fetch_markdown",
                  "fetch_mcp__fetch_txt",
                  "sequentialthinking__sequentialthinking",

                  "neovim__execute_command",
                  "get_changed_files",
                  "grep_search",
                  "list_code_usages",

                  "neovim__write_file",
                  "neovim__edit_file",
                  -- "insert_edit_into_file",
                },
                opts = {
                  collapse_tools = false, -- When true, show as a single group reference instead of individual tools
                },
              },
            },
            opts = {
              default_tools = {
                "gnarus",
                "context7_mcp",
                "ez_web_search_mcp",
                "fetch_mcp",
                "sequentialthinking"
              },
              auto_submit_errors = true,  -- Send any errors to the LLM automatically?
              auto_submit_success = true, -- Send any successful output to the LLM automatically?
            }
          },
          slash_commands = {
            ["dir"] = {
              description = "Select files from your home and add them as references to the current chat",
              ---@param chat CodeCompanion.Chat
              callback = function(chat)
                local home = vim.loop.os_homedir()
                local dirs_therein = vim.fn.systemlist("fd --type d --max-depth 6 . " .. home)

                vim.ui.select(dirs_therein, {
                    prompt = "Select"
                  },
                  function(dir)
                    local files_in_dir = vim.tbl_filter(function(f) return vim.fn.filereadable(f) == 1 end,
                      vim.fn.systemlist("fd --type f --max-depth 2 . " .. dir))

                    if files_in_dir and #files_in_dir > 0 then
                      vim.iter(files_in_dir)
                          :each(function(filepath)
                            add_file_to_codecompanion_chat(filepath, chat)
                          end)
                    else
                      vim.notify("No files found in directory: " .. dir, vim.log.levels.INFO, { title = "CodeCompanion" })
                    end
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
                          add_file_to_codecompanion_chat(file, chat)
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
                contains_code = true,
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
                contains_code = true,
              },
            }
          },
          variables = {},
        },
        inline = {
          adapter = inline_adapter,
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
      },
      display = {
        diff = {
          enabled = true,
          close_chat_at = 80,  -- Close an open chat buffer if the total columns of your display are less than...
          layout = "vertical", -- vertical|horizontal split for default provider
          opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
          provider = "inline", -- default|mini_diff|inline
        },
        chat = { window = { position = "right" }, show_settings = false },
        action_palette = {
          opts = {
            show_preset_prompts = false,
          },
        },
      },
      prompt_library = {
        ["Generate a Commit Message"] = {
          opts = {
            is_slash_cmd = false,
          },
        },
      },
      opts = {
        log_level = "ERROR", -- TRACE|DEBUG|ERROR|INFO
      },
      adapters = {
        http = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              env = { url = os.getenv("OLLAMA_API_BASE") or "http://localhost:11434" },
              schema = {
                model = { default = "gpt-oss:latest" },
                temperature = { default = 0 },
                keep_alive = { default = "30m" },
              },
              parameters = { sync = true },
            })
          end,

          gemini = function()
            return require("codecompanion.adapters").extend("gemini", {
              schema = {
                model = { default = "gemini-3-flash-preview" },
                reasoning_effort = { default = "medium" },
              },
            })
          end,

          gemini_fast = function()
            return require("codecompanion.adapters").extend("gemini", {
              schema = {
                model = { default = "gemini-3-flash-preview" },
                reasoning_effort = { default = "none" },
              },
            })
          end,

          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              opts = { stream = true },
              schema = {
                model = {
                  default = "gpt-5.2",
                  choices = {
                    ["gpt-5.2"] = { formatted_name = "GPT 5.2", opts = { has_vision = true, can_reason = true } },
                    ["gpt-5.1"] = { formatted_name = "GPT 5.1", opts = { has_vision = true, can_reason = true } },
                    ["gpt-5"] = { formatted_name = "GPT 5", opts = { has_vision = true, can_reason = true } },
                    ["gpt-5-mini"] = { formatted_name = "GPT 5 Mini", opts = { has_vision = true, can_reason = true } },
                    ["gpt-5-nano"] = { formatted_name = "GPT 5 Nano", opts = { has_vision = true, can_reason = true } },
                    ["o4-mini-2025-04-16"] = { formatted_name = "o4 Mini", opts = { has_vision = true, can_reason = true } },
                    ["o3-mini-2025-01-31"] = { formatted_name = "o3 Mini", opts = { can_reason = true } },
                    ["o3-2025-04-16"] = { formatted_name = "o3", opts = { has_vision = true, can_reason = true } },
                    ["o1-2024-12-17"] = { formatted_name = "o1", opts = { has_vision = true, can_reason = true } },
                    ["gpt-4.1"] = { formatted_name = "GPT 4.1", opts = { has_vision = true } },
                    ["gpt-4o"] = { formatted_name = "GPT-4o", opts = { has_vision = true } },
                    ["gpt-4o-mini"] = { formatted_name = "GPT-4o Mini", opts = { has_vision = true } },
                    ["gpt-4-turbo-preview"] = { formatted_name = "GPT-4 Turbo Preview", opts = { has_vision = true } },
                    "gpt-4",
                    "gpt-3.5-turbo",
                  },
                },
                reasoning_effort = { default = "medium" },
              },
            })
          end,

          openai_fast = function()
            return require("codecompanion.adapters").extend("openai", {
              opts = { stream = true },
              schema = {
                model = {
                  default = "gpt-5-mini",
                },
                reasoning_effort = { default = "low" },
              },
            })
          end,
        },
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
            picker = "snacks", --- ("telescope", "snacks", "fzf-lua", or "default")
            ---Optional filter function to control which chats are shown when browsing
            chat_filter = nil, -- function(chat_data) return boolean end
            -- Customize picker keymaps (optional)
            picker_keymaps = {
              rename = { n = "r", i = "<M-r>" },
              delete = { n = "d", i = "<M-d>" },
              duplicate = { n = "<C-y>", i = "<C-y>" },
            },
            ---Automatically generate titles for new chats
            auto_generate_title = true,
            title_generation_opts = {
              adapter = inline_adapter,
              refresh_every_n_prompts = 1,
              max_refreshes = 3,
            },
            ---On exiting and entering neovim, loads the last chat on opening chat
            continue_last_chat = false,
            ---When chat is cleared with `gx` delete the chat from history
            delete_on_clearing_chat = true,
            ---Directory path to save the chats
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            ---Enable detailed logging for history extension
            enable_logging = false,

            -- Summary system
            summary = {
              create_summary_keymap = "<leader>gsc",
              browse_summaries_keymap = "<leader>gsb",

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
    ---@class CodeCompanion
    ---@diagnostic disable-next-line: assign-type-mismatch
    local codecompanion = require("codecompanion")
    codecompanion.setup(opts)

    vim.g.codecompanion_auto_tool_mode = true

    setup_extra_keymaps(codecompanion)
    extend_cmp_completions()
  end,
}
