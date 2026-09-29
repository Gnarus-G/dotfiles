local M = {}

-- Display-manager sessions do not source ~/.zshrc.local. A machine-local file
-- selects the rig if GNARUS_RIG is absent from Hyprland's environment.
function M.per_rig_profile(profile, func)
    local rig = os.getenv("GNARUS_RIG")
    if not rig then
        local file = io.open(os.getenv("HOME") .. "/.config/gnarus-rig")
        if file then
            rig = file:read("*l")
            file:close()
        end
    end
    if rig == profile then
        func()
    end
end

return M
