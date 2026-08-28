// SPDX-License-Identifier: GPL-2.0-or-later
// Razer Blade bar widget: GPU temp with fan-mode indicator dot.
// Data comes from `razer-ctl get-state --json` (needs razer-blade-daemon
// running and razer-ctl on PATH). First run without the backend shows a
// setup state ("SETUP") and the panel turns into a HOWTO.
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
    // True once a get-state succeeded (daemon + razer-ctl both present).
    property bool backendSeen: false
    // True when the razer-ctl binary exists on PATH (one-shot probe).
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
    readonly property bool setup: !root.razerCtlPresent

    function reload() {
        stateProc.running = true
    }

    // ---- pending-execution state ----
    // set by the panel for any control write; cleared when a state poll
    // confirms the change or after a 5s timeout (then shown as an error).
    property bool pending: false
    property string pendingError: ""
    property string pendingKind: ""
    property var _pendingExpected: ({})
    property int _pendingAt: 0

    function execute(args, expected, kind) {
        if (root.pending)
            return false
        root.pending = true
        root.pendingError = ""
        root.pendingKind = kind || "other"
        root._pendingExpected = expected || {}
        root._pendingAt = new Date().getTime()
        Quickshell.execDetached(["razer-ctl"].concat(args), null, null, 1)
        root.reload()
        return true
    }

    function _checkPending() {
        if (!root.pending)
            return
        var st = root.state || {}
        var e = root._pendingExpected
        var ok = true
        for (var k in e) {
            if (String(st[k]) !== String(e[k])) {
                ok = false
                break
            }
        }
        if (ok) {
            root.pending = false
            root.pendingKind = ""
        } else if (new Date().getTime() - root._pendingAt > 5000) {
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

    // One-shot probe: does the razer-ctl binary exist? Exit-code only
    // (static shell string — no user input reaches this).
    Process {
        id: probeProc
        command: ["/bin/sh", "-c", "command -v razer-ctl >/dev/null 2>&1"]
        onExited: function (exitCode) {
            root.razerCtlPresent = exitCode === 0
            if (!stateProc.running)
                stateProc.running = true
        }
    }
    // Start at root level: all Process children must exist before the
    // probe runs (it exits before stateProc would be instantiated if
    // started from its own onCompleted).
    Component.onCompleted: probeProc.running = true

    Process {
        id: stateProc
        command: ["razer-ctl", "get-state", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(text)
                    if (parsed && typeof parsed === "object") {
                        root.state = parsed
                        root.daemonUp = true
                        root.backendSeen = true
                        root._checkPending()
                    } else {
                        root.daemonUp = false
                    }
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
        active: root.manual || root.setup
        useActiveColor: true
        tooltipText: root.setup
            ? "Razer Blade: backend not installed — open the panel for setup"
            : (root.manual
               ? "FAN MANUAL " + root.fanRpm + " rpm · tach " + root.fanTach
                 + "\nCPU " + Math.round(root.cpuTemp) + "° · GPU " + Math.round(root.gpuTemp)
                 + "° · " + root.profile.toUpperCase()
               : (root.daemonUp
                  ? "FAN AUTO · CPU " + Math.round(root.cpuTemp) + "° · GPU "
                    + Math.round(root.gpuTemp) + "° · " + root.profile.toUpperCase()
                  : "RAZER BLADE · daemon down"))
        onPressed: function (buttonCode) {
            if (buttonCode === Qt.LeftButton || buttonCode === Qt.RightButton)
                root.toggle()
        }
    }
}