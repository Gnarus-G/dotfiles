local M = {}

-- declare union type
---@alias LlmChatType "codecompanion"

---@type table<LlmChatType, integer>
M.nofile_buffers = {} -- A list of buffer of buftype="nofile" with desired content

---@param buf integer
---@param llmtype LlmChatType
function M.add_buffer_for(buf, llmtype)
  M.nofile_buffers[llmtype] = buf
  vim.notify("Added buffer " .. buf .. " for " .. llmtype, vim.log.levels.INFO)
end

---@param llmtype LlmChatType
function M.clear_for(llmtype)
  M.nofile_buffers[llmtype] = nil
  vim.notify("Cleared buffer for " .. llmtype, vim.log.levels.INFO)
end

function M.clear()
  M.nofile_buffers = {}
  vim.notify("Cleared all buffers", vim.log.levels.INFO)
end

function M.is_empty()
  return vim.tbl_isempty(M.nofile_buffers)
end

--- Handling CodeCompanion buffers
local codecompanion_hooks_group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanionChat*",
  group = codecompanion_hooks_group,
  callback = function(event)
    local match_statement = {
      CodeCompanionChatOpened = function() M.add_buffer_for(event.buf, "codecompanion") end,
      CodeCompanionChatClosed = function() M.clear_for("codecompanion") end,
      CodeCompanionChatHidden = function() M.clear_for("codecompanion") end,
    }
    if match_statement[event.match] then
      match_statement[event.match]()
    end
  end,
})

---@param ft LlmChatType
---@return string
function M.get_formatted_context(ft)
  local bufnr = M.nofile_buffers[ft]
  if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return "<chat_with:" .. ft .. ">" .. table.concat(lines, "\n") .. "</chat_with:" .. ft .. ">"
end

return M
