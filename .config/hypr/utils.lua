local M = {}

-- Runs the given function only when the GNARUS_RIG environment variable matches
-- the profile. Set GNARUS_RIG (e.g. `export GNARUS_RIG=home`) in ~/.zshrc.local
-- on each machine, so it lands in Hyprland's launch environment.
function M.per_rig_profile(profile, func)
    if os.getenv("GNARUS_RIG") == profile then
        func()
    end
end

return M