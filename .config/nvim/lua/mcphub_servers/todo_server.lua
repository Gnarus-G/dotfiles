---@class MCPHub
local mcphub = require('mcphub')
local todo_executable = vim.fn.expand("~/.local/bin/todo") -- Adjust if your todo path is different
local Job = require('plenary.job')

-- Helper function to run todo commands
---@param args string[],
---@return string?, string? -- returns stdout_output_string, err_message_string
local function run_todo_command(args)
  -- vim.notify("Running: " .. todo_executable .. " " .. table.concat(args, " ")) -- For debugging

  ---@diagnostic disable-next-line: missing-fields
  local job = Job:new({
    command = todo_executable,
    args = args, -- args should be a list of strings
  })

  -- job:sync() returns a table of stdout lines and the exit code.
  local stdout_lines, exit_code = job:sync()

  local output_str = ""
  if stdout_lines then
    -- Trim trailing newline from individual lines if present, then join.
    -- However, table.concat(..., "\n") is usually sufficient.
    -- If todo command outputs an extra newline at the end of its whole output,
    -- that will be preserved, which is often fine.
    output_str = table.concat(stdout_lines, "\n")
  end

  if exit_code ~= 0 then
    local stderr_lines = job:stderr_result() -- Get stderr lines
    local stderr_str = ""
    if stderr_lines and #stderr_lines > 0 then
      stderr_str = table.concat(stderr_lines, "\n")
    end

    local err_msg = "todo error (code " .. tostring(exit_code) .. ")"

    if stderr_str ~= "" then
      err_msg = err_msg .. "\nStderr:\n" .. stderr_str
    elseif output_str ~= "" then -- output_str is from stdout
      -- If stderr is empty but stdout has content, include stdout as it might contain the error.
      err_msg = err_msg .. "\nStdout (potential error details):\n" .. output_str
    else
      -- Neither stderr nor stdout had content, just report the code.
      err_msg = err_msg .. " (no output on stdout or stderr)"
    end
    -- vim.notify(err_msg, vim.log.levels.ERROR)
    return nil, err_msg
  end

  return output_str, nil
end

-- Function to get todos from `todo dump` JSON output
local function get_todos()
  local output, err = run_todo_command({ "dump" })
  if err then
    return nil, "Failed to dump todos from todo: " .. err
  end

  local ok, todos = pcall(vim.fn.json_decode, output)
  if not ok or type(todos) ~= "table" then
    return nil,
        "Failed to parse JSON output from todo dump: " ..
        (todos or "invalid JSON")
  end
  return todos, nil
end

-- Function to get todos from `todo dump` JSON output and format to Markdown
---@return string?, string? -- returns markdown_output_string, err_message_string
local function get_todos_from_todo_as_markdown_list()
  local todos_data, err = get_todos()
  if err then
    return nil, err
  end

  if not todos_data or #todos_data == 0 then
    return "No todos found.\n", nil
  end

  local markdown = ""
  for i, todo in ipairs(todos_data) do
    -- Assuming JSON structure from `todo dump` might be like:
    -- { "id": 1, "message": "Task title", "description": "Details...", "status": "open", "due_date": "YYYY-MM-DD" }
    -- Adapt field names (message, description, due_date) as per actual JSON output from `todo dump`
    local todo_id = todo.id or tostring(i) -- Fallback to index if id is missing
    local title = todo.message or todo.title or "No Title"
    local description = todo.description or todo.desc or ""
    local status = todo.status or "N/A"
    local reminder_date = todo.due_date or todo.reminder_date or "Not set"

    markdown = markdown .. string.format("### Task %d (ID: %s): %s\n", i, todo_id, title)
    markdown = markdown .. string.format("- Description: %s\n", description)
    markdown = markdown .. string.format("- Status: %s\n", status)
    markdown = markdown .. string.format("- Reminder Date: %s\n", reminder_date)
    markdown = markdown .. "\n"
  end

  return markdown, nil
end

-- Create todo tool
vim.cmd [[
  augroup McphubTaskServer
    autocmd!
  augroup END
]]
local todo_server_name = "todo_management"

mcphub.add_tool(todo_server_name, {
  name = "create_todo",
  description = "Create a new todo",
  inputSchema = {
    type = "object",
    properties = {
      title = { type = "string", description = "Task title", required = true },
      desc = { type = "string", description = "Task description" },
      status = { type = "string", description = "Task status (e.g., open, in progress, completed)" },
      reminder_date = { type = "string", description = "Reminder date (e.g., YYYY-MM-DD)" }
    },
    required = { "title" }
  },
  handler = function(req, res)
    local title = req.params.title
    -- local desc = req.params.desc -- `todo "message"` doesn't take separate description via CLI flag
    -- local reminder_date = req.params.reminder_date -- `todo "message"` doesn't take reminder date via CLI flag
    -- Note: req.params.status is ignored as `todo "message"` doesn't take status.

    if not title or title == "" then
      return res:error("Task title is required.")
    end

    -- According to README, adding a todo is `todo "message"`
    local cmd_args = { title } -- The message itself is the command argument for adding

    local output, err = run_todo_command(cmd_args)
    if err then
      return res:error("Failed to create todo with todo CLI: " .. err)
    end
    -- Assuming `todo "message"` output is minimal.
    local response_message = "Task created via todo CLI: " .. title
    response_message = response_message ..
        "\nNote: Description, reminder date, and status (if provided) are not set via this CLI command."
    if output and #output > 0 then
      response_message = response_message .. "\nTodo CLI output:\n" .. output
    end
    return res:text(response_message):send()
  end
})

-- List todos tool
mcphub.add_tool(todo_server_name, {
  name = "list_todos",
  description = "List all todos using todo",
  handler = function(req, res)
    local markdown_output, err = get_todos_from_todo_as_markdown_list()
    if err then
      return res:error(err)
    end
    -- assert not nil
    assert(markdown_output ~= nil, "markdown_output should not be nil if no error")
    return res:text(markdown_output):send()
  end
})

-- Update todo tool
mcphub.add_tool(todo_server_name, {
  name = "update_todo",
  description = "Update an existing todo",
  inputSchema = {
    type = "object",
    properties = {
      id = { type = "integer", description = "Task ID", required = true },
      title = { type = "string", description = "New todo title" },
      desc = { type = "string", description = "New todo description" },
      status = { type = "string", description = "New todo status (e.g., open, in progress, completed)" },
      reminder_date = { type = "string", description = "New reminder date (e.g., YYYY-MM-DD)" }
    },
    required = { "id" }
  },
  handler = function(req, res)
    local todo_id = tostring(req.params.id)
    local status_to_set = req.params.status

    local message = "Update for todo ID " .. todo_id .. ": "
    local action_taken = false

    if status_to_set then
      local lower_status = status_to_set:lower()
      if lower_status == "done" or lower_status == "completed" then
        local output, err = run_todo_command({ "done", todo_id })
        if err then
          if err:match("not found") or err:match("no such todo") then -- Heuristic
            return res:error("Task not found with ID: " .. todo_id .. " (todo CLI: " .. err .. ")")
          end
          return res:error("Failed to mark todo " .. todo_id .. " as done with todo CLI: " .. err)
        end
        message = message .. "Marked as done. "
        if output and #output > 0 then message = message .. "\nTodo CLI output:\n" .. output end
        action_taken = true
      else
        message = message ..
            "Status '" .. status_to_set .. "' is not supported for update via CLI (only 'done'/'completed'). "
      end
    end

    local other_fields_present = false
    if req.params.title or req.params.desc or req.params.reminder_date then
      other_fields_present = true
    end

    if not action_taken and not other_fields_present then
      return res:text("No actionable update parameters provided for todo ID " ..
        todo_id .. ". Only marking as 'done' is supported via CLI."):send()
    end

    if other_fields_present then
      message = message ..
          "\nNote: Updates to title, description, or reminder date are not supported via direct todo CLI commands (use `todo edit` or GUI)."
    end

    return res:text(message):send()
  end
})

-- Delete todo tool
mcphub.add_tool(todo_server_name, {
  name = "delete_todo",
  description = "Delete a todo",
  inputSchema = {
    type = "object",
    properties = {
      id = { type = "integer", description = "Task ID", required = true }
    },
    required = { "id" }
  },
  handler = function(req, res)
    local todo_id = tostring(req.params.id) -- todo CLI expects ID as string argument
    local output, err = run_todo_command({ "rm", todo_id })
    if err then
      if err:match("not found") or err:match("no such todo") then -- Heuristic
        return res:error("Task not found with ID: " .. todo_id .. " (todo CLI: " .. err .. ")")
      end
      return res:error("Failed to delete todo " .. todo_id .. " with todo CLI: " .. err)
    end
    return res:text("Task " ..
      todo_id .. " deleted via todo CLI." .. (output and #output > 0 and ("\nTodo CLI output:\n" .. output) or "")):send()
  end
})

-- Resource to get all todos in Json format
mcphub.add_resource(todo_server_name, {
  name = "all_todos_json",
  uri = "todo_management://todos/json",
  description = "Get all todos from todo in JSON format",
  handler = function(req, res)
    local todos, err = get_todos()
    if err then
      return res:error(err, "text/plain")
    end
    local ok, encoded_json = pcall(vim.fn.json_encode, todos)
    if not ok then
      return res:error("Failed to encode todos to JSON: " .. encoded_json, "text/plain")
    end
    return res:text(encoded_json, "application/json"):send()
  end
})

-- Resource to get all todos in Markdown format
mcphub.add_resource(todo_server_name, {
  name = "all_todos_markdown",
  uri = "todo_management://todos/markdown",
  description = "Get all todos from todo in Markdown format",
  handler = function(req, res)
    local markdown_output, err = get_todos_from_todo_as_markdown_list()
    if err then
      return res:error(err, "text/plain") -- Send error as plain text
    end
    return res:text(markdown_output, "text/markdown"):send()
  end
})
