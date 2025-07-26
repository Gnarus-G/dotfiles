local extra_files = require("minuet_ctx.extra_files")
local llm_chats = require("minuet_ctx.llm_chats")
local harpoon_ctx = nil -- Lazy-loaded to avoid circular dependency

local function is_file_of_current_buffer(filepath)
  local current_buf_filepath = vim.api.nvim_buf_get_name(0)
  local full_filepath = vim.fn.fnamemodify(filepath, ":p")
  local full_current_buf_filepath = vim.fn.fnamemodify(current_buf_filepath, ":p")
  return full_filepath == full_current_buf_filepath
end

---@return table<string>
local function all_extra_files()
  -- Lazy-load harpoon context to avoid circular dependency
  if not harpoon_ctx then
    harpoon_ctx = require("minuet_ctx.harpoon")
  end
  local files = vim.tbl_extend("force", extra_files.files(), harpoon_ctx.files());
  local git_files, err = require("gnarus.utils").git_modified_or_added_files();
  if err then
    vim.notify("Git status error: " .. err, vim.log.levels.ERROR)
    return files
  end
  return vim.tbl_extend("force", files, git_files)
end

local function read_file_content(filepath)
  local expanded_path = vim.fn.expand(filepath)
  local file = io.open(expanded_path, "r")
  if not file then
    return ""
  end
  local content = file:read("*a")
  file:close()
  return content or ""
end

local function get_formatted_files_context(files)
  ---@type string[]
  local files_contents = vim.iter(files)
      :filter(function(filepath)
        return not is_file_of_current_buffer(filepath)
      end)
      :map(
      ---@return string, string
        function(filepath)
          return read_file_content(filepath), filepath
        end)
      :filter(function(content, _)
        return content ~= ""
      end)
      :map(function(content, filepath)
        return "--- Content from file: " ..
            vim.fn.fnamemodify(filepath, ":t") .. " ---\n" .. content .. "\n--- End of file content ---"
      end)
      :totable();

  return table.concat(files_contents, "\n")
end

local function get_formatted_chats_context()
  local formatted_chats = vim.iter({
        llm_chats.get_formatted_context("codecompanion")
      })
      :filter(function(chat) return chat ~= "" end)
      :totable()
  return table.concat(formatted_chats, "\n")
end

--- Gets all current dynamic context as a formatted string
local function get_formatted_context()
  local files_contents = get_formatted_files_context(all_extra_files())
  local llm_chats_contents = get_formatted_chats_context()

  local combined_content = table.concat(
    vim.iter({ files_contents, llm_chats_contents })
    :filter(function(content) return content ~= "" end)
    :totable(), "\n")

  if combined_content ~= '' then
    combined_content = '<extra_context>\n' .. combined_content .. '\n</extra_contex>'
  end
  return combined_content
end


vim.api.nvim_create_user_command('MinuetClear', function()
  extra_files.clear()
  llm_chats.clear()
end, { nargs = 0 })

vim.api.nvim_create_user_command('MinuetShowContext', function()
  local function get_file_context_data()
    local data = {}

    data.extra_files = extra_files.files()

    data.llm_chats_buffers = {}
    if not llm_chats.is_empty() then
      for ft, b in pairs(llm_chats.nofile_buffers) do
        table.insert(data.llm_chats_buffers, b .. " " .. ft)
      end
    end

    -- Lazy-load harpoon context to avoid circular dependency
    if not harpoon_ctx then
      harpoon_ctx = require("minuet_ctx.harpoon")
    end
    data.harpoon_files = harpoon_ctx.files()

    local git_files, err = require("gnarus.utils").git_modified_or_added_files()
    if err then
      data.git_error = "Git status error: " .. err
    else
      data.git_files = git_files
    end

    return data
  end

  local function format_context_to_markdown_lines(data)
    local content_lines = {}

    local function add_markdown_header(text)
      table.insert(content_lines, "## " .. text)
    end

    local function add_list_item(text)
      table.insert(content_lines, "- " .. text)
    end

    local function add_empty_line()
      table.insert(content_lines, "")
    end

    add_markdown_header("Files")
    if #data.extra_files > 0 then
      for _, f in ipairs(data.extra_files) do add_list_item(f) end
    else
      add_list_item("(none)")
    end
    add_empty_line()

    add_markdown_header("Chat Context Buffers")
    if #data.llm_chats_buffers > 0 then
      for _, b_ft in ipairs(data.llm_chats_buffers) do add_list_item(b_ft) end
    else
      add_list_item("(none)")
    end
    add_empty_line()

    add_markdown_header("Harpoon Files")
    if #data.harpoon_files > 0 then
      for _, f in ipairs(data.harpoon_files) do add_list_item(f) end
    else
      add_list_item("(none)")
    end
    add_empty_line()

    add_markdown_header("Git Modified or Added Files")
    if data.git_error then
      add_list_item(data.git_error)
    else
      if data.git_files and #data.git_files > 0 then
        for _, f in ipairs(data.git_files) do add_list_item(f) end
      else
        add_list_item("(none)")
      end
    end

    return content_lines
  end

  local function display_lines_in_floating_window(lines)
    local height = #lines
    local max_line_len = 0
    for _, line in ipairs(lines) do
      max_line_len = math.max(max_line_len, #line)
    end
    local width = math.max(40, max_line_len + 2) -- Min width 40, +2 for padding
    width = math.min(width, vim.o.columns - 4)   -- Cap at screen width minus margin

    height = math.min(height, vim.o.lines - 4)   -- Cap at screen height minus margin

    local row = math.max(0, math.floor((vim.o.lines - height) / 2))
    local col = math.max(0, math.floor((vim.o.columns - width) / 2))

    local buf = vim.api.nvim_create_buf(false, true) -- no_name, scratch

    -- Set buffer options directly on the buffer object
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = 'markdown'

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Explicitly make the buffer non-modifiable programmatically after setting content
    vim.bo[buf].readonly = true -- Sets buffer as read-only for the user interface
    vim.bo[buf].modifiable = false

    local win_id = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      row = row,
      col = col,
      width = width,
      height = height,
      border = 'single',
      style = 'minimal',
      focusable = true,
    })

    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', ':close<CR>', { noremap = true, silent = true })

    vim.api.nvim_set_current_win(win_id)
  end

  local context_data = get_file_context_data()
  local formatted_lines = format_context_to_markdown_lines(context_data)
  display_lines_in_floating_window(formatted_lines)
end, { nargs = 0 })


-- Sync minuet context with harpoon files at startup
vim.defer_fn(function()
  if not harpoon_ctx then
    harpoon_ctx = require("minuet_ctx.harpoon")
  end
  harpoon_ctx.sync()
end, 100)


return {
  files = all_extra_files,
  get_formatted_context = get_formatted_context
}
