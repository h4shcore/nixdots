import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common

// entry = an Entry from services/Notifs.qml
Rectangle {
    id: root

    required property var entry
    readonly property var n: entry?.notif ?? null
    readonly property string src: !n ? "" : ((n.image ?? "") !== "" ? n.image : ((n.appIcon ?? "") !== "" ? Quickshell.iconPath(n.appIcon, true) : ""))

    implicitHeight: col.implicitHeight + 24
    radius: 20
    color: Theme.surfaceHi
    border.width: entry?.critical ? 1 : 0
    border.color: Theme.error

    // left click: tuck popup away into the tray, right click: dismiss
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            if (m.button === Qt.RightButton) root.n?.dismiss();
            else if (root.entry) root.entry.popup = false;
        }
    }

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                radius: 12
                color: Theme.surfaceHiest

                Image {
                    id: img
                    anchors.fill: parent
                    source: root.src
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Icon {
                    anchors.centerIn: parent
                    visible: img.status !== Image.Ready
                    text: "\uf0f3"
                    color: Theme.fgDim
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: root.n?.appName ?? ""
                    color: Theme.fgDim
                    font.pixelSize: 11
                }
                Label {
                    Layout.fillWidth: true
                    text: root.n?.summary ?? ""
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.n?.body ?? ""
                    textFormat: Text.StyledText
                    color: Theme.fgDim
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                size: 28
                glyph: "\uf00d"
                onClicked: root.n?.dismiss()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: (root.n?.actions?.length ?? 0) > 0
            spacing: 6

            Repeater {
                model: root.n ? root.n.actions : []

                Rectangle {
                    id: btn
                    required property var modelData
                    implicitWidth: lbl.implicitWidth + 24
                    implicitHeight: 28
                    radius: 14
                    color: bm.containsMouse ? Theme.secondaryContainer : Theme.surfaceHiest
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Label {
                        id: lbl
                        anchors.centerIn: parent
                        text: btn.modelData.text
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: bm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: btn.modelData.invoke()
                    }
                }
            }
        }
    }
}
