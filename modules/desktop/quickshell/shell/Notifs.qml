pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. Everything received stays in `list` (the control
// center's history) until dismissed; `popups` is the subset shown as toasts.
Singleton {
  id: root

  property bool dnd: false
  property var popups: []
  property var arrived: ({})

  // Newest first.
  readonly property var list: Array.from(server.trackedNotifications.values).reverse()
  readonly property int count: list.length

  NotificationServer {
    id: server
    keepOnReload: true
    persistenceSupported: true
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    imageSupported: true

    onNotification: n => {
      n.tracked = true;
      root.arrived[n.id] = Date.now();
      if (!root.dnd || n.urgency === NotificationUrgency.Critical)
        root.popups = [n].concat(root.popups.filter(p => p.id !== n.id)).slice(0, 5);
      n.closed.connect(() => root.hide(n));
    }
  }

  function hide(n) {
    popups = popups.filter(p => p !== n);
  }

  function clear() {
    const all = Array.from(server.trackedNotifications.values);
    popups = [];
    for (const n of all) n.dismiss();
  }

  // The "default" action is what a click on the notification body means.
  function activate(n) {
    const action = Ui.find(n.actions, a => a.identifier === "default");
    if (action) action.invoke();
    else n.dismiss();
  }
}
