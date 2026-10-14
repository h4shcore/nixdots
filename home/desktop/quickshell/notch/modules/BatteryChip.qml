import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// Battery pill: drawn battery with a live fill, percentage, and the time estimate
// sliding out on hover.
Rectangle {
    id: root

    readonly property bool hovered: mouse.containsMouse
    readonly property color tint: Battery.low ? Look.error : (Battery.charging ? Look.primary : Look.fg)
    readonly property bool showEta: hovered && Battery.eta !== ""

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Look.pillHeight - 10
    radius: height / 2
    color: Qt.alpha(tint, hovered ? 0.2 : 0.09)
    scale: mouse.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: 220 } }
    Behavior on scale { Anim { duration: Look.dur.fast } }

    RowLayout {
        id: row
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // battery glyph: outline + fill + nub
        Item {
            implicitWidth: 27
            implicitHeight: 14

            Rectangle {
                id: shell
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 13
                radius: 4
                color: "transparent"
                border.width: 1.5
                border.color: Qt.alpha(root.tint, 0.5)

                Rectangle {
                    x: 2.5
                    y: 2.5
                    height: parent.height - 5
                    width: Math.max(2, (parent.width - 5) * Battery.percent / 100)
                    radius: 2
                    color: root.tint
                    Behavior on width { Anim { duration: 400; curve: Look.standard } }

                    SequentialAnimation on opacity {
                        running: Battery.charging
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) parent.opacity = 1
                        NumberAnimation { to: 0.5; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
            }
            Rectangle {
                anchors.verticalCenter: shell.verticalCenter
                x: 24.5
                width: 2.5
                height: 5
                radius: 1.25
                color: Qt.alpha(root.tint, 0.5)
            }
        }

        // percentage + eta (eta grows out of the clipped box on hover)
        Item {
            id: textBox
            clip: true
            implicitHeight: pct.implicitHeight
            implicitWidth: pct.implicitWidth + (root.showEta ? eta.implicitWidth + 8 : 0)
            Behavior on implicitWidth { Anim { duration: 280; curve: Look.standard } }

            Label {
                id: pct
                text: Math.round(Battery.percent) + "%"
                font.pixelSize: 12
                font.bold: true
                color: Battery.low ? Look.error : Look.fg
            }
            Label {
                id: eta
                x: pct.implicitWidth + 8
                text: Battery.eta
                elide: Text.ElideNone
                font.pixelSize: 11
                color: Look.fgDim
                opacity: root.showEta ? 1 : 0
                Behavior on opacity { Anim { duration: 200; curve: Look.standard } }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
    }
}
