import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

Item {
    id: root

    implicitWidth: 360
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: "Notifications"
                font.bold: true
                font.pixelSize: 14
            }
            IconButton {
                size: 32
                glyph: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                primary: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            IconButton {
                size: 32
                glyph: "\uf1f8"
                onClicked: Notifs.clearAll()
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            visible: Notifs.count === 0
            text: "All caught up"
            color: Theme.fgDim
        }

        ListView {
            id: lv
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 380)
            visible: Notifs.count > 0
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel { values: [...Notifs.list] }

            delegate: NotifCard {
                required property var modelData
                width: ListView.view.width
                entry: modelData
            }

            remove: Transition {
                ParallelAnimation {
                    Anim { property: "opacity"; to: 0; curve: Theme.standard; duration: 200 }
                    Anim { property: "x"; to: 80; curve: Theme.standard; duration: 200 }
                }
            }
            displaced: Transition {
                Anim { property: "y" }
            }
        }
    }
}
