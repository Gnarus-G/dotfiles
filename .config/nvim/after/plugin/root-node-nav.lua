local ts_utils = require "nvim-treesitter.ts_utils"
local map = require("gnarus.keymap").map

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

vim.api.nvim_create_user_command("TSPrevRootLevelNode", function()
  local node = getCurrentRootLevelNode()
  local prev = node:prev_sibling()
  if prev ~= nil then
    ts_utils.goto_node(prev)
    print("Current Treesitter Node is of type:", prev:type())
  end
end, {})

vim.api.nvim_create_user_command("TSNextRootLevelNode", function()
  local node = getCurrentRootLevelNode()
  local next = node:next_sibling()
  if next ~= nil then
    ts_utils.goto_node(next)
    print("Current Treesitter Node is of type:", next:type())
  end
end, {})

map("n", "<up>", ":TSPrevRootLevelNode<cr>")
map("n", "<down>", ":TSNextRootLevelNode<cr>")
