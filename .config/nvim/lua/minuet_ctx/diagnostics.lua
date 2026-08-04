local M = {}

local severity_names = {
  [vim.diagnostic.severity.ERROR] = "ERROR",
  [vim.diagnostic.severity.WARN] = "WARN",
  [vim.diagnostic.severity.INFO] = "INFO",
  [vim.diagnostic.severity.HINT] = "HINT",
}

---@return vim.Diagnostic[]
function M.get()
  return vim.diagnostic.get(0)
end

---@param diagnostic vim.Diagnostic
---@return string
function M.format(diagnostic)
  local location = string.format("%d:%d", diagnostic.lnum + 1, diagnostic.col + 1)
  local severity = severity_names[diagnostic.severity] or "UNKNOWN"
  local origin = {}
  if diagnostic.source then
    table.insert(origin, diagnostic.source)
  end
  if diagnostic.code then
    table.insert(origin, tostring(diagnostic.code))
  end
  local message = diagnostic.message:gsub("\n", " ")

  if #origin > 0 then
    return string.format("- %s [%s] (%s): %s", location, severity, table.concat(origin, "/"), message)
  end

  return string.format("- %s [%s]: %s", location, severity, message)
end

---@return string
function M.get_formatted_context()
  local diagnostics = M.get()
  if #diagnostics == 0 then
    return ""
  end

  local lines = vim.iter(diagnostics):map(M.format):totable()
  return "<diagnostics>\n" .. table.concat(lines, "\n") .. "\n</diagnostics>"
end

return M
