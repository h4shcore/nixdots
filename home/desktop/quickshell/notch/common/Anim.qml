import QtQuick

NumberAnimation {
    property var curve: Theme.spring
    duration: Theme.dur.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
