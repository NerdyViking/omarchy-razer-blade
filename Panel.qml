// SPDX-License-Identifier: GPL-2.0-or-later
// Razer Blade dropdown. Native Omarchy language. SETUP when razer-ctl
// is missing; otherwise live hostWidget.state.
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "nerdyviking.razer-blade"

    property var hostWidget: null
    readonly property bool setup: hostWidget && hostWidget.setup === true
    readonly property bool manual: hostWidget ? hostWidget.manual : false
    readonly property bool daemonUp: hostWidget ? hostWidget.daemonUp : false
    readonly property double cpuTemp: hostWidget ? hostWidget.cpuTemp : 0
    readonly property double gpuTemp: hostWidget ? hostWidget.gpuTemp : 0
    readonly property double gpuUtil: hostWidget ? hostWidget.gpuUtil : 0
    readonly property double gpuPower: hostWidget ? hostWidget.gpuPower : 0
    readonly property double batteryPct: hostWidget ? hostWidget.batteryPct : 0
    readonly property bool acOnline: hostWidget ? hostWidget.acOnline : false
    readonly property string fanMode: hostWidget ? hostWidget.fanMode : "auto"
    readonly property int fanRpm: hostWidget ? hostWidget.fanRpm : 0
    readonly property int fanTach: hostWidget ? hostWidget.fanTach : 0
    readonly property string profile: hostWidget ? hostWidget.profile : "?"
    readonly property var st: hostWidget && hostWidget.state ? hostWidget.state : ({})
    readonly property int cpuBoost: st.cpu_boost || 0
    readonly property int gpuBoost: st.gpu_boost || 0
    readonly property bool bhoOn: st.bho_on || false
    readonly property int bhoThreshold: st.bho_threshold || 80
    readonly property int clampMin: st.clamp_min || 3500
    readonly property int clampMax: st.clamp_max || 5000
    readonly property int fanMid: Math.round((clampMin + clampMax) / 200) * 100
    readonly property int watchdogLeft: hostWidget && hostWidget.watchdogLeft >= 0
        ? hostWidget.watchdogLeft : -1
    readonly property bool busy: hostWidget ? hostWidget.pending === true : false
    readonly property bool commandRunning: hostWidget ? hostWidget.commandRunning === true : false
    readonly property bool canMutate: !root.busy && !root.commandRunning
    readonly property string pendingError: hostWidget ? hostWidget.pendingError : ""
    readonly property string pendingKind: hostWidget ? hostWidget.pendingKind : ""
    property bool bhoHold: false
    property bool bhoHoldOn: false
    readonly property int fanSel: {
        if (hostWidget && hostWidget.fanHoldRpm >= 0)
            return hostWidget.fanHoldRpm
        if (root.busy && root.pendingKind === "fan")
            return -1
        return root.manual ? root.fanRpm : -1
    }

    function exec(args, kind) {
        if (!(hostWidget && typeof hostWidget.execute === "function"))
            return false
        var ok = hostWidget.execute(args, kind)
        if (!ok && !hostWidget.pendingError)
            hostWidget.pendingError = "Busy — try again"
        return ok
    }

    function setFan(rpm) {
        if (hostWidget)
            hostWidget.fanHoldRpm = rpm
        root.exec(["set-fan-rpm", String(rpm)], "fan")
    }

    function setAuto() {
        if (!root.exec(["set-fan-auto"], "fan"))
            return
        if (hostWidget)
            hostWidget.fanHoldRpm = -1
    }

    function reload() {
        if (hostWidget && "reload" in hostWidget)
            hostWidget.reload()
    }

    function tempColor(t) {
        if (t >= 85)
            return Color.urgent
        if (t >= 75)
            return Color.accent
        return root.bar ? Qt.darker(root.bar.foreground, 1.2) : Color.foreground
    }

    function boostName(level) {
        return ["Low", "Normal", "High", "Boost"][level] || "?"
    }

    function statusLabel() {
        if (root.setup)
            return "SETUP"
        if (root.busy)
            return "WORKING"
        if (root.manual) {
            var s = "MANUAL " + root.fanRpm + " rpm"
            if (root.watchdogLeft >= 0)
                s += " · " + root.watchdogLeft + "s"
            return s
        }
        return root.daemonUp ? "AUTO" : "DAEMON DOWN"
    }

    function statusColor() {
        if (root.setup)
            return Color.accent
        if (root.manual || !root.daemonUp)
            return Color.urgent
        return root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
    }

    onBusyChanged: {
        if (!root.busy)
            root.bhoHold = false
    }

    onOpenedChanged: {
        if (root.opened)
            root.reload()
    }

    KeyboardPanel {
        id: popup
        anchorItem: root.anchorItem ?? root
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        contentWidth: popup.fittedContentWidth(
            Math.max(Style.space(520), panelColumn.implicitWidth),
            Style.space(800))
        contentHeight: popup.fittedContentHeight(panelFocus.implicitHeight, Style.space(560))

        Item {
            id: panelFocus
            anchors.fill: parent
            focus: true
            implicitWidth: panelColumn.implicitWidth
            implicitHeight: panelColumn.implicitHeight

            ColumnLayout {
                id: panelColumn
                anchors.fill: parent
                spacing: Style.space(4)

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(titleText.implicitHeight, statusText.implicitHeight)
                    Text {
                        id: titleText
                        text: "RAZER BLADE"
                        color: root.bar ? root.bar.foreground : Color.foreground
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 1.2
                        anchors.left: parent.left
                        anchors.leftMargin: Style.space(2)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: statusText
                        text: root.statusLabel()
                        color: root.statusColor()
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        anchors.right: parent.right
                        anchors.rightMargin: Style.space(2)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                PanelSeparator {
                    Layout.fillWidth: true
                    foreground: root.bar ? root.bar.foreground : Color.foreground
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: hintText.implicitHeight
                    visible: !root.setup && !root.daemonUp
                    Text {
                        id: hintText
                        text: "daemon not running — sudo systemctl enable --now razer-blade-daemon"
                        color: Color.urgent
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.caption
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: pendingErrorText.implicitHeight
                    visible: root.pendingError !== ""
                    Text {
                        id: pendingErrorText
                        text: root.pendingError
                        color: Color.urgent
                        font.family: root.bar ? root.bar.fontFamily : Style.font.family
                        font.pixelSize: Style.font.caption
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }
                SetupGuide {
                    host: root
                }
                GridLayout {
                    visible: !root.setup
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Style.space(12)
                    rowSpacing: Style.space(4)
                    TempsBoost { host: root }
                    FanCharge { host: root }
                    ProfileButtons { host: root }
                }
            }
        }
    }
}
