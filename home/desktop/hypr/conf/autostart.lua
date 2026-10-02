-- https://wiki.hypr.land/Configuring/Basics/Autostart/
-- Not using UWSM, so no `uwsm app --` prefix here.
-- The first command is what activates graphical-session.target (needed by the portals).
-- If you already have that line somewhere else, delete one of them.

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user start hyprland-session.target")

    hl.exec_cmd("uwsm app -- awww-daemon")
    hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
end)
