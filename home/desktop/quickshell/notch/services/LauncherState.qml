pragma Singleton
import Quickshell

// Shared by the bottom docks (apps launcher + wallpaper picker): only one is open at a time.
Singleton {
    property bool open: false
    property string mode: "apps"     // apps | wall

    function toggleMode(m) {
        if (open && mode === m) {
            open = false;
        } else {
            mode = m;
            open = true;
        }
    }

    function toggle() { toggleMode("apps"); }
    function show() { mode = "apps"; open = true; }
    function hide() { open = false; }
}
