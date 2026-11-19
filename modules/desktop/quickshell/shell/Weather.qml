pragma Singleton

import QtQuick
import Quickshell

// Current weather from Open-Meteo (Lublin, PL), refreshed every 30 minutes.
Singleton {
  id: root

  property bool ready: false
  property int temp: 0
  property int code: 0
  property bool isDay: true
  property string condition: ""
  property string location: "Lublin"

  readonly property string url:
    "https://api.open-meteo.com/v1/forecast?latitude=51.25&longitude=22.57&current=temperature_2m,weather_code,is_day&timezone=auto"

  function glyphFor(wmo, day) {
    if (wmo === 0 || wmo === 1) return day ? Theme.iSun : Theme.iMoon;
    if (wmo === 2 || wmo === 3 || wmo === 45 || wmo === 48) return Theme.iCloud;
    if (wmo >= 51 && wmo <= 67) return Theme.iRain;
    if (wmo >= 71 && wmo <= 77) return Theme.iSnow;
    if (wmo >= 80 && wmo <= 82) return Theme.iRain;
    if (wmo >= 85 && wmo <= 86) return Theme.iSnow;
    if (wmo >= 95) return Theme.iStorm;
    return Theme.iCloud;
  }

  function describe(wmo) {
    if (wmo === 0) return "Clear sky";
    if (wmo <= 2) return "Partly cloudy";
    if (wmo === 3) return "Overcast";
    if (wmo === 45 || wmo === 48) return "Foggy";
    if (wmo <= 57) return "Drizzle";
    if (wmo <= 67) return "Rain";
    if (wmo <= 77) return "Snow";
    if (wmo <= 82) return "Showers";
    if (wmo <= 86) return "Snow showers";
    if (wmo >= 95) return "Thunderstorm";
    return "Cloudy";
  }

  function refresh() {
    const req = new XMLHttpRequest();
    req.onreadystatechange = () => {
      if (req.readyState !== XMLHttpRequest.DONE) return;
      if (req.status === 200) {
        try {
          const c = JSON.parse(req.responseText).current;
          root.temp = Math.round(c.temperature_2m);
          root.code = c.weather_code;
          root.isDay = c.is_day === 1;
          root.condition = describe(c.weather_code);
          root.ready = true;
          return;
        } catch (e) {
          console.warn("weather: parse error", e);
        }
      }
      if (!root.ready) retryTimer.restart();
    };
    req.open("GET", url);
    req.send();
  }

  Timer {
    id: retryTimer
    interval: 30 * 1000
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
