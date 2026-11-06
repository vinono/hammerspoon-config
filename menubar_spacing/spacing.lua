-- Read-only capability report. Loading this module has no side effects.
-- hs.menubar exposes controls for owned items, not global item spacing.
local M = {}

function M.diagnose(version)
    local major = type(version) == 'table' and tonumber(version.major) or nil
    return {
        supported = false,
        action = 'none',
        reason = major == 27
            and 'macOS 27: no verified public API for global menu bar icon spacing; preferences left untouched.'
            or 'No verified public global spacing API for this system; preferences left untouched.',
    }
end

return M
