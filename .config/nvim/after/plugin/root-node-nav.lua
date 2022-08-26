local ts_utils = require "nvim-treesitter.ts_utils"

local function getCurrentRootLevelNode()
  local curr_node = ts_utils.get_node_at_cursor()

  if curr_node == nil then
    error("No Treesitter parser found.")
  end

  local root_node = ts_utils.get_root_for_node(curr_node)

  local parent = curr_node:parent()

  while (parent ~= nil and parent ~= root_node) do
    curr_node = parent
    parent = curr_node:parent()
  end

  return curr_node
end

local function jump_from(node, jump_count, next_node)
  local to_node = node;
  for _ = 1, jump_count ~= 0 and jump_count or 1 do
    if next_node(to_node) == nil then
      break
    end
    to_node = next_node(to_node)
  end
  return to_node;
end

local function go_to_node(node)
  if node ~= nil then
    ts_utils.goto_node(node)
    print("Current Treesitter Node is of type:", node:type())
  end
end

local function getNextRootLevelNode(jump_count)
  local rl_node = getCurrentRootLevelNode()
  local next = jump_from(rl_node, jump_count, function(node)
    return node:next_sibling()
  end)
  go_to_node(next)
end

local function getPreviousRootLvlNode(jump_count)
  local rl_node = getCurrentRootLevelNode()
  local prev = jump_from(rl_node, jump_count, function(node)
    return node:prev_sibling()
  end)
  go_to_node(prev)
end

vim.api.nvim_create_user_command("TSPrevRootLevelNode", function(arg)
  getPreviousRootLvlNode(arg.count)
end, {
  count = true
})

vim.api.nvim_create_user_command("TSNextRootLevelNode", function(arg)
  getNextRootLevelNode(arg.count)
end, {
  count = true
})

vim.keymap.set("n", "<up>", function() getPreviousRootLvlNode(vim.v.count) end)
vim.keymap.set("n", "<down>", function() getNextRootLevelNode(vim.v.count) end)
