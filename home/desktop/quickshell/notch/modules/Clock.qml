import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

RowLayout {
    spacing: 6

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Label {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.bold: true
        font.pixelSize: 14
    }
    Label {
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        color: Theme.fgDim
        font.pixelSize: 13
    }
}
