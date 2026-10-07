//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs.modules
import qs.services

ShellRoot {
    Variants {
        model: Quickshell.screens
        PerScreen {}
    }

    // qs -c notch ipc call launcher toggle
    IpcHandler {
        target: "launcher"

        function toggle(): void { LauncherState.toggle(); }
        function show(): void { LauncherState.show(); }
        function hide(): void { LauncherState.hide(); }
    }

    // qs -c notch ipc call capture toggle | region | window | fullscreen | record | stop
    IpcHandler {
        target: "capture"

        function toggle(): void { LauncherState.toggleMode("cap"); }
        function region(): void { Capture.start("shot", "region"); }
        function window(): void { Capture.start("shot", "window"); }
        function fullscreen(): void { Capture.start("shot", "screen"); }
        function record(): void { Capture.start("record", Capture.target); }
        function stop(): void { Capture.stop(); }
    }

    // qs -c notch ipc call clipboard toggle
    IpcHandler {
        target: "clipboard"

        function toggle(): void { LauncherState.toggleMode("clip"); }
        function show(): void {
            LauncherState.mode = "clip";
            LauncherState.open = true;
        }
        function hide(): void { LauncherState.hide(); }
    }

    // qs -c notch ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"

        function toggle(): void { LauncherState.toggleMode("wall"); }
        function show(): void {
            LauncherState.mode = "wall";
            LauncherState.open = true;
        }
        function hide(): void { LauncherState.hide(); }
    }
}
