import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

// Tray icons (one row): left = activate, right = app menu (shown inside the notch),
// middle = secondary action. Hover info is exposed for the tooltip in the bar.
Row {
    id: root

    property int cell: 32
    property int iconSize: 20
    property var hoveredItem: null
    property real hoverX: 0
    signal menuRequested(var item)

    spacing: 4

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            width: root.cell
            height: root.cell
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onContainsMouseChanged: {
                if (containsMouse) {
                    root.hoveredItem = modelData;
                    root.hoverX = item.x + item.width / 2;
                } else if (root.hoveredItem === modelData) {
                    root.hoveredItem = null;
                }
            }

            onClicked: m => {
                if (m.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (m.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) root.menuRequested(modelData);
                } else {
                    modelData.activate();
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: item.containsMouse ? Look.surfaceHiest : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            IconImage {
                anchors.centerIn: parent
                width: root.iconSize
                height: root.iconSize
                source: item.modelData.icon
                scale: item.containsMouse ? 1.15 : 1
                Behavior on scale { Anim { duration: Look.dur.fast } }
            }
        }
    }
}
