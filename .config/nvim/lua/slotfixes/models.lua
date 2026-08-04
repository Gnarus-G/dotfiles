local M = {}

local cache

local function load_models()
  local ok, process = pcall(vim.system, { "pi", "--list-models" }, { text = true })
  if not ok then return {} end
  local result = process:wait()
  if result.code ~= 0 then return {} end

  local models = {}
  for line in vim.gsplit(result.stdout or "", "\n", { plain = true }) do
    local provider, model = line:match("^(%S+)%s+(%S+)")
    if provider and provider ~= "provider" then
      table.insert(models, provider .. "/" .. model)
    end
  end
  return models
end

function M.list()
  if not cache then cache = load_models() end
  return vim.deepcopy(cache)
end

---@param lead string
function M.complete(lead)
  local query = lead:lower()
  return vim.iter(M.list()):filter(function(model)
    return model:lower():find(query, 1, true) ~= nil
  end):totable()
end

return M
