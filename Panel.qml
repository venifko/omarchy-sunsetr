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
  property bool automatic: true
  property bool busy: false
  property string activePreset: "unknown"
  property string scheduledPreset: "unknown"
  property var temperature: null
  property var gamma: null
  property int daylightTemp: 6500
  property int eveningTemp: 4000
  property int bedtimeTemp: 2800
  property int neutralTemp: 6500
  property string errorText: ""

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color muted: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string icon: automatic ? "󰖨" : "󰖔"
  readonly property string temperatureLabel: temperature === null ? "--" : Math.round(temperature) + " K"

  function scriptPath() {
    var url = String(Qt.resolvedUrl("scripts/sunsetr-control"))
    return decodeURIComponent(url.replace(/^file:\/\//, ""))
  }

  function applyState(line) {
    var state
    try { state = JSON.parse(String(line || "")) } catch (exception) { return }
    if (!state || typeof state !== "object") return
    if (state.available !== undefined) available = state.available === true
    if (state.running !== undefined) running = state.running === true
    if (state.automatic !== undefined) automatic = state.automatic === true
    if (state.activePreset !== undefined) activePreset = String(state.activePreset)
    if (state.scheduledPreset !== undefined) scheduledPreset = String(state.scheduledPreset)
    temperature = state.temperature === null || state.temperature === undefined ? null : Number(state.temperature)
    gamma = state.gamma === null || state.gamma === undefined ? null : Number(state.gamma)
    if (state.daylightTemp !== undefined) daylightTemp = Number(state.daylightTemp)
    if (state.eveningTemp !== undefined) eveningTemp = Number(state.eveningTemp)
    if (state.bedtimeTemp !== undefined) bedtimeTemp = Number(state.bedtimeTemp)
    if (state.neutralTemp !== undefined) neutralTemp = Number(state.neutralTemp)
    errorText = String(state.error || "")
  }

  function refresh() {
    if (busy) return
    statusProcess.running = true
  }

  function runAction(args) {
    if (busy) return
    busy = true
    actionProcess.command = [scriptPath()].concat(args)
    actionProcess.running = true
  }

  function adjust(kind, current, delta) {
    runAction(["set-temp", kind, String(Math.max(1000, Math.min(10000, current + delta)))])
  }

  implicitWidth: barButton.implicitWidth
  implicitHeight: barButton.implicitHeight

  onOpenedChanged: if (opened) refresh()

  Timer {
    interval: 30000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess
    command: [root.scriptPath(), "status"]
    stdout: SplitParser { onRead: function(line) { root.applyState(line) } }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.errorText = "Could not read sunsetr status"
    }
  }

  Process {
    id: actionProcess
    stdout: SplitParser { onRead: function(line) { root.applyState(line) } }
    stderr: SplitParser { onRead: function(line) { if (String(line).trim()) root.errorText = String(line).trim() } }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode !== 0 && root.errorText === "") root.errorText = "sunsetr command failed"
      root.refresh()
    }
  }

  BarIconButton {
    id: barButton
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    fontFamily: root.fontFamily
    active: root.running && root.automatic
    activeColor: Color.accent
    tooltipText: "Sunsetr · " + (root.automatic ? "Automatic" : "Neutral") + " · " + root.temperatureLabel
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.runAction(["mode", root.automatic ? "neutral" : "auto"])
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: barButton
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: parent.width
      spacing: Style.space(12)

      Row {
        width: parent.width
        spacing: Style.space(12)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.icon
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
        }

        Column {
          width: parent.width - Style.space(58)
          spacing: Style.space(2)
          Text {
            text: root.temperatureLabel
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            text: root.automatic
              ? "AUTOMATIC · " + root.activePreset.toUpperCase()
              : "MANUAL · NEUTRAL"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1
          }
        }
      }

      PanelSeparator { foreground: root.foreground }

      Row {
        width: parent.width
        spacing: Style.space(6)
        Button {
          width: (parent.width - parent.spacing) / 2
          text: "Automatic"
          selected: root.automatic
          enabled: !root.busy && root.running
          onClicked: root.runAction(["mode", "auto"])
        }
        Button {
          width: (parent.width - parent.spacing) / 2
          text: "Neutral"
          selected: !root.automatic
          enabled: !root.busy && root.running
          onClicked: root.runAction(["mode", "neutral"])
        }
      }

      Text {
        width: parent.width
        text: root.automatic
          ? "Schedule now selects " + root.scheduledPreset + ". Right-click the bar icon for a quick override."
          : "Neutral override is held until Automatic is selected."
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      PanelSectionHeader {
        text: "TEMPERATURE PRESETS"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Repeater {
        model: [
          { key: "daylight", label: "Daylight", value: root.daylightTemp },
          { key: "evening", label: "Evening", value: root.eveningTemp },
          { key: "bedtime", label: "Bedtime", value: root.bedtimeTemp },
          { key: "neutral", label: "Neutral", value: root.neutralTemp }
        ]

        Row {
          required property var modelData
          width: parent.width
          spacing: Style.space(5)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - downButton.width - upButton.width - parent.spacing * 2
            text: modelData.label + "  ·  " + modelData.value + " K"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
          Button {
            id: downButton
            text: "−250"
            enabled: !root.busy && modelData.value > 1000
            onClicked: root.adjust(modelData.key, modelData.value, -250)
          }
          Button {
            id: upButton
            text: "+250"
            enabled: !root.busy && modelData.value < 10000
            onClicked: root.adjust(modelData.key, modelData.value, 250)
          }
        }
      }

      Text {
        width: parent.width
        visible: root.errorText !== ""
        text: root.errorText
        color: Color.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }
}
