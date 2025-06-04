local M = {}

---@type string[]
M._dynamic_files = {} -- A list of file paths

--- Adds a file to the dynamic context list
--- @param filepath string The path to the file
function M.add_file(filepath)
  filepath = vim.fn.expand(filepath) -- ensuring expansion
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("MinuetExtraFilesContext: File not readable: " .. filepath, vim.log.levels.WARN)
    return
  end

  for _, existing_path in ipairs(M._dynamic_files) do
    if existing_path == filepath then
      vim.notify("MinuetExtraFilesContext: File already added: " .. filepath, vim.log.levels.INFO)
      return
    end
  end
  table.insert(M._dynamic_files, filepath)
  vim.notify("MinuetExtraFilesContext: Added file: " .. vim.fn.fnamemodify(filepath, ":~:."))
end

--- Removes a file from the dynamic context list
--- @param filepath string The path to the file
function M.remove_file(filepath)
  filepath = vim.fn.expand(filepath) -- Ensure filepath is expanded
  local original_count = #M._dynamic_files
  M._dynamic_files = vim.iter(M._dynamic_files):filter(function(path)
    return path ~= filepath --
  end):totable()
  local removed = original_count > #M._dynamic_files

  if removed then
    vim.notify("MinuetExtraFilesContext: Removed file: " .. vim.fn.fnamemodify(filepath, ":~:."))
  else
    vim.notify("MinuetExtraFilesContext: File not found in list: " .. vim.fn.fnamemodify(filepath, ":~:."),
      vim.log.levels.INFO)
  end
end

function M.clear()
  M._dynamic_files = {}
  vim.notify("MinuetExtraFilesContext: Cleared all files.")
end

--- Adds a buffer to the dynamic context list
--- @param buf_identifier string|integer Buffer name, pattern, or number
function M.add_buffer(buf_identifier)
  local bufnr
  if type(buf_identifier) == "number" then
    bufnr = buf_identifier
  else
    bufnr = vim.fn.bufnr(buf_identifier)
  end

  if bufnr == -1 or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("MinuetExtraFilesContext: Invalid buffer identifier: " .. tostring(buf_identifier), vim.log.levels.WARN)
    return
  end

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    vim.notify("MinuetExtraFilesContext: Cannot add unnamed buffer " .. tostring(bufnr), vim.log.levels.WARN)
    return
  end

  M.add_file(filepath)
end

-- Commands for Minuet Dynamic Context
-- (Ensure 'minuet_extra_context' module is available in your lua path, e.g., ~/.config/nvim/lua/minuet_extra_context.lua)

-- Command to add a file to Minuet's dynamic context using snacks.nvim picker
vim.api.nvim_create_user_command('MinuetAddFile', function()
  local home = os.getenv("HOME") .. "/"
  Snacks.picker.files({
    cwd = home,
    hidden = true,
    confirm = function(picker, item)
      picker:close()
      local filepath = item.cwd .. "/" .. item.file
      M.add_file(filepath)
    end,
  })
end, { nargs = 0 })

vim.api.nvim_create_user_command('MinuetAddBuffer', function(opts)
  if opts.fargs[1] then
    M.add_buffer(opts.fargs[1])
  else
    Snacks.picker.buffers({
      confirm = function(picker, item)
        picker:close()
        M.add_file(item.file)
      end,
    })
  end
end, { nargs = "?", complete = 'buffer' })

vim.api.nvim_create_user_command('MinuetRemoveFile', function(opts)
  if opts.fargs[1] then
    M.remove_file(opts.fargs[1])
  else
    if #M._dynamic_files == 0 then
      vim.notify("MinuetExtraFilesContext: No files in list to remove.", vim.log.levels.INFO)
      return
    end

    local picker_items = {}
    for _, full_path in ipairs(M._dynamic_files) do
      table.insert(picker_items, {
        value = full_path,
        formatted = vim.fn.fnamemodify(full_path, ":t") .. " (" .. vim.fn.fnamemodify(full_path, ":~:.") .. ")"
      })
    end

    vim.ui.select(picker_items, {
      prompt = "Remove file from Minuet Dynamic Context: ",
      format_item = function(item)
        return item.formatted
      end,
      kind = "Minuet Extra Context Files",
    }, function(selected_item, _)
      if selected_item and selected_item.value then
        M.remove_file(selected_item.value)
      end
    end)
  end
end, { nargs = "?", complete = 'file' })


function M.files()
  return vim.deepcopy(M._dynamic_files)
end

return M
