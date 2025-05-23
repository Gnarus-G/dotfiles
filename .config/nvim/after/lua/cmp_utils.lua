---@return integer[]
local get_visible_buffers = function()
  local is_too_much = function(buf)
    local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
    local max = (1024 * 1024 * 1) -- 1 Megabyte max
    return byte_size > max
  end

  local bufs = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not is_too_much(buf) then
      bufs[buf] = true
    end
  end
  return vim.tbl_keys(bufs)
end

return {
  get_visible_buffers = get_visible_buffers,
}
