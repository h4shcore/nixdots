import QtQuick

// Wrapper that fades + lifts its content in with a per-item delay (staggered reveal).
// Opens slow and soft, closes fast with no stagger.
Item {
    id: root

    property bool shown: false
    property int delay: 0
    property real lift: 10

    implicitHeight: childrenRect.height
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.97
    transformOrigin: Item.Top

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: root.shown ? root.delay : 0 }
            Anim { duration: root.shown ? 320 : 120; curve: Look.standard }
        }
    }
    Behavior on scale {
        SequentialAnimation {
            PauseAnimation { duration: root.shown ? root.delay : 0 }
            Anim { duration: root.shown ? 520 : 150; curve: root.shown ? Look.smooth : Look.standard }
        }
    }

    transform: Translate {
        y: root.shown ? 0 : root.lift
        Behavior on y {
            SequentialAnimation {
                PauseAnimation { duration: root.shown ? root.delay : 0 }
                Anim { duration: root.shown ? 520 : 150; curve: root.shown ? Look.smooth : Look.standard }
            }
        }
    }
}
