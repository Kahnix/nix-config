//@ pragma AppId dev.kahnix.greeter

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Greetd

ShellRoot {
  id: root

  property string statusText: "Enter your password"
  property bool authenticating: false

  function beginAuthentication() {
    if (!Greetd.available || username.text.trim().length === 0 || authenticating) return;
    authenticating = true;
    statusText = "Starting session";
    Greetd.createSession(username.text.trim());
  }

  function submit() {
    if (!authenticating) {
      beginAuthentication();
      return;
    }

    if (password.text.length > 0) {
      statusText = "Authenticating";
      Greetd.respond(password.text);
      password.text = "";
    }
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      root.statusText = error ? message : "Enter your password";
      if (responseRequired) {
        password.echoMode = echoResponse ? TextInput.Normal : TextInput.Password;
        Qt.callLater(() => password.forceActiveFocus());
      }
    }

    function onAuthFailure(message) {
      root.statusText = message || "Authentication failed";
      root.authenticating = false;
      password.text = "";
      failureReset.restart();
    }

    function onReadyToLaunch() {
      root.statusText = "Welcome back";
      Greetd.launch(
        [Quickshell.env("KACPER_SESSION")],
        [
          "XDG_CURRENT_DESKTOP=Hyprland",
          "XDG_SESSION_DESKTOP=Hyprland",
          "XDG_SESSION_TYPE=wayland"
        ]
      );
    }

    function onError(message) {
      root.statusText = message;
      root.authenticating = false;
    }
  }

  Timer {
    id: failureReset
    interval: 900
    onTriggered: root.beginAuthentication()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  FloatingWindow {
    id: window
    visible: true
    color: "#111116"
    implicitWidth: 1920
    implicitHeight: 1080

    Image {
      anchors.fill: parent
      source: Quickshell.env("KACPER_WALLPAPER")
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }

    Rectangle {
      anchors.fill: parent
      color: "#111116"
      opacity: 0.28
    }

    ColumnLayout {
      anchors {
        horizontalCenter: parent.horizontalCenter
        top: parent.top
        topMargin: Math.max(56, parent.height * 0.12)
      }
      spacing: 2

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: "#dcd7ba"
        font.family: "Departure Mono"
        font.pixelSize: 70
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(clock.date, "dddd, dd MMMM")
        color: "#a6a69c"
        font.family: "Departure Mono"
        font.pixelSize: 15
      }
    }

    Rectangle {
      id: loginPanel
      anchors.centerIn: parent
      width: Math.min(360, parent.width - 48)
      height: 244
      radius: 4
      color: Qt.rgba(0.07, 0.07, 0.09, 0.94)
      border.width: 1
      border.color: "#363646"

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        RowLayout {
          Layout.fillWidth: true

          Text {
            Layout.fillWidth: true
            text: "KAHNIX"
            color: "#dcd7ba"
            font.family: "Departure Mono"
            font.pixelSize: 14
            font.bold: true
          }

          Rectangle {
            Layout.preferredWidth: 7
            Layout.preferredHeight: 7
            radius: 4
            color: Greetd.available ? "#98bb6c" : "#e46876"
          }
        }

        LoginField {
          id: username
          Layout.fillWidth: true
          label: "USER"
          text: "kacper"
          onAccepted: root.beginAuthentication()
        }

        LoginField {
          id: password
          Layout.fillWidth: true
          label: "PASSWORD"
          echoMode: TextInput.Password
          onAccepted: root.submit()
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: 2

          Text {
            Layout.fillWidth: true
            text: root.statusText
            color: root.statusText.toLowerCase().includes("failed") ? "#e46876" : "#727169"
            font.family: "Departure Mono"
            font.pixelSize: 9
            elide: Text.ElideRight
          }

          Rectangle {
            Layout.preferredWidth: 88
            Layout.preferredHeight: 31
            radius: 4
            color: loginHover.hovered ? "#91a8d0" : "#7e9cd8"

            Text {
              anchors.centerIn: parent
              text: "LOG IN"
              color: "#111116"
              font.family: "Departure Mono"
              font.pixelSize: 10
              font.bold: true
            }

            HoverHandler { id: loginHover }
            TapHandler { onTapped: root.submit() }
          }
        }
      }
    }

    Row {
      anchors {
        right: parent.right
        bottom: parent.bottom
        margins: 22
      }
      spacing: 8

      SessionButton {
        icon: "󰜉"
        label: "Restart"
        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
      }
      SessionButton {
        icon: "󰐥"
        label: "Shut down"
        danger: true
        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
      }
    }

    Component.onCompleted: Qt.callLater(() => {
      password.forceActiveFocus();
      root.beginAuthentication();
    })
  }
}
