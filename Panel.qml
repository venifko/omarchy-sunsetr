import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "venifko.sunsetr"
  ipcTarget: "venifko.sunsetr"

  property bool available: false
  property bool running: false
  property bool busy: false
  property bool enabled: true
  property string mode: "auto"
  property string effectiveMode: "auto"
  property string phase: "daylight"
  property string nextPhase: ""
  property string nextTransition: ""
  property string sunsetTime: ""
  property int temperature: 6500
  property int daylightTemp: 6500
  property int eveningTemp: 4000
  property int bedtimeTemp: 2800
  property int neutralTemp: 6500
  property int manualTemp: 4500
  property string scheduleMode: "solar"
  property string wakeTime: "06:30"
  property string sleepTime: "22:30"
  property string eveningTime: "18:30"
  property int transitionMinutes: 60
  property int windDownMinutes: 120
  property real latitude: 49.3961
  property real longitude: 15.5912
  property bool disableFullscreen: false
  property var excludedApps: []
  property var monitors: []
  property var disabledOutputs: []
  property bool perDisplayAvailable: false
  property string backend: "sunsetr"
  property string activeApp: ""
  property string activeTitle: ""
  property bool activeFullscreen: false
  property string overrideReason: ""
  property string errorText: ""
  property string page: "main"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color muted: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string icon: effectiveMode === "disabled" ? "󰖔" : (phase === "daylight" ? "󰖨" : "󰖔")
  readonly property string statusLabel: effectiveMode === "disabled"
    ? "DISABLED · " + overrideReason.toUpperCase()
    : effectiveMode === "manual" ? "MANUAL" : effectiveMode === "neutral" ? "NEUTRAL" : phase.toUpperCase()

  function scriptPath() {
    var url = String(Qt.resolvedUrl("scripts/sunsetr-control"))
    return decodeURIComponent(url.replace(/^file:\/\//, ""))
  }

  function applyState(line) {
    var s
    try { s = JSON.parse(String(line || "")) } catch (exception) { return }
    if (!s || typeof s !== "object") return
    var keys = ["available", "running", "enabled", "mode", "effectiveMode", "phase",
      "nextPhase", "nextTransition", "sunsetTime", "temperature", "daylightTemp",
      "eveningTemp", "bedtimeTemp", "neutralTemp", "manualTemp", "scheduleMode",
      "wakeTime", "sleepTime", "eveningTime", "transitionMinutes", "windDownMinutes",
      "latitude", "longitude", "disableFullscreen", "excludedApps", "monitors",
      "disabledOutputs", "perDisplayAvailable", "backend", "activeApp", "activeTitle",
      "activeFullscreen", "overrideReason"]
    for (var i = 0; i < keys.length; i++)
      if (s[keys[i]] !== undefined) root[keys[i]] = s[keys[i]]
    errorText = String(s.error || "")
  }

  function runAction(args) {
    if (busy) return
    busy = true
    actionProcess.command = [scriptPath()].concat(args)
    actionProcess.running = true
  }
  function setValue(key, value) { runAction(["set", key, String(value)]) }
  function adjust(key, value, delta) { setValue(key, Math.max(1000, Math.min(10000, value + delta))) }

  implicitWidth: barButton.implicitWidth
  implicitHeight: barButton.implicitHeight
  onOpenedChanged: if (opened) { page = "main"; reconcile() }

  function reconcile() { if (!busy && !reconcileProcess.running) reconcileProcess.running = true }

  Timer { interval: 2000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.reconcile() }
  Process {
    id: reconcileProcess
    command: [root.scriptPath(), "reconcile"]
    stdout: SplitParser { onRead: function(line) { root.applyState(line) } }
  }
  Process {
    id: actionProcess
    stdout: SplitParser { onRead: function(line) { root.applyState(line) } }
    stderr: SplitParser { onRead: function(line) { if (String(line).trim()) root.errorText = String(line).trim() } }
    onExited: function(exitCode) { root.busy = false; root.reconcile() }
  }

  BarIconButton {
    id: barButton
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    fontFamily: root.fontFamily
    active: root.running && root.enabled && root.effectiveMode === "auto"
    activeColor: Color.accent
    tooltipText: "Sunsetr · " + root.statusLabel + " · " + root.temperature + " K"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.runAction(["disable", root.overrideReason === "" ? "3600" : "clear"])
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: barButton
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: parent.width
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(10)
        Button { text: root.page === "main" ? "● Controls" : "Controls"; selected: root.page === "main"; onClicked: root.page = "main" }
        Button { text: root.page === "settings" ? "● Schedule & rules" : "Schedule & rules"; selected: root.page === "settings"; onClicked: root.page = "settings" }
      }

      Column {
        visible: root.page === "main"
        width: parent.width
        spacing: Style.space(10)

        Row {
          width: parent.width
          spacing: Style.space(12)
          Text { text: root.icon; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.display }
          Column {
            width: parent.width - Style.space(58)
            Text { text: root.temperature + " K"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.title; font.bold: true }
            Text { text: root.statusLabel; color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1 }
            Text { visible: root.effectiveMode === "auto"; text: "Next: " + root.nextPhase + " at " + root.nextTransition; color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          }
        }

        PanelSeparator { foreground: root.foreground }

        Row {
          width: parent.width; spacing: Style.space(5)
          Repeater {
            model: [{key:"auto",label:"Automatic"},{key:"manual",label:"Manual"},{key:"neutral",label:"Neutral"}]
            Button {
              required property var modelData
              width: (parent.width - parent.spacing * 2) / 3
              text: modelData.label; selected: root.mode === modelData.key
              enabled: !root.busy; onClicked: root.runAction(["mode", modelData.key])
            }
          }
        }

        Row {
          visible: root.mode === "manual"
          width: parent.width; spacing: Style.space(6)
          Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - down.width - up.width - parent.spacing * 2; text: "Manual temperature · " + root.manualTemp + " K"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }
          Button { id: down; text: "−250"; onClicked: root.adjust("manualTemp", root.manualTemp, -250) }
          Button { id: up; text: "+250"; onClicked: root.adjust("manualTemp", root.manualTemp, 250) }
        }

        PanelSectionHeader { text: "QUICK DISABLE"; foreground: root.foreground; fontFamily: root.fontFamily }
        Row {
          width: parent.width; spacing: Style.space(5)
          Button { width: (parent.width - parent.spacing * 2) / 3; text: "1 hour"; onClicked: root.runAction(["disable", "3600"]) }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: "Until wake"; onClicked: root.runAction(["disable", "wake"]) }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: "Resume"; enabled: root.overrideReason !== ""; onClicked: root.runAction(["disable", "clear"]) }
        }

        PanelSectionHeader { text: "CURRENT APP"; foreground: root.foreground; fontFamily: root.fontFamily }
        Text { width: parent.width; text: root.activeApp || "No active app"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; elide: Text.ElideRight }
        Button {
          width: parent.width
          text: root.excludedApps.indexOf(root.activeApp.toLowerCase()) >= 0 ? "Enable for this app" : "Disable for this app"
          enabled: root.activeApp !== ""; onClicked: root.runAction(["toggle-app"])
        }

        PanelSectionHeader { text: "COLOR TEMPERATURES"; foreground: root.foreground; fontFamily: root.fontFamily }
        Repeater {
          model: [{key:"daylightTemp",label:"Daylight",value:root.daylightTemp},
                  {key:"eveningTemp",label:"Evening",value:root.eveningTemp},
                  {key:"bedtimeTemp",label:"Bedtime",value:root.bedtimeTemp},
                  {key:"neutralTemp",label:"Disabled / neutral",value:root.neutralTemp}]
          Row {
            required property var modelData
            width: parent.width; spacing: Style.space(5)
            Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - minus.width - plus.width - parent.spacing * 2; text: modelData.label + " · " + modelData.value + " K"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }
            Button { id: minus; text: "−250"; onClicked: root.adjust(modelData.key, modelData.value, -250) }
            Button { id: plus; text: "+250"; onClicked: root.adjust(modelData.key, modelData.value, 250) }
          }
        }
      }

      Column {
        visible: root.page === "settings"
        width: parent.width
        spacing: Style.space(9)

        PanelSectionHeader { text: "CIRCADIAN SCHEDULE"; foreground: root.foreground; fontFamily: root.fontFamily }
        Row {
          width: parent.width; spacing: Style.space(6)
          TextField { id: wakeField; width: (parent.width - parent.spacing) / 2; placeholderText: "Wake HH:MM"; text: root.wakeTime; onAccepted: root.setValue("wakeTime", text) }
          TextField { id: sleepField; width: (parent.width - parent.spacing) / 2; placeholderText: "Sleep HH:MM"; text: root.sleepTime; onAccepted: root.setValue("sleepTime", text) }
        }
        Button { width: parent.width; text: "Save wake " + wakeField.text + " · sleep " + sleepField.text; onClicked: root.runAction(["set-schedule", wakeField.text, sleepField.text]) }

        Row {
          width: parent.width; spacing: Style.space(6)
          Button { width: (parent.width-parent.spacing)/2; text: "Sun-based"; selected: root.scheduleMode === "solar"; onClicked: root.setValue("scheduleMode", "solar") }
          Button { width: (parent.width-parent.spacing)/2; text: "Fixed time"; selected: root.scheduleMode === "clock"; onClicked: root.setValue("scheduleMode", "clock") }
        }

        Row {
          visible: root.scheduleMode === "clock"
          width: parent.width; spacing: Style.space(6)
          TextField { id: eveningField; width: parent.width - eveningSave.width - parent.spacing; placeholderText: "Evening HH:MM"; text: root.eveningTime; onAccepted: root.setValue("eveningTime", text) }
          Button { id: eveningSave; text: "Save"; onClicked: root.setValue("eveningTime", eveningField.text) }
        }

        Column {
          visible: root.scheduleMode === "solar"
          width: parent.width; spacing: Style.space(5)
          Text { text: "Manual location · sunset today " + root.sunsetTime; color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
          Row {
            width: parent.width; spacing: Style.space(6)
            TextField { id: latField; width: (parent.width-parent.spacing)/2; placeholderText: "Latitude"; text: String(root.latitude) }
            TextField { id: lonField; width: (parent.width-parent.spacing)/2; placeholderText: "Longitude"; text: String(root.longitude) }
          }
          Button { width: parent.width; text: "Save coordinates"; onClicked: root.runAction(["set-location", latField.text, lonField.text]) }
        }

        Row {
          width: parent.width; spacing: Style.space(6)
          Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - windMinus.width - windPlus.width - parent.spacing*2; text: "Wind-down before sleep · " + root.windDownMinutes + " min"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }
          Button { id: windMinus; text: "−30"; onClicked: root.setValue("windDownMinutes", Math.max(30, root.windDownMinutes-30)) }
          Button { id: windPlus; text: "+30"; onClicked: root.setValue("windDownMinutes", Math.min(360, root.windDownMinutes+30)) }
        }
        Row {
          width: parent.width; spacing: Style.space(6)
          Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - transitionMinus.width - transitionPlus.width - parent.spacing*2; text: "Color transition · " + root.transitionMinutes + " min"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }
          Button { id: transitionMinus; text: "−15"; onClicked: root.setValue("transitionMinutes", Math.max(5, root.transitionMinutes-15)) }
          Button { id: transitionPlus; text: "+15"; onClicked: root.setValue("transitionMinutes", Math.min(180, root.transitionMinutes+15)) }
        }

        PanelSectionHeader { text: "AUTOMATIC EXCEPTIONS"; foreground: root.foreground; fontFamily: root.fontFamily }
        Button { width: parent.width; text: (root.disableFullscreen ? "✓ " : "") + "Disable in fullscreen"; selected: root.disableFullscreen; onClicked: root.setValue("disableFullscreen", !root.disableFullscreen) }
        Repeater {
          model: root.excludedApps
          Button { required property var modelData; width: parent.width; text: "Remove app rule · " + modelData; onClicked: root.runAction(["remove-app", modelData]) }
        }

        PanelSectionHeader { text: "DISPLAYS"; foreground: root.foreground; fontFamily: root.fontFamily }
        Text { width: parent.width; text: root.perDisplayAvailable ? "Choose displays independently." : "Current sunsetr backend controls all displays together. Per-display switches are shown read-only until a compatible output backend is installed."; color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
        Repeater {
          model: root.monitors
          Button { required property var modelData; width: parent.width; text: (root.disabledOutputs.indexOf(modelData.name) < 0 ? "✓ " : "") + modelData.name + " · " + modelData.description; enabled: root.perDisplayAvailable; onClicked: root.runAction(["toggle-output", modelData.name]) }
        }
        Text { width: parent.width; visible: root.errorText !== ""; text: root.errorText; color: Color.urgent; font.family: root.fontFamily; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
      }
    }
  }
}
