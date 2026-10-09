import QtQuick
import QtQuick.Layouts

// Frame for the Wi-Fi / Bluetooth / Sound pickers: back button + title, then your content.
Item {
    id: root

    property string title
    property string icon
    property string subtitle
    default property alias content: body.data
    property alias headerRight: right.data
    signal back

    implicitWidth: 360
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconButton {
                size: 32
                glyph: "arrow_back"
                onClicked: root.back()
            }
            InkIcon {
                text: root.icon
                color: Look.primary
                pixelSize: 16
                box: 24
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: root.title
                    font.bold: true
                    font.pixelSize: 14
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.subtitle
                    color: Look.fgDim
                    font.pixelSize: 11
                }
            }
            RowLayout {
                id: right
                spacing: 6
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 6
        }
    }
}
