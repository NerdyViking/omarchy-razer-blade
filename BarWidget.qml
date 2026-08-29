// SPDX-License-Identifier: GPL-2.0-or-later
// Razer Blade bar widget: GPU temp with fan-mode indicator.
// Data comes from `razer-ctl --json` (needs razer-blade-daemon running
// and razer-ctl on PATH). First run without the backend shows SETUP.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "nerdyviking.razer-blade"

    property var state: ({})
    property bool daemonUp: false
    property bool backendSeen: false
    property bool razerCtlPresent: false
    readonly property bool opened: panelLoader.item
        ? panelLoader.item.opened === true : false

    readonly property string fanMode: state.fan_mode || "auto"
    readonly property bool manual: fanMode === "manual"
    readonly property int fanRpm: state.fan_rpm || 0
    readonly property int fanTach: state.fan_actual || 0
    readonly property double gpuTemp: state.gpu_temp || 0
    readonly property double cpuTemp: state.cpu_temp || 0
    readonly property string profile: state.profile || "?"
    readonly property double gpuUtil: typeof state.gpu_util === "number" ? state.gpu_util : -1
    readonly property double gpuPower: state.gpu_power || 0
    readonly property double batteryPct: state.battery_pct || 0
    readonly property bool acOnline: state.ac_online || false
    readonly property int watchdogLeft: typeof state.watchdog_remaining_s === "number"
        ? state.watchdog_remaining_s : -1
    readonly property int watchdogTimeout: state.watchdog_timeout_s || 30
    readonly property bool setup: !root.razerCtlPresent && !root.backendSeen

    property bool pending: false
    property string pendingError: ""
    property string pendingKind: ""
    property bool _quiet: false
    readonly property bool commandRunning: cmdProc.running
    // -1 = auto intent; otherwise last MIN/BALANCED/MAX rpm to heartbeat.
    property int fanHoldRpm: -1

    function reload() {
        if (root.setup) {
            if (!probeProc.running)
                probeProc.running = true
        } else if (!stateProc.running) {
            stateProc.running = true
        }
    }

    function execute(args, kind, quiet) {
        if (cmdProc.running)
            return false
        root._quiet = quiet === true
        if (!root._quiet) {
            if (root.pending)
                return false
            root.pending = true
            root.pendingError = ""
            root.pendingKind = kind || "other"
            pendingTimeout.restart()
        }
        cmdProc.command = ["razer-ctl", "--json"].concat(args)
        cmdProc.running = true
        return true
    }

    function _adoptState(st) {
        root.state = st
        root.daemonUp = true
        root.backendSeen = true
        if (root.fanHoldRpm >= 0 && !root.pending && (st.fan_mode || "auto") !== "manual") {
            root.fanHoldRpm = -1
            root.pendingError = "Fan reverted to auto (watchdog or EC)"
            pendingErrorTimer.restart()
        }
    }

    function tooltipBody() {
        if (root.setup)
            return "Razer Blade: backend not installed — open the panel for setup"
        if (!root.daemonUp)
            return "RAZER BLADE · daemon down"
        var temps = "CPU " + Math.round(root.cpuTemp) + "° · GPU "
            + Math.round(root.gpuTemp) + "° · " + root.profile.toUpperCase()
        if (!root.manual)
            return "FAN AUTO · " + temps
        var lease = root.watchdogLeft >= 0 ? " · " + root.watchdogLeft + "s" : ""
        return "FAN MANUAL " + root.fanRpm + " rpm" + lease
            + " · tach " + root.fanTach + "\n" + temps
    }

    function _finishCommand(ok, payload, errText) {
        if (!root._quiet) {
            root.pending = false
            root.pendingKind = ""
            pendingTimeout.stop()
        }
        if (ok && payload && typeof payload === "object") {
            root._adoptState(payload)
            return
        }
        root.pendingError = errText || (root._quiet ? "Fan hold heartbeat failed" : "Command failed")
        pendingErrorTimer.restart()
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function toggle() {
        if (root.opened)
            root.closePanel()
        else
            root.openPanel()
    }

    function open() {
        root.openPanel()
    }

    function close() {
        root.closePanel()
    }

    function openPanel() {
        if (panelLoader.item)
            panelLoader.item.open()
    }

    function closePanel() {
        if (panelLoader.item)
            panelLoader.item.close()
    }

    function injectPanel() {
        var target = panelLoader.item
        if (!target)
            return
        if ("bar" in target)
            target.bar = root.bar
        if ("settings" in target)
            target.settings = root.settings
        if ("anchorItem" in target)
            target.anchorItem = button
        if ("hostWidget" in target)
            target.hostWidget = root
    }

    onBarChanged: injectPanel()
    onSettingsChanged: injectPanel()

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.reload()
    }

    Timer {
        id: heartbeat
        interval: {
            var w = root.watchdogTimeout
            if (!(w > 0))
                w = 30
            return Math.max(5000, Math.min(15000, (w / 2) * 1000))
        }
        running: root.fanHoldRpm >= 0 && root.daemonUp && !root.pending
        repeat: true
        onTriggered: root.execute(
            ["set-fan-rpm", String(root.fanHoldRpm)], "fan", true)
    }

    Timer {
        id: pendingTimeout
        interval: 5000
        onTriggered: {
            if (!root.pending)
                return
            root.pending = false
            root.pendingKind = ""
            root.pendingError = "Command not confirmed — reverted to the actual state"
            pendingErrorTimer.restart()
        }
    }

    Timer {
        id: pendingErrorTimer
        interval: 6000
        onTriggered: root.pendingError = ""
    }

    Process {
        id: probeProc
        command: ["/bin/sh", "-c", "command -v razer-ctl >/dev/null 2>&1"]
        onExited: function (exitCode) {
            root.razerCtlPresent = exitCode === 0
            if (exitCode === 0 && !stateProc.running)
                stateProc.running = true
        }
    }
    Component.onCompleted: probeProc.running = true

    Process {
        id: stateProc
        command: ["razer-ctl", "get-state", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(text)
                    var st = parsed && parsed.state ? parsed.state : null
                    if (parsed && parsed.ok && st && typeof st === "object")
                        root._adoptState(st)
                    else
                        root.daemonUp = false
                } catch (e) {
                    root.daemonUp = false
                }
            }
        }
        onExited: function (exitCode) {
            if (exitCode !== 0)
                root.daemonUp = false
        }
    }

    Process {
        id: cmdProc
        command: ["razer-ctl", "--json", "ping"]
        stdout: StdioCollector {
            id: cmdOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: cmdErr
            waitForEnd: true
        }
        onExited: function (exitCode) {
            var payload = null
            var errText = ""
            try {
                var parsed = JSON.parse(cmdOut.text)
                if (parsed && parsed.state && typeof parsed.state === "object")
                    payload = parsed.state
                if (parsed && parsed.error)
                    errText = parsed.error
            } catch (e) {
                errText = cmdErr.text || "invalid response"
            }
            root._finishCommand(exitCode === 0 && !!payload, payload, errText)
        }
    }

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            Qt.callLater(root.injectPanel)
        }
    }

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.setup
            ? "SETUP"
            : (root.gpuTemp > 0 ? Math.round(root.gpuTemp) + "°" : "--°")
              + (root.manual ? "+" : "")
        active: root.setup
        useActiveColor: true
        tooltipText: root.tooltipBody()
        onPressed: function (buttonCode) {
            if (buttonCode === Qt.LeftButton || buttonCode === Qt.RightButton)
                root.toggle()
        }
    }
}
