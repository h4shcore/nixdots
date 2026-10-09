import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

PickerPanel {
    id: root

    title: "Wi-Fi"
    icon: "wifi"
    subtitle: !Network.enabled ? "Off" : (Network.connecting ? Network.status : (Network.ssid || "Not connected"))

    headerRight: [
        IconButton {
            size: 32
            glyph: "refresh"
            enabled: Network.enabled
            onClicked: Network.scan()
        },
        Pill {
            implicitHeight: 30
            text: Network.enabled ? "On" : "Off"
            selected: Network.enabled
            onClicked: Network.toggle()
        }
    ]

    function bars(signal) {
        return signal >= 75 ? "wifi" : signal >= 50 ? "network_wifi_3_bar" : signal >= 25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    onVisibleChanged: {
        if (visible) Network.scan();
        else Network.cancelPassword();
    }

    Connections {
        target: Network
        function onNeedPasswordChanged() {
            if (Network.needPassword !== "") {
                pw.text = "";
                Qt.callLater(() => pw.forceActiveFocus());
            }
        }
    }

    // password prompt for a new secured network
    Rectangle {
        Layout.fillWidth: true
        visible: Network.needPassword !== ""
        implicitHeight: pwCol.implicitHeight + 24
        radius: 18
        color: Look.surfaceHi

        ColumnLayout {
            id: pwCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: "Password for " + Network.needPassword
                font.bold: true
                font.pixelSize: 13
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: Network.status
                color: Look.error
                font.pixelSize: 11
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: 20
                color: Look.surfaceHiest

                TextInput {
                    id: pw
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Look.fg
                    selectionColor: Look.primary
                    selectedTextColor: Look.primaryFg
                    font.family: Look.font
                    font.pixelSize: 14
                    clip: true
                    onAccepted: Network.submitPassword(text)
                    Keys.onEscapePressed: Network.cancelPassword()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }
                Pill {
                    implicitHeight: 32
                    text: "Cancel"
                    onClicked: Network.cancelPassword()
                }
                Pill {
                    implicitHeight: 32
                    text: "Connect"
                    selected: true
                    onClicked: Network.submitPassword(pw.text)
                }
            }
        }
    }

    Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        visible: Network.needPassword === "" && (!Network.enabled || Network.networks.length === 0)
        text: !Network.enabled ? "Wi-Fi is off" : (Network.scanning ? "Searching…" : "No networks found")
        color: Look.fgDim
    }

    Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        visible: Network.needPassword === "" && Network.status !== "" && !Network.connecting
        text: Network.status
        color: Look.error
        font.pixelSize: 11
    }

    ListView {
        id: lv
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 288)
        visible: Network.enabled && Network.needPassword === "" && Network.networks.length > 0
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: Network.networks
            objectProp: "ssid"
        }

        delegate: PickerRow {
            id: row

            required property var modelData

            width: ListView.view.width
            glyph: root.bars(modelData.signal)
            title: modelData.ssid
            subtitle: modelData.inUse ? "Connected" : (Network.saved[modelData.ssid] ? "Saved" : (modelData.secure ? "Secured" : "Open"))
            active: modelData.inUse
            onClicked: Network.connectTo(modelData)

            InkIcon {
                visible: modelData.secure
                text: "lock"
                pixelSize: 13
                box: 20
                color: Look.fgDim
            }
            IconButton {
                visible: !!Network.saved[modelData.ssid] && !modelData.inUse
                size: 28
                glyph: "delete"
                onClicked: Network.forget(modelData.ssid)
            }
        }
    }
}
