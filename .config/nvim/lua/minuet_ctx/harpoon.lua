local harpoon = require("harpoon")

local M = {}

---@type string[]
M._files = {}

function M.add_file(path)
  table.insert(M._files, path)
  vim.notify("Added " .. path .. " to Minuet context", vim.log.levels.INFO)
end

function M.remove_file(path)
  for i, f in ipairs(M._files) do
    if f == path then
      table.remove(M._files, i)
      vim.notify("Removed " .. path .. " from Minuet context", vim.log.levels.INFO)
      break
    end
  end
end

---@return string[]
local function get_current_harpoon_filepaths()
  local paths = {}
  local current_list = harpoon:list()

  if current_list then
    for i = 1, current_list:length() do
      local item = current_list:get(i)
      if item and item.value then
        table.insert(paths, vim.fn.expand(item.value))
      end
    end
  end
  return paths
end

local function sync_harpoon_list_to_minuet_context()
  M._files = get_current_harpoon_filepaths()
end

-- Sync when Harpoon's list structure changes
local harpoon_ext = require("harpoon.extensions")
harpoon:extend({
  [harpoon_ext.event_names.ADD] = function(event)
    M.add_file(event.item.value)
  end,
  [harpoon_ext.event_names.REMOVE] = function(event)
    M.remove_file(event.item.value)
  end,
  [harpoon_ext.event_names.LIST_CHANGE] = function()
    sync_harpoon_list_to_minuet_context()
  end,
})

return {
  sync = sync_harpoon_list_to_minuet_context,
  files = function()
    return vim.deepcopy(M._files)
  end
}
