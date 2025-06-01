local M = {}

-- declare union type
---@alias LlmChatFileType "codecompanion" | "Avante"

---@type table<LlmChatFileType, integer>
M.nofile_buffers = {} -- A list of buffer of buftype="nofile" with desired content

---@param buf integer
---@param filetype "codecompanion" | "Avante"
function M.add_buffer_for_filetype(buf, filetype)
  M.nofile_buffers[filetype] = buf
end

---@param filetype LlmChatFileType
function M.clear_for_filetype(filetype)
  M.nofile_buffers[filetype] = nil
end

function M.clear()
  M.nofile_buffers = {}
end

function M.is_empty()
  return vim.tbl_isempty(M.nofile_buffers)
end

--- Handling CodeCompanion buffers
local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanionChat*",
  group = group,
  callback = function(event)
    local match_statement = {
      CodeCompanionChatOpened = function() M.add_buffer_for_filetype(event.buf, "codecompanion") end,
      CodeCompanionChatClosed = function() M.clear_for_filetype("codecompanion") end,
      CodeCompanionChatHidden = function() M.clear_for_filetype("codecompanion") end,
    }
    vim.notify("Got CodeCompanionChat event: " .. event.match, vim.log.levels.INFO)
    if match_statement[event.match] then
      match_statement[event.match]()
    end
  end,
})

---@param ft LlmChatFileType
---@return string
function M.get_formatted_context(ft)
  local bufnr = M.nofile_buffers[ft]
  if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return "<" .. ft .. ">" .. table.concat(lines, "\n") .. "</" .. ft .. ">"
end

return M
