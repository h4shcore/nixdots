import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.services

// Mini month calendar shown in the notch when you click the clock.
// Arrows (or scroll) change month, clicking the title jumps back to today.
Item {
    id: root

    property bool shown: false

    readonly property var today: new Date(clk.date)
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property bool onToday: year === today.getFullYear() && month === today.getMonth()

    // JS weekday (0 = Sunday) the week starts on, from the locale
    readonly property int firstDow: Qt.locale().firstDayOfWeek % 7
    readonly property var gridStart: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - firstDow + 7) % 7;
        return new Date(year, month, 1 - offset);
    }

    implicitWidth: 420
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clk
        precision: SystemClock.Minutes
    }

    function shift(n) {
        const d = new Date(year, month + n, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    function goToday() {
        year = today.getFullYear();
        month = today.getMonth();
    }

    onShownChanged: if (!shown) goToday()

    WheelHandler {
        onWheel: ev => root.shift(ev.angleDelta.y < 0 ? 1 : -1)
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 8

        // ── header: month + nav ──
        Reveal {
            Layout.fillWidth: true
            shown: root.shown
            delay: 0

            RowLayout {
                width: parent.width
                height: 40
                spacing: 4

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 6
                        spacing: 8

                        Label {
                            text: Qt.locale().monthName(root.month, Locale.LongFormat)
                            font.bold: true
                            font.pixelSize: 20
                        }
                        Label {
                            Layout.alignment: Qt.AlignBaseline
                            text: root.year
                            font.pixelSize: 14
                            color: Look.fgDim
                        }

                        // "Today" chip appears when browsing another month
                        Rectangle {
                            visible: opacity > 0
                            opacity: root.onToday ? 0 : 1
                            Behavior on opacity { Anim { duration: 200; curve: Look.standard } }
                            implicitWidth: todayLbl.implicitWidth + 18
                            implicitHeight: 22
                            radius: 11
                            color: Look.secondaryContainer

                            Label {
                                id: todayLbl
                                anchors.centerIn: parent
                                text: "Today"
                                font.pixelSize: 11
                                font.bold: true
                                color: Look.primary
                            }
                            TapHandler { onTapped: root.goToday() }
                        }
                    }
                }

                IconButton {
                    size: 34
                    glyph: "\uf104"
                    onClicked: root.shift(-1)
                }
                IconButton {
                    size: 34
                    glyph: "\uf105"
                    onClicked: root.shift(1)
                }
            }
        }

        // ── weekdays + days ──
        Reveal {
            Layout.fillWidth: true
            shown: root.shown
            delay: 50

            ColumnLayout {
                width: parent.width
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: 7

                        Label {
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName((root.firstDow + index) % 7, Locale.ShortFormat).slice(0, 2)
                            font.pixelSize: 11
                            font.bold: true
                            color: Look.fgDim
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 2
                    columnSpacing: 0

                    Repeater {
                        model: 42

                        Item {
                            id: cell

                            required property int index

                            readonly property date d: new Date(root.gridStart.getFullYear(), root.gridStart.getMonth(), root.gridStart.getDate() + index)
                            readonly property bool inMonth: d.getMonth() === root.month
                            readonly property bool isToday: d.getFullYear() === root.today.getFullYear()
                                && d.getMonth() === root.today.getMonth()
                                && d.getDate() === root.today.getDate()

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 34

                            Rectangle {
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                radius: 16
                                color: cell.isToday ? Look.primary
                                    : dayMouse.containsMouse ? Look.surfaceHi : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Label {
                                    anchors.centerIn: parent
                                    text: cell.d.getDate()
                                    font.pixelSize: 13
                                    font.bold: cell.isToday
                                    color: cell.isToday ? Look.primaryFg : (cell.inMonth ? Look.fg : Look.fgDim)
                                    opacity: cell.inMonth || cell.isToday ? 1 : 0.45
                                }
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}
