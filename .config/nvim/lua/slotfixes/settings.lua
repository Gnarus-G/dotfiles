local M = {}

M.path = vim.fs.joinpath(vim.fn.stdpath("state"), "slotfixes.json")
M.reasoning_levels = { "off", "minimal", "low", "medium", "high", "xhigh", "max" }

local function valid_count(count)
  return type(count) == "number" and count % 1 == 0 and count >= 1 and count <= 3
end

---@param values table
local function persisted_values(values)
  local persisted = {}
  if valid_count(values.count) then persisted.count = values.count end
  if type(values.model) == "string" and values.model ~= "" then persisted.model = values.model end
  if vim.tbl_contains(M.reasoning_levels, values.reasoning) then persisted.reasoning = values.reasoning end
  return persisted
end

function M.load()
  if vim.fn.filereadable(M.path) ~= 1 then return {} end
  local ok, values = pcall(vim.json.decode, table.concat(vim.fn.readfile(M.path), "\n"))
  if not ok or type(values) ~= "table" then
    vim.notify("slotfixes: could not read persisted configuration", vim.log.levels.WARN)
    return {}
  end
  return persisted_values(values)
end

---@param values table
function M.save(values)
  vim.fn.mkdir(vim.fs.dirname(M.path), "p")
  local ok, encoded = pcall(vim.json.encode, persisted_values(values))
  if not ok or vim.fn.writefile({ encoded }, M.path) ~= 0 then
    vim.notify("slotfixes: could not persist configuration", vim.log.levels.ERROR)
  end
end

return M
