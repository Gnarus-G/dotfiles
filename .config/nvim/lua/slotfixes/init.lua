local M = {}

M.config = {
  count = 3,
  context_lines = 40,
  keymap = "<leader>cf",
  model = "openai-codex/gpt-5.6-luna",
  prompt = "Fix the diagnostics on this line.",
}

M.state = { running = false }

local SYSTEM_PROMPT = table.concat({
  "You generate a replacement for one selected syntax node.",
  "Return exactly one <slotfix>...</slotfix> element and nothing else.",
  "Inside the element, return only replacement source code: no Markdown fence or explanation.",
  "The first line must begin at column zero; indent later lines relative to the first line.",
  "Preserve behavior unrelated to the request and make the smallest correct change.",
}, " ")

local severity_names = {
  [vim.diagnostic.severity.ERROR] = "ERROR",
  [vim.diagnostic.severity.WARN] = "WARN",
  [vim.diagnostic.severity.INFO] = "INFO",
  [vim.diagnostic.severity.HINT] = "HINT",
}

local loading_namespace = vim.api.nvim_create_namespace("slotfixes_loading")

---@param target table
---@param request string
---@return function stop
local function start_loading(target, request)
  local frames = { "-", "\\", "|", "/" }
  local ghost_prompt = request:gsub("%s+", " ")
  local frame = 1
  local active = true
  local timer = vim.uv.new_timer()
  local start_mark
  local end_mark
  local end_row = target.end_row
  local end_col = target.end_col
  local line_count = vim.api.nvim_buf_line_count(target.bufnr)
  if end_row >= line_count then
    end_row = line_count - 1
    end_col = #(vim.api.nvim_buf_get_lines(target.bufnr, end_row, end_row + 1, false)[1] or "")
  end

  local function render()
    if not active or not vim.api.nvim_buf_is_valid(target.bufnr) then return end
    local indicator = frames[frame]
    start_mark = vim.api.nvim_buf_set_extmark(target.bufnr, loading_namespace, target.start_row, target.start_col, {
      id = start_mark,
      right_gravity = false,
      virt_text = { { string.format("[slotfixes %s] %s -> ", indicator, ghost_prompt), "DiagnosticInfo" } },
      virt_text_pos = "inline",
    })
    end_mark = vim.api.nvim_buf_set_extmark(target.bufnr, loading_namespace, end_row, end_col, {
      id = end_mark,
      right_gravity = true,
      virt_text = { { string.format(" <- [slotfixes %s]", indicator), "DiagnosticInfo" } },
      virt_text_pos = "inline",
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
    if vim.api.nvim_buf_is_valid(target.bufnr) then
      if start_mark then pcall(vim.api.nvim_buf_del_extmark, target.bufnr, loading_namespace, start_mark) end
      if end_mark then pcall(vim.api.nvim_buf_del_extmark, target.bufnr, loading_namespace, end_mark) end
    end
  end
end

local function visual_mode()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22"
end

---@param node TSNode
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@return boolean
local function selection_covers(node, start_row, start_col, end_row, end_col)
  local node_start_row, node_start_col, node_end_row, node_end_col = node:range()
  local starts_inside = node_start_row > start_row or
      (node_start_row == start_row and node_start_col >= start_col)
  local ends_inside = node_end_row < end_row or
      (node_end_row == end_row and node_end_col <= end_col)
  return starts_inside and ends_inside
end

---@param bufnr integer
---@return TSNode?
local function selected_node(bufnr)
  if not visual_mode() then
    return vim.treesitter.get_node({ bufnr = bufnr })
  end

  local first = vim.fn.getpos("v")
  local last = vim.fn.getpos(".")
  if first[2] > last[2] or (first[2] == last[2] and first[3] > last[3]) then
    first, last = last, first
  end

  local start_row = first[2] - 1
  local end_row = last[2] - 1
  local start_col = math.max(first[3] - 1, 0)
  local end_col = last[3]
  if vim.fn.mode() == "V" then
    start_col = 0
    end_col = #(vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or "")
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { cursor[1] - 1, cursor[2] } })
  while node and node:parent() and selection_covers(node:parent(), start_row, start_col, end_row, end_col) do
    node = node:parent()
  end
  return node
end

---@param bufnr integer
---@return table? target, string? err
local function capture_target(bufnr)
  local ok, node = pcall(selected_node, bufnr)
  if not ok or not node then
    return nil, "no Tree-sitter node at the cursor or selection"
  end

  local start_row, start_col, end_row, end_col = node:range()
  local lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
  return {
    bufnr = bufnr,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    diagnostic_row = vim.api.nvim_win_get_cursor(0)[1] - 1,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    lines = lines,
  }
end

---@param diagnostic vim.Diagnostic
---@return string
local function format_diagnostic(diagnostic)
  local severity = severity_names[diagnostic.severity] or "UNKNOWN"
  local origin = {}
  if diagnostic.source then table.insert(origin, diagnostic.source) end
  if diagnostic.code then table.insert(origin, tostring(diagnostic.code)) end
  local attribution = #origin > 0 and (" (" .. table.concat(origin, "/") .. ")") or ""
  return string.format("- %d:%d [%s]%s %s", diagnostic.lnum + 1, diagnostic.col + 1,
    severity, attribution, diagnostic.message:gsub("\n", " "))
end

---@param target table
---@param request string
---@param alternative integer
---@return string
local function build_prompt(target, request, alternative)
  local bufnr = target.bufnr
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local context_start = math.max(0, target.start_row - M.config.context_lines)
  local context_end = math.min(line_count, target.end_row + M.config.context_lines + 1)
  local context = vim.api.nvim_buf_get_lines(bufnr, context_start, context_end, false)
  local diagnostics = vim.diagnostic.get(bufnr, {
    lnum = target.diagnostic_row,
  })

  local diagnostic_lines = vim.iter(diagnostics):map(format_diagnostic):totable()
  if #diagnostic_lines == 0 then
    diagnostic_lines = { "- (none)" }
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then path = "[No Name]" end

  return table.concat({
    request,
    string.format("Generate alternative %d of %d; prefer a distinct valid fix where reasonable.", alternative, M.config.count),
    string.format("File: %s", vim.fn.fnamemodify(path, ":~:.")),
    string.format("Language: %s", vim.bo[bufnr].filetype),
    string.format("Target range: %d:%d-%d:%d", target.start_row + 1, target.start_col + 1,
      target.end_row + 1, target.end_col + 1),
    "Diagnostics on the target line:",
    table.concat(diagnostic_lines, "\n"),
    "<target>",
    table.concat(target.lines, "\n"),
    "</target>",
    string.format('<context start-line="%d">', context_start + 1),
    table.concat(context, "\n"),
    "</context>",
  }, "\n")
end

---@param output string
---@return string?
local function parse_replacement(output)
  local replacement = output:match("<slotfix>%s*(.-)%s*</slotfix>")
  if not replacement or replacement == "" then return nil end
  return replacement
end

---@param target table
---@param replacement string
local function apply_replacement(target, replacement)
  if not vim.api.nvim_buf_is_valid(target.bufnr) then
    vim.notify("slotfixes: target buffer no longer exists", vim.log.levels.ERROR)
    return
  end
  if vim.api.nvim_buf_get_changedtick(target.bufnr) ~= target.changedtick then
    vim.notify("slotfixes: buffer changed while fixes were generated; no fix applied", vim.log.levels.WARN)
    return
  end

  local lines = vim.split(replacement, "\n", { plain = true })
  local source_line = vim.api.nvim_buf_get_lines(target.bufnr, target.start_row, target.start_row + 1, false)[1] or ""
  local before_target = source_line:sub(1, target.start_col)
  local continuation_indent = before_target:match("^%s*$") and before_target or string.rep(" ", target.start_col)
  for index = 2, #lines do
    if lines[index] ~= "" then
      lines[index] = continuation_indent .. lines[index]
    end
  end

  vim.api.nvim_buf_set_text(target.bufnr, target.start_row, target.start_col,
    target.end_row, target.end_col, lines)
  vim.api.nvim_set_current_buf(target.bufnr)
  vim.api.nvim_win_set_cursor(0, { target.start_row + 1, target.start_col })
end

---@param target table
---@param replacements string[]
---@param request string
local function show_choices(target, replacements, request)
  local lines = {
    "# slotfixes",
    "",
    "**Prompt:** " .. request,
    "",
    "Press 1, 2, or 3 to apply a fix; Esc cancels.",
  }
  for index, replacement in ipairs(replacements) do
    vim.list_extend(lines, {
      "",
      string.format("## %d", index),
      "```" .. vim.bo[target.bufnr].filetype,
    })
    vim.list_extend(lines, vim.split(replacement, "\n", { plain = true }))
    table.insert(lines, "```")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width = math.max(40, math.floor(vim.o.columns * 0.8))
  local height = math.max(10, math.floor(vim.o.lines * 0.8))
  width = math.min(width, vim.o.columns - 4)
  height = math.min(height, vim.o.lines - 4)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
    style = "minimal",
    title = " slotfixes ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  for index, replacement in ipairs(replacements) do
    vim.keymap.set("n", tostring(index), function()
      close()
      apply_replacement(target, replacement)
    end, { buffer = buf, nowait = true, silent = true })
  end
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, silent = true })
end

---@param target table
---@param request string
local function generate(target, request)
  M.state.running = true
  local replacements = {}
  local errors = {}
  local finished = 0
  local stop_loading = start_loading(target, request)

  local function complete(index, result)
    finished = finished + 1
    if result.code == 0 then
      replacements[index] = parse_replacement(result.stdout or "")
    end
    if not replacements[index] then
      errors[index] = (result.stderr and result.stderr ~= "") and result.stderr or "invalid response"
    end

    if finished ~= M.config.count then return end
    stop_loading()
    M.state.running = false
    if next(errors) then
      vim.notify("slotfixes: generation failed: " .. table.concat(vim.tbl_values(errors), "; "), vim.log.levels.ERROR)
      return
    end
    show_choices(target, replacements, request)
  end

  vim.notify("slotfixes: generating three fixes...", vim.log.levels.INFO)
  for index = 1, M.config.count do
    local command = {
      "pi",
      "--no-tools",
      "--no-session",
      "--no-context-files",
      "--no-skills",
      "--no-extensions",
      "--print",
      "--model", M.config.model,
      "--system-prompt", SYSTEM_PROMPT,
      build_prompt(target, request, index),
    }
    local ok, err = pcall(vim.system, command, { text = true }, function(result)
      vim.schedule(function() complete(index, result) end)
    end)
    if not ok then
      vim.schedule(function() complete(index, { code = -1, stdout = "", stderr = tostring(err) }) end)
    end
  end
end

---@param request string?
function M.run(request)
  if M.state.running then
    vim.notify("slotfixes: fixes are already being generated", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("pi") ~= 1 then
    vim.notify("slotfixes: pi is not executable", vim.log.levels.ERROR)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local target, err = capture_target(bufnr)
  if not target then
    vim.notify("slotfixes: " .. err, vim.log.levels.WARN)
    return
  end
  generate(target, request or M.config.prompt)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.keymap.set({ "n", "x" }, M.config.keymap, function() M.run() end,
    { desc = "Generate diagnostic fixes" })
  vim.api.nvim_create_user_command("Slotfixes", function(command)
    M.run(command.args ~= "" and command.args or nil)
  end, { nargs = "*" })
end

return M
