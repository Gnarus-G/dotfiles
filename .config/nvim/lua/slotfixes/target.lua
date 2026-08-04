local M = {}

---@class SlotfixTarget
---@field bufnr integer
---@field changedtick integer
---@field diagnostic_row integer
---@field start_row integer
---@field start_col integer
---@field end_row integer
---@field end_col integer
---@field lines string[]

local function visual_mode()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22"
end

---@param node TSNode
---@param selection table
local function selection_covers(node, selection)
  local start_row, start_col, end_row, end_col = node:range()
  local starts_inside = start_row > selection.start_row or
      (start_row == selection.start_row and start_col >= selection.start_col)
  local ends_inside = end_row < selection.end_row or
      (end_row == selection.end_row and end_col <= selection.end_col)
  return starts_inside and ends_inside
end

---@param bufnr integer
---@return table
local function selection_range(bufnr)
  local first = vim.fn.getpos("v")
  local last = vim.fn.getpos(".")
  if first[2] > last[2] or (first[2] == last[2] and first[3] > last[3]) then
    first, last = last, first
  end

  local range = {
    start_row = first[2] - 1,
    start_col = math.max(first[3] - 1, 0),
    end_row = last[2] - 1,
    end_col = last[3],
  }
  if vim.fn.mode() == "V" then
    range.start_col = 0
    range.end_col = #(vim.api.nvim_buf_get_lines(bufnr, range.end_row, range.end_row + 1, false)[1] or "")
  end
  return range
end

---@param bufnr integer
---@return TSNode?
local function selected_node(bufnr)
  if not visual_mode() then
    return vim.treesitter.get_node({ bufnr = bufnr })
  end

  local selection = selection_range(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { cursor[1] - 1, cursor[2] } })
  while node and node:parent() and selection_covers(node:parent(), selection) do
    node = node:parent()
  end
  return node
end

---@param bufnr integer
---@return SlotfixTarget? target, string? error
function M.capture(bufnr)
  local ok, node = pcall(selected_node, bufnr)
  if not ok or not node then
    return nil, "no Tree-sitter node at the cursor or selection"
  end

  local start_row, start_col, end_row, end_col = node:range()
  return {
    bufnr = bufnr,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    diagnostic_row = vim.api.nvim_win_get_cursor(0)[1] - 1,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {}),
  }
end

---@param target SlotfixTarget
---@param replacement string
---@return string[]
local function replacement_lines(target, replacement)
  local lines = vim.split(replacement, "\n", { plain = true })
  local source_line = vim.api.nvim_buf_get_lines(target.bufnr, target.start_row, target.start_row + 1, false)[1] or ""
  local before_target = source_line:sub(1, target.start_col)
  local indent = before_target:match("^%s*$") and before_target or string.rep(" ", target.start_col)

  return vim.iter(lines):enumerate():map(function(index, line)
    return index > 1 and line ~= "" and (indent .. line) or line
  end):totable()
end

---@param target SlotfixTarget
---@param replacement string
function M.apply(target, replacement)
  if not vim.api.nvim_buf_is_valid(target.bufnr) then
    vim.notify("slotfixes: target buffer no longer exists", vim.log.levels.ERROR)
    return
  end
  if vim.api.nvim_buf_get_changedtick(target.bufnr) ~= target.changedtick then
    vim.notify("slotfixes: buffer changed while fixes were generated; no fix applied", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_text(target.bufnr, target.start_row, target.start_col,
    target.end_row, target.end_col, replacement_lines(target, replacement))
  vim.api.nvim_set_current_buf(target.bufnr)
  vim.api.nvim_win_set_cursor(0, { target.start_row + 1, target.start_col })
end

return M
