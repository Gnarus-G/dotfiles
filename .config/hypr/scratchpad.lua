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

  local function findOurs()
    for _, candidate in ipairs(hl.get_windows()) do
      if is_ours(candidate) then
        return candidate
      end
    end
    return nil
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

  -- Toggling off restores keyboard focus by workspace history, not by what is
  -- under the cursor, and the follow-mouse refocus is gated on real mouse
  -- motion. The move dispatch lands after this callback, so poll until our
  -- window is back on its storage workspace, then hand keyboard focus to the
  -- topmost floating window under the cursor (floats stack above tiled; most
  -- recently raised wins).
  local function hide(window)
    local ws_name = window.workspace.name
    hl.dispatch(hl.dsp.window.move({ window = window, workspace = workspace }))
    closeStorageWorkspace()

    local function refocusUnderCursor()
      local cursor = hl.get_cursor_pos()
      local top
      for _, win in ipairs(hl.get_workspace_windows(hl.get_workspace(ws_name))) do
        if win.floating and cursor.x >= win.at.x and cursor.x < win.at.x + win.size.x and cursor.y >= win.at.y and cursor.y < win.at.y + win.size.y then
          if not top or win.focus_history_id < top.focus_history_id then
            top = win
          end
        end
      end
      if top then
        hl.dispatch(hl.dsp.focus({ window = top }))
      else
        hl.dispatch(hl.dsp.cursor.move({ x = cursor.x, y = cursor.y }))
      end
    end

    local function awaitHidden()
      if findOurs() and findOurs().workspace.name == ws_name then
        hl.timer(awaitHidden, { timeout = 20, type = "oneshot" })
        return
      end
      hl.timer(refocusUnderCursor, { timeout = 60, type = "oneshot" })
    end

    hl.timer(awaitHidden, { timeout = 50, type = "oneshot" })
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
    local window = findOurs()
    if window and window.workspace.name == movedWorkspace.name then
      resize(window, monitor)
    end
  end)

  hl.bind(key, function()
    local window = findOurs()

    if not window then
      if not pending then
        pending = true
        hl.exec_cmd(command)
      end
    elseif window.workspace.name == hl.get_active_workspace().name then
      hide(window)
    else
      show(window)
    end
  end)
end

return M
