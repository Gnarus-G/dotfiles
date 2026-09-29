local M = {}

function M.setup(name, key, width, height, opts)
  opts = opts or {}
  local command = opts.command
      or "ghostty --gtk-single-instance=false --title=" ..
      name .. " --title-report=false -e tmux new-session -As " .. name
  local workspace = "special:" .. name
  local pending = false

  -- Identify this scratchpad's window: by class if given, else by ghostty's fixed title
  local function is_ours(window)
    if opts.class then
      return window.class == opts.class
    end
    return window.initial_title == name
  end

  local function closeStorageWorkspace()
    local active = hl.get_active_special_workspace()
    if active and active.name == workspace then
      hl.dispatch(hl.dsp.workspace.toggle_special(name))
    end
  end

  local function resize(window, monitor)
    hl.dispatch(hl.dsp.window.resize({
      window = window,
      x = math.floor(monitor.width * width),
      y = math.floor(monitor.height * height),
    }))
    hl.dispatch(hl.dsp.window.center({ window = window }))
  end

  local function show(window)
    local monitor = hl.get_active_monitor()
    hl.dispatch(hl.dsp.window.move({ window = window, workspace = monitor.active_workspace }))
    closeStorageWorkspace()
    hl.dispatch(hl.dsp.window.fullscreen({ action = "unset", window = window }))
    resize(window, monitor)
    hl.dispatch(hl.dsp.window.bring_to_top({ window = window }))
    hl.dispatch(hl.dsp.focus({ window = window }))
  end

  closeStorageWorkspace()

  hl.on("hyprland.start", function()
    hl.exec_cmd(command)
  end)

  hl.window_rule({
    name = "scratchpad-" .. name,
    match = opts.class and { class = opts.class } or { initial_title = "^" .. name .. "$" },
    workspace = workspace .. " silent",
    float = true,
    size = "monitor_w*" .. width .. " monitor_h*" .. height,
    center = true,
    fullscreen_state = "0 0",
    no_anim = true,
  })

  hl.on("window.open", function(window)
    if pending and is_ours(window) then
      pending = false
      show(window)
    end
  end)

  hl.on("workspace.move_to_monitor", function(movedWorkspace, monitor)
    for _, window in ipairs(hl.get_windows()) do
      if is_ours(window) and window.workspace.name == movedWorkspace.name then
        resize(window, monitor)
        break
      end
    end
  end)

  hl.bind(key, function()
    local window
    for _, candidate in ipairs(hl.get_windows()) do
      if is_ours(candidate) then
        window = candidate
        break
      end
    end

    if not window then
      if not pending then
        pending = true
        hl.exec_cmd(command)
      end
    elseif window.workspace.name == hl.get_active_workspace().name then
      hl.dispatch(hl.dsp.window.move({ window = window, workspace = workspace }))
      closeStorageWorkspace()
    else
      show(window)
    end
  end)
end

return M
