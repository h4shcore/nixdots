import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common

// Renders a tray app's own menu (QsMenuOpener) inside the notch, with submenu navigation.
Item {
    id: root

    property var item: null     // SystemTrayItem
    property var stack: []      // opened submenu entries
    signal close

    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : (item ? item.menu : null)
    readonly property string title: stack.length > 0 ? stack[stack.length - 1].text : (item ? (item.title || item.id) : "")

    implicitWidth: 360
    implicitHeight: col.implicitHeight

    onItemChanged: stack = []

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconButton {
                size: 32
                glyph: "\uf104"
                onClicked: {
                    if (root.stack.length > 0) root.stack = root.stack.slice(0, -1);
                    else root.close();
                }
            }
            IconImage {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                visible: root.item !== null && root.stack.length === 0
                source: root.item ? root.item.icon : ""
            }
            Label {
                Layout.fillWidth: true
                text: root.title
                font.bold: true
                font.pixelSize: 14
            }
        }

        ListView {
            id: lv
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 320)
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: opener.children

            delegate: Item {
                id: row

                required property var modelData

                width: ListView.view.width
                height: modelData.isSeparator ? 9 : 36

                Rectangle {
                    visible: row.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    width: parent.width - 24
                    height: 1
                    color: Look.outline
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !row.modelData.isSeparator
                    radius: 12
                    color: rowMouse.containsMouse && row.modelData.enabled ? Look.surfaceHiest : "transparent"
                    opacity: row.modelData.enabled ? 1 : 0.4
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 10

                        Icon {
                            Layout.preferredWidth: 14
                            visible: row.modelData.buttonType !== QsMenuButtonType.None
                            text: row.modelData.checkState === Qt.Checked ? "\uf00c" : ""
                            font.pixelSize: 12
                            color: Look.primary
                        }
                        IconImage {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            visible: row.modelData.icon !== ""
                            source: row.modelData.icon
                        }
                        Label {
                            Layout.fillWidth: true
                            text: row.modelData.text
                        }
                        Icon {
                            visible: row.modelData.hasChildren
                            text: "\uf105"
                            color: Look.fgDim
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.modelData.isSeparator && row.modelData.enabled
                        onClicked: {
                            if (row.modelData.hasChildren) {
                                root.stack = [...root.stack, row.modelData];
                            } else {
                                row.modelData.triggered();
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
