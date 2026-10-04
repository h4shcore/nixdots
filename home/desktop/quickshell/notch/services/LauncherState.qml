pragma Singleton
import Quickshell

Singleton {
    property bool open: false

    function toggle() { open = !open; }
    function show() { open = true; }
    function hide() { open = false; }
}
