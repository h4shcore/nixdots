local P = require("conf.programs")
local mainMod = P.mainMod

-- Core
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(P.terminal))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(P.menu))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(P.wallpaper))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + I", hl.dsp.layout("togglesplit")) -- dwindle only

-- Fullscreen
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Focus: arrows + hjkl
local dirs = {
    { "left", "h", "left" },
    { "right", "l", "right" },
    { "up", "k", "up" },
    { "down", "j", "down" },
}
for _, d in ipairs(dirs) do
    hl.bind(mainMod .. " + " .. d[1], hl.dsp.focus({ direction = d[3] }))
    hl.bind(mainMod .. " + " .. d[2], hl.dsp.focus({ direction = d[3] }))
end

-- Workspaces: mainMod + [0-9], move window with SHIFT
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                 { locked = true, repeating = true })

-- playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind("SUPER + Minus", function() zoomfunction(-0.3) end, { repeating = true, description = "Screen: Zoom out" })
hl.bind("SUPER + Equal", function() zoomfunction(0.3) end,  { repeating = true, description = "Screen: Zoom in" })

-- Zoom with keypad
hl.bind("SUPER + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind("SUPER + code:86", function() zoomfunction(0.3) end,  { repeating = true })

-- Special workspaces (windows get sent here by the tag rules in rules.lua)
hl.bind(mainMod .. " + M", hl.dsp.workspace.toggle_special("music"))   -- music players
hl.bind(mainMod .. " + D", hl.dsp.workspace.toggle_special("chat"))    -- discord / whatsapp

-- Layout switching
local layouts = { "dwindle", "master", "scrolling", "monocle" }

local function set_layout(name)
    hl.config({ general = { layout = name } })
    -- hl.exec_cmd("notify-send -t 1500 'Layout' '" .. name .. "'") -- needs a notification daemon
end

local function cycle_layout(step)
    local current = hl.get_config("general:layout")
    local idx = 1
    for i, name in ipairs(layouts) do
        if name == current then idx = i break end
    end
    set_layout(layouts[(idx - 1 + step) % #layouts + 1])
end

hl.bind(mainMod .. " + CTRL + D", function() set_layout("dwindle") end)
hl.bind(mainMod .. " + CTRL + M", function() set_layout("master") end)
hl.bind(mainMod .. " + CTRL + S", function() set_layout("scrolling") end)
hl.bind(mainMod .. " + CTRL + O", function() set_layout("monocle") end)

-- Cycle forward / backward through the list above
hl.bind(mainMod .. " + CTRL + Space",         function() cycle_layout(1) end)
hl.bind(mainMod .. " + CTRL + SHIFT + Space", function() cycle_layout(-1) end)
