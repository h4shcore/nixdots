import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.common
import qs.services

// Compact now-playing card: art, title/artist, slim progress, centered controls.
ClippingRectangle {
    id: root

    readonly property MprisPlayer p: Players.active
    readonly property bool playing: p?.isPlaying ?? false
    readonly property bool busy: progress.pressed

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    implicitHeight: col.implicitHeight + 28
    radius: 24
    color: Look.surfaceHi

    // position isn't pushed by MPRIS, so poke it while playing and visible
    Timer {
        running: root.visible && root.playing
        interval: 1000
        repeat: true
        onTriggered: if (root.p) root.p.positionChanged()
    }

    // soft primary wash from the left edge
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(Look.primary, 0.12) }
            GradientStop { position: 0.8; color: Qt.alpha(Look.primary, 0) }
        }
    }

    // fade + lift whenever the track changes
    ParallelAnimation {
        id: trackAnim
        Anim { target: info; property: "opacity"; from: 0; to: 1; duration: 300; curve: Look.standard }
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
            margins: 14
        }
        spacing: 10

        // ── art + info ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {
                id: tile
                Layout.preferredWidth: 68
                Layout.preferredHeight: 68
                radius: 18
                color: Look.surfaceHiest
                scale: root.playing ? 1 : 0.94
                Behavior on scale { Anim {} }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.p?.trackArtUrl ?? ""
                    sourceSize: Qt.size(192, 192)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { Anim { duration: 300; curve: Look.standard } }
                }
                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "\uf001"
                    font.pixelSize: 26
                    color: Look.fgDim
                }
            }

            ColumnLayout {
                id: info
                Layout.fillWidth: true
                spacing: 2
                transform: Translate { id: infoShift }

                RowLayout {
                    spacing: 7

                    // equalizer bars
                    Row {
                        spacing: 2
                        Repeater {
                            model: [340, 460, 300, 400]

                            Item {
                                required property int modelData
                                width: 3
                                height: 12

                                Rectangle {
                                    id: bar
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    height: 3
                                    radius: 1.5
                                    color: Look.primary

                                    SequentialAnimation {
                                        running: root.playing
                                        loops: Animation.Infinite
                                        onRunningChanged: if (!running) bar.height = 3
                                        NumberAnimation { target: bar; property: "height"; to: 12; duration: modelData; easing.type: Easing.InOutSine }
                                        NumberAnimation { target: bar; property: "height"; to: 3; duration: modelData; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: (root.p?.identity ?? "").toUpperCase()
                        color: Look.primary
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: root.p?.trackTitle || "Nothing playing"
                    font.bold: true
                    font.pixelSize: 15
                }
                Label {
                    Layout.fillWidth: true
                    text: root.p?.trackArtist ?? ""
                    color: Look.fgDim
                    font.pixelSize: 12
                }
            }
        }

        // ── progress: time · bar · time ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: root.fmt(root.p?.position)
                color: Look.fgDim
                font.pixelSize: 10
            }
            WaveSlider {
                id: progress
                Layout.fillWidth: true
                implicitHeight: 22
                playing: root.playing
                value: root.p && root.p.length > 0 ? root.p.position / root.p.length : 0
                enabled: root.p?.canSeek ?? false
                onMoved: v => { if (root.p && root.p.canSeek) root.p.position = v * root.p.length; }
            }
            Label {
                text: root.fmt(root.p?.length)
                color: Look.fgDim
                font.pixelSize: 10
            }
        }

        // ── controls ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            IconButton {
                size: 38
                glyph: "\uf048"
                enabled: root.p?.canGoPrevious ?? false
                onClicked: root.p.previous()
            }

            // play/pause: morphs between circle (paused) and rounded square (playing)
            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 42
                radius: root.playing ? 15 : 21
                color: Look.primary
                opacity: enabled ? 1 : 0.4
                enabled: root.p?.canTogglePlaying ?? false
                scale: playMouse.pressed ? 0.92 : 1

                Behavior on radius { Anim {} }
                Behavior on scale { Anim { duration: Look.dur.fast } }

                Icon {
                    anchors.centerIn: parent
                    text: root.playing ? "\uf04c" : "\uf04b"
                    color: Look.primaryFg
                    font.pixelSize: 17
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    onClicked: root.p.togglePlaying()
                }
            }

            IconButton {
                size: 38
                glyph: "\uf051"
                enabled: root.p?.canGoNext ?? false
                onClicked: root.p.next()
            }
        }
    }
}
