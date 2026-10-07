import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// Shown in the notch while recording (timer) or counting down to a capture. Click to stop / cancel.
RowLayout {
    id: root

    visible: Capture.recording || Capture.countdown > 0
    spacing: 7

    Rectangle {
        Layout.preferredWidth: 9
        Layout.preferredHeight: 9
        radius: 4.5
        color: Look.error

        SequentialAnimation on opacity {
            running: root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
        }
    }

    Label {
        text: Capture.countdown > 0 ? String(Capture.countdown) : Capture.fmt(Capture.elapsed)
        font.bold: true
        font.pixelSize: 13
        color: Look.error
    }

    // click anywhere on the chip
    TapHandler {
        onTapped: Capture.stop()
    }
}
