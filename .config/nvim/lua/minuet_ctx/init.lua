local extra_files = require("minuet_ctx.extra_files")
local llm_chats = require("minuet_ctx.llm_chats")
local harpoon_ctx = require("minuet_ctx.harpoon")

local function is_file_of_current_buffer(filepath)
  local current_buf_filepath = vim.api.nvim_buf_get_name(0)
  local full_filepath = vim.fn.fnamemodify(filepath, ":p")
  local full_current_buf_filepath = vim.fn.fnamemodify(current_buf_filepath, ":p")
  return full_filepath == full_current_buf_filepath
end

local function get_formatted_files_context()
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

  local files = vim.tbl_extend("force", extra_files.files(), harpoon_ctx.files())

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
  local files_contents = get_formatted_files_context()
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
  local files = extra_files.files()
  vim.notify("--- Files ---", vim.log.levels.INFO)
  if #files > 0 then
    for _, f in ipairs(files) do vim.notify("- " .. f, vim.log.levels.INFO) end
  else
    vim.notify("(none)", vim.log.levels.INFO)
  end

  vim.notify("--- Chat Context Buffers ---", vim.log.levels.INFO)
  if not llm_chats.is_empty() then
    for ft, b in pairs(llm_chats.nofile_buffers) do
      vim.notify("- " .. b .. " " .. ft, vim.log.levels.INFO)
    end
  else
    vim.notify("(none)", vim.log.levels.INFO)
  end

  vim.notify("--- Harpoon Files ---", vim.log.levels.INFO)
  local harpoon_files = harpoon_ctx.files()
  if #harpoon_files > 0 then
    for _, f in ipairs(harpoon_files) do vim.notify("- " .. f, vim.log.levels.INFO) end
  else
    vim.notify("(none)", vim.log.levels.INFO)
  end

  -- or this more comprehensive view
  --[[ local combined_content = get_formatted_context() ]]
  --[[ vim.notify("Commbined Content", vim.log.levels.DEBUG) ]]
  --[[ vim.notify(combined_content, vim.log.levels.DEBUG) ]]
end, { nargs = 0 })

harpoon_ctx.sync()

return {
  files = function()
    return vim.tbl_extend("force", extra_files.files(), harpoon_ctx.files())
  end,
  get_formatted_context = get_formatted_context
}
