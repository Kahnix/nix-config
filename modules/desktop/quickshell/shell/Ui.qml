pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which panel is open, plus helpers shared by every component.
Singleton {
  id: root

  property bool launcherOpen: false
  property string launcherMode: "apps" // "apps" | "clipboard"
  property bool controlOpen: false
  property string controlTab: "overview" // "overview" | "services" | "displays" | "wallpaper" | "ai"
  property bool calendarOpen: false
  property bool sessionOpen: false
  property bool keepAwake: false

  // A focus grab clears on the same click that hits a bar button; without
  // this the button would immediately reopen the panel it just closed.
  property real controlClosedAt: 0
  property real calendarClosedAt: 0

  readonly property ShellScreen activeScreen: {
    const name = Hyprland.focusedMonitor?.name;
    const screens = Quickshell.screens;
    for (let i = 0; i < screens.length; i++)
      if (screens[i].name === name) return screens[i];
    return screens.length > 0 ? screens[0] : null;
  }

  function closeAll() {
    launcherOpen = false;
    controlOpen = false;
    calendarOpen = false;
    sessionOpen = false;
  }

  function toggleLauncher(mode) {
    const reopen = !launcherOpen || launcherMode !== mode;
    closeAll();
    launcherMode = mode;
    launcherOpen = reopen;
  }

  function toggleControl() {
    if (!controlOpen && Date.now() - controlClosedAt < 250) return;
    const open = !controlOpen;
    closeAll();
    controlOpen = open;
  }

  function openControlTab(tab) {
    if (controlOpen && controlTab === tab) {
      closeControl();
      return;
    }
    if (!controlOpen && Date.now() - controlClosedAt < 250) return;
    closeAll();
    controlTab = tab;
    controlOpen = true;
  }

  function closeControl() {
    controlOpen = false;
    controlClosedAt = Date.now();
  }

  function toggleCalendar() {
    if (!calendarOpen && Date.now() - calendarClosedAt < 250) return;
    const open = !calendarOpen;
    closeAll();
    calendarOpen = open;
  }

  function closeCalendar() {
    calendarOpen = false;
    calendarClosedAt = Date.now();
  }

  function toggleSession() {
    const open = !sessionOpen;
    closeAll();
    sessionOpen = open;
  }

  // Apps go through UWSM so each gets its own systemd scope: restarting the
  // shell's unit (every rebuild) must not take launched programs with it.
  function run(command) {
    Quickshell.execDetached(["uwsm", "app", "--"].concat(command));
  }

  // Hyprland's Lua config takes Lua dispatcher expressions over IPC.
  function dispatch(lua) {
    Quickshell.execDetached(["hyprctl", "dispatch", lua]);
  }

  function find(list, predicate) {
    for (let i = 0; i < list.length; i++)
      if (predicate(list[i])) return list[i];
    return null;
  }

  function ago(ms) {
    const s = Math.floor((Date.now() - ms) / 1000);
    if (s < 60) return "now";
    if (s < 3600) return Math.floor(s / 60) + "m";
    if (s < 86400) return Math.floor(s / 3600) + "h";
    return Math.floor(s / 86400) + "d";
  }
}
