pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<Entry> list: []
    readonly property list<Entry> popups: list.filter(e => e.popup)
    readonly property int count: list.length
    property bool dnd: false

    function clearAll() {
        for (const e of list.filter(() => true))
            e.notif.dismiss();
    }

    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            root.list = [entryComp.createObject(root, { notif: n }), ...root.list];
        }
    }

    Component {
        id: entryComp
        Entry {}
    }

    component Entry: QtObject {
        id: entry

        required property Notification notif
        readonly property bool critical: notif.urgency === NotificationUrgency.Critical
        property bool popup: !root.dnd

        readonly property Timer timer: Timer {
            running: entry.popup && !entry.critical
            interval: entry.notif.expireTimeout > 0 ? entry.notif.expireTimeout * 1000 : 6000
            onTriggered: entry.popup = false
        }

        readonly property Connections conn: Connections {
            target: entry.notif
            function onClosed() {
                root.list = root.list.filter(e => e !== entry);
                entry.destroy(1500);
            }
        }
    }
}
