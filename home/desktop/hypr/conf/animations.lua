-- Curves
local curves = {
    expressiveFastSpatial    = { { 0.42, 1.67 }, { 0.21, 0.90 } },
    expressiveSlowSpatial    = { { 0.39, 1.29 }, { 0.35, 0.98 } },
    expressiveDefaultSpatial = { { 0.38, 1.21 }, { 0.22, 1.00 } },
    emphasizedDecel          = { { 0.05, 0.7 },  { 0.1, 1 } },
    emphasizedAccel          = { { 0.3, 0 },     { 0.8, 0.15 } },
    standardDecel            = { { 0, 0 },       { 0, 1 } },
    menu_decel               = { { 0.1, 1 },     { 0, 1 } },
    menu_accel               = { { 0.52, 0.03 }, { 0.72, 0.08 } },
    stall                    = { { 1, -0.1 },    { 0.7, 0.85 } },
}
for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

-- Animations: { leaf, speed, bezier, style (optional) }
local anims = {
    -- windows
    { "windowsIn",  3,   "emphasizedDecel", "popin 80%" },
    { "fadeIn",     3,   "emphasizedDecel" },
    { "windowsOut", 2,   "emphasizedDecel", "popin 90%" },
    { "fadeOut",    2,   "emphasizedDecel" },
    { "windowsMove", 3,  "emphasizedDecel", "slide" },
    { "border",     10,  "emphasizedDecel" },

    -- layers
    { "layersIn",       2.7, "emphasizedDecel", "popin 93%" },
    { "layersOut",      2.4, "menu_accel",      "popin 94%" },
    { "fadeLayersIn",   0.5, "menu_decel" },
    { "fadeLayersOut",  2.7, "stall" },

    -- workspaces
    { "workspaces",          7,   "menu_decel",      "slide" },
    { "specialWorkspaceIn",  2.8, "emphasizedDecel", "slidevert" },
    { "specialWorkspaceOut", 1.2, "emphasizedAccel", "slidevert" },

    -- zoom
    { "zoomFactor", 3, "standardDecel" },
}
for _, a in ipairs(anims) do
    hl.animation({
        leaf    = a[1],
        enabled = true,
        speed   = a[2],
        bezier  = a[3],
        style   = a[4],
    })
end
