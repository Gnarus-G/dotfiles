local M = {}

local loading_namespace = vim.api.nvim_create_namespace("slotfixes_loading")

---@param target SlotfixTarget
local function target_end(target)
  local line_count = vim.api.nvim_buf_line_count(target.bufnr)
  if target.end_row < line_count then return target.end_row, target.end_col end
  local row = line_count - 1
  local line = vim.api.nvim_buf_get_lines(target.bufnr, row, row + 1, false)[1] or ""
  return row, #line
end

---@param target SlotfixTarget
---@param presentation table
---@return function stop
function M.start_loading(target, presentation)
  local frames = { "-", "\\", "|", "/" }
  local prompt = presentation.prompt:gsub("%s+", " ")
  local indent = string.rep(" ", target.start_col)
  local end_row, end_col = target_end(target)
  local timer = vim.uv.new_timer()
  local active = true
  local frame = 1
  local marks = {}

  local function render()
    if not active or not vim.api.nvim_buf_is_valid(target.bufnr) then return end
    local indicator = frames[frame]
    marks[1] = vim.api.nvim_buf_set_extmark(target.bufnr, loading_namespace, target.start_row, target.start_col, {
      id = marks[1],
      right_gravity = false,
      virt_lines = { { { string.format("%s[%s %s] %s", indent, presentation.model, indicator, prompt), "DiagnosticInfo" } } },
      virt_lines_above = true,
    })
    marks[2] = vim.api.nvim_buf_set_extmark(target.bufnr, loading_namespace, end_row, end_col, {
      id = marks[2],
      right_gravity = true,
      virt_lines = { { { string.format("%s[%s %s]", indent, presentation.model, indicator), "DiagnosticInfo" } } },
    })
    frame = frame % #frames + 1
  end

  render()
  timer:start(120, 120, vim.schedule_wrap(render))

  return function()
    if not active then return end
    active = false
    timer:stop()
    timer:close()
    if not vim.api.nvim_buf_is_valid(target.bufnr) then return end
    for _, mark in ipairs(marks) do
      pcall(vim.api.nvim_buf_del_extmark, target.bufnr, loading_namespace, mark)
    end
  end
end

local function choice_keys(replacements)
  return vim.iter(replacements):enumerate():map(function(index)
    return tostring(index)
  end):totable()
end

local function quoted(text)
  return vim.iter(vim.split(text, "\n", { plain = true })):map(function(line)
    return "> " .. line
  end):totable()
end

local function choice_lines(target, replacements, presentation)
  local lines = {
    "# Fix candidates",
    "",
    string.format("`%s` | reasoning `%s`", presentation.model, presentation.reasoning),
    "",
    "> **Prompt**",
  }
  vim.list_extend(lines, quoted(presentation.prompt))
  for index, replacement in ipairs(replacements) do
    vim.list_extend(lines, { "", string.format("## Option %d", index), "```" .. vim.bo[target.bufnr].filetype })
    vim.list_extend(lines, vim.split(replacement, "\n", { plain = true }))
    table.insert(lines, "```")
  end
  vim.list_extend(lines, { "", "---", "", "## System prompt", "" })
  vim.list_extend(lines, quoted(presentation.system_prompt))
  return lines
end

local function window_size()
  return math.min(math.max(40, math.floor(vim.o.columns * 0.8)), vim.o.columns - 4),
      math.min(math.max(10, math.floor(vim.o.lines * 0.8)), vim.o.lines - 4)
end

---@param target SlotfixTarget
---@param replacements string[]
---@param presentation table
---@param select fun(replacement: string)
function M.show_choices(target, replacements, presentation, select)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, choice_lines(target, replacements, presentation))
  vim.bo[buf].modifiable = false

  local width, height = window_size()
  local keys = choice_keys(replacements)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
    style = "minimal",
    title = " slotfixes review ",
    title_pos = "center",
    footer = string.format(" %s apply | Esc cancel ", table.concat(keys, " / ")),
    footer_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:DiagnosticInfo,FloatTitle:DiagnosticInfo"

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  for index, replacement in ipairs(replacements) do
    vim.keymap.set("n", tostring(index), function()
      close()
      select(replacement)
    end, { buffer = buf, nowait = true, silent = true })
  end
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, silent = true })
end

return M
