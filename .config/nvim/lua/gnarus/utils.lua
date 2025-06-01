--- @param buf number Buffer number
--- @return boolean
local is_too_much = function(buf)
  local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
  local max = (1024 * 1024 * 1) -- 1 Megabyte max
  return byte_size > max
end

return {
  -- Filters out files that are too large (greater than 1 Megabyte)
  ---@return integer[]
  get_visible_buffers = function()
    return vim.iter(vim.api.nvim_list_wins())
        :map(function(win) return vim.api.nvim_win_get_buf(win) end)
        :filter(function(buf)
          return not is_too_much(buf) and vim.api.nvim_buf_is_loaded(buf)
        end)
        :totable()
  end,
  get_buffer_text_content =
  ---@param buf number
  ---@return string
      function(buf)
        return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      end
}
