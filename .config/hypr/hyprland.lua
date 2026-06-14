-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- HYPRLAND LUA CONFIG.                                 --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

------------------------
---- CURSOR & GENERAL ----
------------------------

hl.config({
    cursor = {
        no_hardware_cursors = true
    }

})

-------------------------
---- REQUIRE MODULES ----
-------------------------

local HOME = os.getenv("HOME")
local function is_file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local modules = {
    "palette",
    "colors",
    "monitor",
    "autostart",
    "windowrules",
    "decoration",
    "animation",
    "input",
    "layouts",
    "keybinding",
    "transparency"
}

for _, mod in ipairs(modules) do
    require(mod)
    -- Load override if it exists
    if is_file_exists(HOME .. "/.config/hypr/custom/" .. mod .. ".lua") then
        require("custom." .. mod)
    end
end
