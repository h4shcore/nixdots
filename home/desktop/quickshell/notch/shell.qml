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
}
