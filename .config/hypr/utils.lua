local M = {}

-- Select the rig from a machine-local file, independent of the hostname.
function M.per_rig_profile(profile, func)
    local file = io.open(os.getenv("HOME") .. "/.config/rig-name")
    if not file then return end
    local rig = file:read("*l")
    file:close()
    if rig == profile then
        func()
    end
end

return M
