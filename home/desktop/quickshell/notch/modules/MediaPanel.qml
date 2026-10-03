import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.common
import qs.services

Item {
    id: root

    readonly property MprisPlayer p: Players.active

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    implicitWidth: 340
    implicitHeight: col.implicitHeight

    // position isn't pushed by MPRIS, so poke it while playing and visible
    Timer {
        running: root.visible && root.p?.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: if (root.p) root.p.positionChanged()
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ClippingRectangle {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                radius: 16
                color: Theme.surfaceHiest

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.p?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "\uf001"
                    font.pixelSize: 26
                    color: Theme.fgDim
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: root.p?.trackTitle || "Nothing playing"
                    font.bold: true
                    font.pixelSize: 14
                }
                Label {
                    Layout.fillWidth: true
                    text: root.p?.trackArtist ?? ""
                    color: Theme.fgDim
                }
                Label {
                    Layout.fillWidth: true
                    text: root.p?.identity ?? ""
                    color: Theme.outline
                    font.pixelSize: 11
                }
            }
        }

        Slider {
            Layout.fillWidth: true
            value: root.p && root.p.length > 0 ? root.p.position / root.p.length : 0
            enabled: root.p?.canSeek ?? false
            onMoved: v => { if (root.p && root.p.canSeek) root.p.position = v * root.p.length; }
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: root.fmt(root.p?.position)
                color: Theme.fgDim
                font.pixelSize: 11
            }
            Item { Layout.fillWidth: true }
            Label {
                text: root.fmt(root.p?.length)
                color: Theme.fgDim
                font.pixelSize: 11
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            IconButton {
                glyph: "\uf048"
                enabled: root.p?.canGoPrevious ?? false
                onClicked: root.p.previous()
            }
            IconButton {
                size: 48
                primary: true
                glyph: root.p?.isPlaying ? "\uf04c" : "\uf04b"
                enabled: root.p?.canTogglePlaying ?? false
                onClicked: root.p.togglePlaying()
            }
            IconButton {
                glyph: "\uf051"
                enabled: root.p?.canGoNext ?? false
                onClicked: root.p.next()
            }
        }
    }
}
