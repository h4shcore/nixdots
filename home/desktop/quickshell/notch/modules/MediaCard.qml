import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.common
import qs.services

// Now-playing card: blurred album-art backdrop, bouncing art tile, equalizer bars,
// morphing play button, animated track changes.
ClippingRectangle {
    id: root

    readonly property MprisPlayer p: Players.active
    readonly property bool playing: p?.isPlaying ?? false
    readonly property bool busy: progress.pressed

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    implicitHeight: col.implicitHeight + 32
    radius: 24
    color: Theme.surfaceHi

    // position isn't pushed by MPRIS, so poke it while playing and visible
    Timer {
        running: root.visible && root.playing
        interval: 1000
        repeat: true
        onTriggered: if (root.p) root.p.positionChanged()
    }

    // ── blurred backdrop ──
    Image {
        id: bgSrc
        visible: false
        width: root.width
        height: root.height
        source: root.p?.trackArtUrl ?? ""
        sourceSize: Qt.size(160, 160)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    MultiEffect {
        anchors.fill: parent
        source: bgSrc
        blurEnabled: true
        blurMax: 48
        blur: 1
        saturation: 0.4
        brightness: -0.1
        opacity: bgSrc.status === Image.Ready ? 1 : 0
        Behavior on opacity { Anim { duration: 400; curve: Theme.standard } }
    }
    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceHi
        opacity: 0.6
    }

    // pop + fade whenever the track changes
    ParallelAnimation {
        id: trackAnim
        Anim { target: info; property: "opacity"; from: 0; to: 1; duration: 300; curve: Theme.standard }
        Anim { target: infoShift; property: "y"; from: 8; to: 0 }
        Anim { target: tile; property: "scale"; from: 0.82; to: 1 }
    }
    Connections {
        target: root.p
        function onTrackTitleChanged() { trackAnim.restart(); }
    }

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }
        spacing: 12

        // ── art + info ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {
                id: tile
                Layout.preferredWidth: 88
                Layout.preferredHeight: 88
                radius: 22
                color: Theme.surfaceHiest
                scale: root.playing ? 1 : 0.92
                Behavior on scale { Anim {} }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.p?.trackArtUrl ?? ""
                    sourceSize: Qt.size(256, 256)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { Anim { duration: 300; curve: Theme.standard } }
                }
                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "\uf001"
                    font.pixelSize: 30
                    color: Theme.fgDim
                }
            }

            ColumnLayout {
                id: info
                Layout.fillWidth: true
                spacing: 3
                transform: Translate { id: infoShift }

                RowLayout {
                    spacing: 8

                    // equalizer bars
                    Row {
                        spacing: 2
                        Repeater {
                            model: [340, 460, 300, 400]

                            Item {
                                required property int modelData
                                width: 3
                                height: 14

                                Rectangle {
                                    id: bar
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    height: 4
                                    radius: 1.5
                                    color: Theme.primary

                                    SequentialAnimation {
                                        running: root.playing
                                        loops: Animation.Infinite
                                        onRunningChanged: if (!running) bar.height = 4
                                        NumberAnimation { target: bar; property: "height"; to: 14; duration: modelData; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: bar; property: "height"; to: 4; duration: modelData; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: (root.p?.identity ?? "").toUpperCase()
                        color: Theme.primary
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: root.p?.trackTitle || "Nothing playing"
                    font.bold: true
                    font.pixelSize: 16
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
                Label {
                    Layout.fillWidth: true
                    text: root.p?.trackArtist ?? ""
                    color: Theme.fgDim
                    font.pixelSize: 13
                }
            }
        }

        // ── progress ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Slider {
                id: progress
                Layout.fillWidth: true
                implicitHeight: 14
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
        }

        // ── controls ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            IconButton {
                size: 42
                glyph: "\uf048"
                enabled: root.p?.canGoPrevious ?? false
                onClicked: root.p.previous()
            }

            // play/pause: morphs between circle (paused) and rounded square (playing)
            Rectangle {
                id: playBtn
                Layout.preferredWidth: 64
                Layout.preferredHeight: 48
                radius: root.playing ? 16 : 24
                color: Theme.primary
                opacity: enabled ? 1 : 0.4
                enabled: root.p?.canTogglePlaying ?? false
                scale: playMouse.pressed ? 0.92 : 1

                Behavior on radius { Anim {} }
                Behavior on scale { Anim { duration: Theme.dur.fast } }

                Icon {
                    anchors.centerIn: parent
                    text: root.playing ? "\uf04c" : "\uf04b"
                    color: Theme.primaryFg
                    font.pixelSize: 18
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    onClicked: root.p.togglePlaying()
                }
            }

            IconButton {
                size: 42
                glyph: "\uf051"
                enabled: root.p?.canGoNext ?? false
                onClicked: root.p.next()
            }
        }
    }
}
