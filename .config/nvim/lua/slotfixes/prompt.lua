local M = {}

M.system = table.concat({
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

---@param diagnostic vim.Diagnostic
local function format_diagnostic(diagnostic)
  local origin = {}
  if diagnostic.source then table.insert(origin, diagnostic.source) end
  if diagnostic.code then table.insert(origin, tostring(diagnostic.code)) end
  local attribution = #origin > 0 and (" (" .. table.concat(origin, "/") .. ")") or ""
  return string.format("- %d:%d [%s]%s %s", diagnostic.lnum + 1, diagnostic.col + 1,
    severity_names[diagnostic.severity] or "UNKNOWN", attribution, diagnostic.message:gsub("\n", " "))
end

---@param target SlotfixTarget
local function target_diagnostics(target)
  local diagnostics = vim.diagnostic.get(target.bufnr, { lnum = target.diagnostic_row })
  if #diagnostics == 0 then return { "- (none)" } end
  return vim.iter(diagnostics):map(format_diagnostic):totable()
end

---@param target SlotfixTarget
---@param request string
---@param alternative integer
---@param config table
---@return string
function M.build(target, request, alternative, config)
  local line_count = vim.api.nvim_buf_line_count(target.bufnr)
  local context_start = math.max(0, target.start_row - config.context_lines)
  local context_end = math.min(line_count, target.end_row + config.context_lines + 1)
  local path = vim.api.nvim_buf_get_name(target.bufnr)

  return table.concat({
    request,
    string.format("Generate alternative %d of %d; prefer a distinct valid fix where reasonable.", alternative, config.count),
    string.format("File: %s", path == "" and "[No Name]" or vim.fn.fnamemodify(path, ":~:.")),
    string.format("Language: %s", vim.bo[target.bufnr].filetype),
    string.format("Target range: %d:%d-%d:%d", target.start_row + 1, target.start_col + 1,
      target.end_row + 1, target.end_col + 1),
    "Diagnostics on the target line:",
    table.concat(target_diagnostics(target), "\n"),
    "<target>",
    table.concat(target.lines, "\n"),
    "</target>",
    string.format('<context start-line="%d">', context_start + 1),
    table.concat(vim.api.nvim_buf_get_lines(target.bufnr, context_start, context_end, false), "\n"),
    "</context>",
  }, "\n")
end

---@param output string
---@return string?
function M.parse(output)
  local replacement = output:match("<slotfix>%s*(.-)%s*</slotfix>")
  if replacement == "" then return nil end
  return replacement
end

return M
