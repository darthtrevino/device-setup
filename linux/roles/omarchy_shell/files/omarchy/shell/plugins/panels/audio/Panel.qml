import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

// Fedora's Quickshell 0.2 PipeWire object model can segfault while a live
// device graph is mounted in a popup. Keep this panel command-backed until the
// distro package catches up; the bar remains stable when sinks appear or leave.
Panel {
  id: root

  moduleName: "omarchy.audio"
  ipcTarget: "omarchy.audio"

  property int volumePercent: 0
  property bool outputMuted: false
  property string sinkName: ""
  property int pendingVolumePercent: -1
  property real wheelAccumulator: 0

  readonly property string sinkLabel: {
    if (sinkName === "audio_effect.j416-convolver") return "MacBook Pro Speakers"
    if (!sinkName) return "Default output"
    var label = sinkName
      .replace(/^raop_sink\./, "")
      .replace(/^alsa_output\./, "")
      .replace(/_/g, " ")
    return label.length > 42 ? label.slice(0, 39) + "..." : label
  }

  function outputIcon() {
    if (outputMuted || volumePercent === 0) return ""
    if (volumePercent >= 67) return ""
    if (volumePercent >= 34) return ""
    return ""
  }

  function refreshStatus() {
    if (!statusProcess.running) statusProcess.running = true
  }

  function applyStatus(raw) {
    var fields = String(raw || "").trim().split("\t")
    if (fields.length < 3) return
    var nextVolume = Number(fields[0])
    if (!isNaN(nextVolume)) volumePercent = Math.max(0, Math.min(100, nextVolume))
    outputMuted = fields[1] === "yes"
    sinkName = fields.slice(2).join("\t")
  }

  function queueVolume(percent) {
    pendingVolumePercent = Math.max(0, Math.min(100, Math.round(percent)))
    volumePercent = pendingVolumePercent
    volumeApplyTimer.restart()
  }

  function toggleMute() {
    if (muteProcess.running) return
    muteProcess.command = [
      "pactl",
      "set-sink-mute",
      sinkName || "@DEFAULT_SINK@",
      "toggle"
    ]
    outputMuted = !outputMuted
    muteProcess.running = true
  }

  onOpenedChanged: if (opened) refreshStatus()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: statusProcess
    command: ["omarchy-audio-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
  }

  Process {
    id: volumeProcess
    onExited: root.refreshStatus()
  }

  Process {
    id: muteProcess
    onExited: root.refreshStatus()
  }

  Timer {
    interval: root.opened ? 1000 : 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshStatus()
  }

  Timer {
    id: volumeApplyTimer
    interval: 75
    repeat: false

    onTriggered: {
      if (volumeProcess.running) {
        restart()
        return
      }
      if (root.pendingVolumePercent < 0) return

      var percent = root.pendingVolumePercent
      root.pendingVolumePercent = -1
      volumeProcess.command = [
        "pactl",
        "set-sink-volume",
        root.sinkName || "@DEFAULT_SINK@",
        percent + "%"
      ]
      volumeProcess.running = true
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.outputIcon()
    tooltipText: root.outputMuted ? "Audio muted" : "Volume " + root.volumePercent + "%"

    onPressed: function(button) {
      if (button === Qt.RightButton) root.toggleMute()
      else root.toggle()
    }

    onWheelMoved: function(delta) {
      var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
      root.wheelAccumulator = wheel.remainder
      if (wheel.steps !== 0) root.queueVolume(root.volumePercent + wheel.steps * 5)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.queueVolume(root.volumePercent + dx * 5)
      }
      onActivateRequested: root.toggleMute()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (text === "m" || text === "M") root.toggleMute()
      }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, muteSwitch.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: root.outputIcon()
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            opacity: root.outputMuted ? 0.5 : 1
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: muteSwitch.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: "Audio"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: root.sinkLabel.toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              elide: Text.ElideRight
            }
          }

          ToggleSwitch {
            id: muteSwitch
            checked: !root.outputMuted
            foreground: root.bar.foreground
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onToggled: root.toggleMute()
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        Item {
          width: parent.width
          implicitHeight: Math.max(outputHeader.implicitHeight, outputPercent.implicitHeight)

          PanelSectionHeader {
            id: outputHeader
            text: "OUTPUT"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: outputPercent
            text: root.volumePercent + "%"
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.outputMuted ? 0.5 : 1
          }
        }

        PanelSlider {
          bar: root.bar
          width: parent.width
          minimum: 0
          maximum: 100
          step: 5
          integer: true
          value: root.volumePercent
          opacity: root.outputMuted ? 0.5 : 1
          onMoved: function(value) { root.queueVolume(value) }
          onRightClicked: root.toggleMute()
        }

        Text {
          width: parent.width
          text: "Use Shift+Volume Mute to choose another output."
          color: Qt.darker(root.bar.foreground, 1.5)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
