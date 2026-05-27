-- Send text/prompts from nvim to an agent TUI (claude, codex, …) running in a tmux pane.
-- Agent-agnostic: it just pastes into a chosen pane and optionally submits with Enter.

local M = {}

M.config = {
  agent_commands = { "claude", "codex", "opencode", "aider", "node" }, -- pane_current_command to auto-detect
  buffer_name = "nvim-agent",                                  -- named tmux paste buffer, never clobbers the user's
  bracketed_paste = true,                                      -- paste-buffer -p, so multiline stays one input
  submit_delay = 60,                                           -- ms between paste and Enter (let the TUI register)
}

M.state = { target = nil } -- remembered "session:win.pane" for this nvim session

local FMT = table.concat({
  "#{pane_id}", "#{session_name}", "#{window_index}", "#{window_name}",
  "#{pane_index}", "#{pane_current_command}", "#{pane_current_path}", "#{pane_title}",
}, "\t")

---@param args string[]
---@param opts table? extra vim.system opts (e.g. { stdin = "…" })
---@return { code: integer, stdout: string, stderr: string }
local function run(args, opts)
  local cmd = { "tmux" }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {})):wait()
  return { code = res.code, stdout = res.stdout or "", stderr = res.stderr or "" }
end

---@return table[]? panes, string? err  -- excludes nvim's own pane
local function list_panes()
  local res = run({ "list-panes", "-a", "-F", FMT })
  if res.code ~= 0 then
    return nil, res.stderr ~= "" and res.stderr or "tmux list-panes failed"
  end

  local self_pane = vim.env.TMUX_PANE
  local panes = {}
  for line in vim.gsplit(res.stdout, "\n", { plain = true }) do
    if line ~= "" then
      local p = vim.split(line, "\t", { plain = true })
      local id, session, win_index, _, pane_index = p[1], p[2], p[3], p[4], p[5]
      if id and session and win_index and pane_index and id ~= self_pane then
        table.insert(panes, {
          id = id,
          session = session,
          command = p[6] or "",
          cwd = p[7] or "",
          title = table.concat(vim.list_slice(p, 8), "\t"),
          target = string.format("%s:%s.%s", session, win_index, pane_index),
        })
      end
    end
  end
  return panes
end

local function target_valid(target)
  return run({ "display-message", "-p", "-t", target, "#{pane_id}" }).code == 0
end

---@param target string
---@param text string
---@param submit boolean
local function paste_to(target, text, submit)
  local b = M.config.buffer_name
  local load = run({ "load-buffer", "-b", b, "-" }, { stdin = text })
  if load.code ~= 0 then
    vim.notify("agent: load-buffer failed: " .. load.stderr, vim.log.levels.ERROR)
    return
  end

  local args = { "paste-buffer", "-d", "-b", b, "-t", target }
  if M.config.bracketed_paste then table.insert(args, 2, "-p") end
  local paste = run(args)
  if paste.code ~= 0 then
    vim.notify("agent: paste-buffer failed: " .. paste.stderr, vim.log.levels.ERROR)
    return
  end

  if submit then
    vim.defer_fn(function() run({ "send-keys", "-t", target, "Enter" }) end, M.config.submit_delay)
  end
end

-- Panes whose running command looks like an agent TUI (already excludes nvim's own pane).
---@return table[]? panes, string? err
local function agent_panes()
  local panes, err = list_panes()
  if not panes then return nil, err end
  return vim.tbl_filter(function(p)
    return vim.tbl_contains(M.config.agent_commands, p.command)
  end, panes)
end

---@param cb fun(target: string)
---@param panes table[] candidate panes (fetched/filtered by the caller)
---@param empty_msg string shown when there are no candidates
local function pick(cb, panes, empty_msg)
  if #panes == 0 then
    vim.notify("agent: " .. empty_msg, vim.log.levels.WARN)
    return
  end

  vim.ui.select(panes, {
    prompt = "Agent pane",
    format_item = function(p)
      return string.format("%s (%s) [%s] %s",
        p.target, p.id, p.command ~= "" and p.command or "-", p.title ~= "" and p.title or p.cwd)
    end,
  }, function(choice)
    if not choice then return end
    M.state.target = choice.target
    cb(choice.target)
  end)
end

-- Resolve a target pane: remembered → single auto-detected agent → picker (agents only).
---@param cb fun(target: string)
local function resolve_target(cb)
  if M.state.target and target_valid(M.state.target) then
    return cb(M.state.target)
  end
  M.state.target = nil

  local panes, err = agent_panes()
  if not panes then
    vim.notify("agent: " .. err, vim.log.levels.ERROR)
    return
  end
  if #panes == 1 then
    M.state.target = panes[1].target
    return cb(panes[1].target)
  end

  pick(cb, panes, "no agent panes found (looking for: "
    .. table.concat(M.config.agent_commands, ", ") .. ")")
end

local function in_visual_mode()
  local m = vim.fn.mode()
  return m == "v" or m == "V" or m == "\22" -- \22 == <C-v>
end

---@return string[] lines, integer srow, integer erow
local function get_selection()
  if in_visual_mode() then
    local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
    local lines = vim.fn.getregion(a, b, { type = vim.fn.mode() })
    return lines, math.min(a[2], b[2]), math.max(a[2], b[2])
  end
  local row = vim.fn.line(".")
  return { vim.fn.getline(row) }, row, row
end

-- "header + fenced literal text" payload.
---@return string
local function fence(lines, srow, erow)
  local relpath = vim.fn.expand("%:.")
  if relpath == "" then relpath = "[No Name]" end
  return table.concat({
    string.format("`%s:%d-%d`", relpath, srow, erow),
    "```" .. vim.bo.filetype,
    table.concat(lines, "\n"),
    "```",
  }, "\n")
end

function M.send_selection(opts)
  opts = opts or {}
  local lines, srow, erow = get_selection()
  local body = fence(lines, srow, erow)
  resolve_target(function(target)
    paste_to(target, body, opts.submit ~= false)
  end)
end

function M.ask(opts)
  opts = opts or {}
  -- Capture the selection now, before the input box steals focus / mode.
  local ctx = nil
  if in_visual_mode() then
    local lines, srow, erow = get_selection()
    ctx = fence(lines, srow, erow)
  end

  vim.ui.input({ prompt = "Agent: " }, function(text)
    if not text or text == "" then return end
    local body = ctx and (text .. "\n\n" .. ctx) or text
    resolve_target(function(target)
      paste_to(target, body, opts.submit ~= false)
    end)
  end)
end

-- <leader>cp: pick from ALL panes (unfiltered escape hatch); the choice is remembered.
function M.select_pane()
  local panes, err = list_panes()
  if not panes then
    vim.notify("agent: " .. err, vim.log.levels.ERROR)
    return
  end
  pick(function(target) vim.notify("agent: target → " .. target) end, panes,
    "no other tmux panes found")
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Check tmux at use-time (not startup) so a non-tmux nvim session stays quiet.
  local function guard(fn)
    return function()
      if vim.env.TMUX == nil then
        vim.notify("agent: not inside tmux", vim.log.levels.WARN)
        return
      end
      fn()
    end
  end

  vim.keymap.set({ "n", "x" }, "<leader>cc", guard(function() M.send_selection() end),
    { desc = "Send selection/line to agent" })
  vim.keymap.set({ "n", "x" }, "<leader>cq", guard(function() M.ask() end),
    { desc = "Ask agent…" })
  vim.keymap.set("n", "<leader>cp", guard(function() M.select_pane() end),
    { desc = "Pick agent pane" })
end

return M
