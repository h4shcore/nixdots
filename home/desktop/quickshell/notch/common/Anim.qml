import QtQuick

NumberAnimation {
    property var curve: Look.spring
    duration: Look.dur.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
