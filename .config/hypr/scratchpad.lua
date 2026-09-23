local M = {}

function M.setup(name, key, width, height)
    local command = "ghostty --gtk-single-instance=false --title=" .. name .. " --title-report=false -e tmux new-session -As " .. name
    local workspace = "special:" .. name
    local pending = false

    local function closeStorageWorkspace()
        local active = hl.get_active_special_workspace()
        if active and active.name == workspace then
            hl.dispatch(hl.dsp.workspace.toggle_special(name))
        end
    end

    closeStorageWorkspace()

    hl.on("hyprland.start", function()
        hl.exec_cmd(command)
    end)

    hl.window_rule({
        name = "scratchpad-" .. name,
        match = { initial_title = "^" .. name .. "$" },
        workspace = workspace .. " silent",
        float = true,
        size = "monitor_w*" .. width .. " monitor_h*" .. height,
        center = true,
        fullscreen_state = "0 0",
        no_anim = true,
    })

    hl.on("window.open", function(window)
        if pending and window.initial_title == name then
            pending = false
            hl.dispatch(hl.dsp.window.move({ window = window, workspace = hl.get_active_workspace() }))
            closeStorageWorkspace()
            hl.dispatch(hl.dsp.window.fullscreen({ action = "unset", window = window }))
            hl.dispatch(hl.dsp.window.bring_to_top({ window = window }))
            hl.dispatch(hl.dsp.focus({ window = window }))
        end
    end)

    hl.bind(key, function()
        local window
        for _, candidate in ipairs(hl.get_windows()) do
            if candidate.initial_title == name then
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
            hl.dispatch(hl.dsp.window.move({ window = window, workspace = hl.get_active_workspace() }))
            closeStorageWorkspace()
            hl.dispatch(hl.dsp.window.fullscreen({ action = "unset", window = window }))
            hl.dispatch(hl.dsp.window.bring_to_top({ window = window }))
            hl.dispatch(hl.dsp.focus({ window = window }))
        end
    end)
end

return M
