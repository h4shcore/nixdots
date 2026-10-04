import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.common
import qs.services

// Compact "now playing" card the notch shows for a few seconds when the track changes.
Item {
    id: root

    readonly property MprisPlayer p: Players.active

    implicitWidth: 300
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        width: parent.width
        spacing: 12

        ClippingRectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            radius: 14
            color: Look.surfaceHi

            Image {
                id: art
                anchors.fill: parent
                source: root.p?.trackArtUrl ?? ""
                sourceSize: Qt.size(128, 128)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { Anim { duration: 250; curve: Look.standard } }
            }
            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: "\uf001"
                font.pixelSize: 20
                color: Look.fgDim
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Label {
                Layout.fillWidth: true
                text: "NOW PLAYING"
                color: Look.primary
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
            }
            Label {
                Layout.fillWidth: true
                text: root.p?.trackTitle || ""
                font.bold: true
                font.pixelSize: 14
            }
            Label {
                Layout.fillWidth: true
                text: root.p?.trackArtist ?? ""
                color: Look.fgDim
                font.pixelSize: 12
            }
        }
    }
}
