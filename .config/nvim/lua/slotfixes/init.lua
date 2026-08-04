local prompt = require("slotfixes.prompt")
local target = require("slotfixes.target")
local ui = require("slotfixes.ui")

local M = {}

M.config = {
  count = 3,
  context_lines = 40,
  keymap = "<leader>cf",
  model = "openai-codex/gpt-5.6-luna",
  prompt = "Fix the diagnostics on this line.",
}

M.state = { running = false }

local function pi_command(captured, request, alternative)
  return {
    "pi",
    "--no-tools",
    "--no-session",
    "--no-context-files",
    "--no-skills",
    "--no-extensions",
    "--print",
    "--model", M.config.model,
    "--system-prompt", prompt.system,
    prompt.build(captured, request, alternative, M.config),
  }
end

local function result_error(result)
  return result.stderr and result.stderr ~= "" and result.stderr or "invalid response"
end

local function error_message(errors)
  local messages = {}
  for index = 1, M.config.count do
    if errors[index] then table.insert(messages, errors[index]) end
  end
  return table.concat(messages, "; ")
end

local function generate(captured, request)
  M.state.running = true
  local batch = { remaining = M.config.count, replacements = {}, errors = {} }
  local stop_loading = ui.start_loading(captured, request)

  local function complete(index, result)
    local replacement = result.code == 0 and prompt.parse(result.stdout or "") or nil
    if replacement then
      batch.replacements[index] = replacement
    else
      batch.errors[index] = result_error(result)
    end
    batch.remaining = batch.remaining - 1
    if batch.remaining > 0 then return end

    stop_loading()
    M.state.running = false
    if next(batch.errors) then
      vim.notify("slotfixes: generation failed: " .. error_message(batch.errors), vim.log.levels.ERROR)
      return
    end
    ui.show_choices(captured, batch.replacements, request, function(replacement)
      target.apply(captured, replacement)
    end)
  end

  vim.notify(string.format("slotfixes: generating %d fixes...", M.config.count), vim.log.levels.INFO)
  for index = 1, M.config.count do
    local ok, err = pcall(vim.system, pi_command(captured, request, index), { text = true }, function(result)
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

  local captured, err = target.capture(vim.api.nvim_get_current_buf())
  if not captured then
    vim.notify("slotfixes: " .. err, vim.log.levels.WARN)
    return
  end
  generate(captured, request or M.config.prompt)
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
