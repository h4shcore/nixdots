-- Shared values used by other modules: local P = require("conf.programs")
return {
    terminal    = "kitty",
    fileManager = "dolphin",
    -- menu        = "fuzzel",
    menu        = "qs -c notch ipc call launcher toggle",
    wallpaper   = "qs -c notch ipc call wallpaper toggle",
    mainMod     = "SUPER",
}
