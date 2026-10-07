-- Shared values used by other modules: local P = require("conf.programs")
return {
    terminal    = "kitty",
    fileManager = "dolphin",
    -- menu        = "fuzzel",
    menu        = "qs -c notch ipc call launcher toggle",
    wallpaper   = "qs -c notch ipc call wallpaper toggle",
    clipboard   = "qs -c notch ipc call clipboard toggle",
    powermenu   = "qs -c notch ipc call power toggle",
    mainMod     = "SUPER",
    -- screenshot  = "grimblast --freeze copysave area ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png",
}
