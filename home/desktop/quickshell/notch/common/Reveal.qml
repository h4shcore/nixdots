import QtQuick

// Wrapper that fades/scales its content in with a per-item delay (staggered reveal).
Item {
    id: root

    property bool shown: false
    property int delay: 0

    implicitHeight: childrenRect.height
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    transformOrigin: Item.Top

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: root.shown ? root.delay : 0 }
            Anim { duration: 250; curve: Theme.standard }
        }
    }
    Behavior on scale {
        SequentialAnimation {
            PauseAnimation { duration: root.shown ? root.delay : 0 }
            Anim {}
        }
    }
}
