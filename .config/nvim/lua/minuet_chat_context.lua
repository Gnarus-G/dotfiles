local M = {}

-- declare union type
---@alias LlmChatType "codecompanion" | "avante"

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

local avante_open_close_group = vim.api.nvim_create_augroup("AvanteOpenClose", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = avante_open_close_group,
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].filetype == "Avante" then
      M.add_buffer_for(args.buf, "avante")
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufWipeout" }, {
  group = avante_open_close_group,
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].filetype == "Avante" then
      M.clear_for("avante")
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
  return "<" .. ft .. ">" .. table.concat(lines, "\n") .. "</" .. ft .. ">"
end

return M
