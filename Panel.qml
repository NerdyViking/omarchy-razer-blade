// SPDX-License-Identifier: GPL-2.0-or-later
// Razer Blade dropdown panel. Native Omarchy design language (mirrors the
// audio/network panels): PanelSectionHeader rows, MIN/BALANCED/MAX fan
// buttons, ToggleSwitch for charge limit, Button actions.
// First-run gate: with the backend not installed (no razer-ctl on PATH)
// the panel shows a SETUP guide instead of the controls.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "nerdyviking.razer-blade"

    property var hostWidget: null
    readonly property bool setup: hostWidget && hostWidget.setup === true

    readonly property bool manual: hostWidget
        ? hostWidget.manual : false
    readonly property bool daemonUp: hostWidget
        ? hostWidget.daemonUp : false
    readonly property double cpuTemp: hostWidget
        ? hostWidget.cpuTemp : 0
    readonly property double gpuTemp: hostWidget
        ? hostWidget.gpuTemp : 0
    readonly property double gpuUtil: hostWidget
        ? hostWidget.gpuUtil : 0
    readonly property double gpuPower: hostWidget
        ? hostWidget.gpuPower : 0
    readonly property double batteryPct: hostWidget
        ? hostWidget.batteryPct : 0
    readonly property bool acOnline: hostWidget
        ? hostWidget.acOnline : false
    readonly property string fanMode: hostWidget
        ? hostWidget.fanMode : "auto"
    readonly property int fanRpm: hostWidget
        ? hostWidget.fanRpm : 0
    readonly property int fanTach: hostWidget
        ? hostWidget.fanTach : 0
    readonly property string profile: hostWidget
        ? hostWidget.profile : "?"
    readonly property int cpuBoost: state ? (state.cpu_boost || 0) : 0
    readonly property int gpuBoost: state ? (state.gpu_boost || 0) : 0
    readonly property bool bhoOn: state ? (state.bho_on || false) : false
    readonly property int bhoThreshold: state ? (state.bho_threshold || 80) : 80
    readonly property int clampMin: state ? (state.clamp_min || 3500) : 3500
    readonly property int clampMax: state ? (state.clamp_max || 5000) : 5000
    readonly property int fanMid: Math.round((clampMin + clampMax) / 200) * 100

    property var state: ({})

    readonly property bool busy: hostWidget ? hostWidget.pending === true : false
    readonly property string pendingError: hostWidget ? hostWidget.pendingError : ""
    readonly property string pendingKind: hostWidget ? hostWidget.pendingKind : ""
    property double fanCommit: 0

    readonly property int fanSel: (root.busy && root.pendingKind === "fan")
        ? Math.round(root.fanCommit)
        : (root.manual ? root.fanRpm : -1)

    function exec(args, expected, kind) {
        if (hostWidget && typeof hostWidget.execute === "function")
            return hostWidget.execute(args, expected, kind)
        return false
    }

    function setFan(rpm) {
        root.fanCommit = rpm
        root.exec(["set-fan-rpm", String(rpm)],
            {fan_mode: "manual", fan_rpm: rpm}, "fan")
    }

    function reload() {
        if (hostWidget && "reload" in hostWidget)
            hostWidget.reload()
    }

    function run(args) {
        Quickshell.execDetached(
            ["razer-ctl"].concat(args), null, null, 1)
        root.reload()
    }

    function tempColor(t) {
        if (t >= 85)
            return Color.urgent
        if (t >= 75)
            return Color.accent
        return root.bar ? Qt.darker(root.bar.foreground, 1.2) : Color.foreground
    }

    // ---- state sync ----
    function adoptState() {
        if (hostWidget)
            root.state = hostWidget.state || {}
    }
    onHostWidgetChanged: adoptState()
    Timer {
        interval: 2500
        running: root.opened
        repeat: true
        triggeredOnStart: true
        onTriggered: root.adoptState()
    }

    onOpenedChanged: {
        if (root.opened) {
            root.adoptState()
            root.reload()
        }
    }

    // ---- row helpers (native anatomy) ----
    component SectionRow: Item {
        property string label: ""
        property string value: ""
        property color valueColor: root.bar
            ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
        property bool valueBold: false
        Layout.fillWidth: true
        implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

        Text {
            id: labelText
            text: parent.label
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            anchors.left: parent.left
            anchors.leftMargin: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: valueText
            text: parent.value
            color: parent.valueColor
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: parent.valueBold
            anchors.right: parent.right
            anchors.rightMargin: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    KeyboardPanel {
        id: popup
        anchorItem: root.anchorItem ?? root
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        contentWidth: popup.fittedContentWidth(Style.space(440))
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

                // ---- header ----
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
                        text: root.setup
                            ? "SETUP"
                            : (root.busy
                               ? "WORKING"
                               : (root.manual
                                  ? "MANUAL " + root.fanRpm + " rpm"
                                  : (root.daemonUp ? "AUTO" : "DAEMON DOWN")))
                        color: root.setup
                            ? Color.accent
                            : (root.manual
                               ? Color.urgent
                               : (root.daemonUp
                                  ? (root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground)
                                  : Color.urgent))
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

                // ---- daemon-down hint (installed but stopped) ----
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

                // ---- command error (execution not confirmed) ----
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

                // ================= SETUP guide (first run) =================
                Item {
                    Layout.fillWidth: true
                    implicitHeight: setupText.implicitHeight
                    visible: root.setup

                    Column {
                        id: setupText
                        width: parent.width
                        spacing: Style.space(8)

                        Text {
                            text: "This widget controls the Razer Blade EC: fans, power profiles, CPU/GPU boost and the battery charge limit, with live temps."
                            color: root.bar ? root.bar.foreground : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.body
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            text: "Why a daemon: the EC is owned by a userspace driver (razer-control-revived). This widget relays every command through razer-blade-daemon (root), which clamps fan RPM, verifies writes by readback and reverts to auto on a watchdog — the widget alone cannot touch the EC."
                            color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.body
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            text: "Install:"
                            color: root.bar ? root.bar.foreground : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.body
                            font.bold: true
                        }
                        Text {
                            text: "1. razer-control-revived from its releases — your USB PID (lsusb: 1532:xxxx) must be listed\n2. git clone https://github.com/NerdyViking/razer-blade.git && cd razer-blade\n3. cargo build --release\n4. sudo ./scripts/install.sh\n5. sudo systemctl enable --now razer-blade-daemon"
                            color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.caption
                            width: parent.width
                            wrapMode: Text.WordWrap
                            lineHeight: 1.6
                        }
                        Text {
                            text: "Live temps need the NVIDIA driver (NVML). After installing, press CHECK AGAIN — the panel switches to the controls automatically."
                            color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.caption
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "CHECK AGAIN"
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            fontSize: Style.font.caption
                            verticalPadding: Style.space(2)
                            onClicked: root.reload()
                        }
                    }
                }

                // ================= MAIN GRID (2 columns x 2 rows) =================
                GridLayout {
                    visible: !root.setup
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Style.space(12)
                    rowSpacing: Style.space(4)

                    // ---------- LEFT: TEMPS + BOOST ----------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(4)

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: tempsHeader.implicitHeight

                            PanelSectionHeader {
                                id: tempsHeader
                                text: "TEMPS"
                                foreground: root.bar ? root.bar.foreground : Color.foreground
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            }
                        }
                        SectionRow {
                            label: "CPU"
                            value: root.cpuTemp > 0 ? Math.round(root.cpuTemp) + "°C" : "--"
                            valueColor: root.cpuTemp > 0 ? root.tempColor(root.cpuTemp)
                                : (root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground)
                        }
                        SectionRow {
                            label: "GPU"
                            value: root.gpuTemp > 0 ? Math.round(root.gpuTemp) + "°C" : "--"
                            valueColor: root.gpuTemp > 0 ? root.tempColor(root.gpuTemp)
                                : (root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground)
                        }
                        SectionRow {
                            label: "GPU util / power"
                            value: (root.gpuUtil >= 0 ? Math.round(root.gpuUtil) + "%" : "--")
                                + " / " + (root.gpuPower > 0 ? root.gpuPower.toFixed(1) + " W" : "--")
                        }
                        SectionRow {
                            label: "Battery"
                            value: (root.batteryPct > 0 ? Math.round(root.batteryPct) + "%" : "--")
                                + " · " + (root.acOnline ? "AC" : "BAT")
                        }

                        PanelSeparator {
                            Layout.fillWidth: true
                            foreground: root.bar ? root.bar.foreground : Color.foreground
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: boostHeader.implicitHeight

                            PanelSectionHeader {
                                id: boostHeader
                                text: "BOOST"
                                foreground: root.bar ? root.bar.foreground : Color.foreground
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            }
                        }
                        Row {
                            visible: root.profile === "Custom"
                            spacing: Style.space(4)

                            Button {
                                text: "CPU " + root.boostName(root.cpuBoost)
                                accent: Color.accent
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                                fontSize: Style.font.caption
                                verticalPadding: Style.space(2)
                                enabled: !root.busy
                                onClicked: root.exec([
                                    "set-boost",
                                    String((root.cpuBoost + 1) % 4),
                                    String(root.gpuBoost),
                                ], {cpu_boost: (root.cpuBoost + 1) % 4, gpu_boost: root.gpuBoost}, "boost")
                            }
                            Button {
                                text: "GPU " + root.boostName(root.gpuBoost)
                                accent: Color.accent
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                                fontSize: Style.font.caption
                                verticalPadding: Style.space(2)
                                enabled: !root.busy
                                onClicked: root.exec([
                                    "set-boost",
                                    String(root.cpuBoost),
                                    String((root.gpuBoost + 1) % 4),
                                ], {cpu_boost: root.cpuBoost, gpu_boost: (root.gpuBoost + 1) % 4}, "boost")
                            }
                        }
                        Text {
                            visible: root.profile !== "Custom"
                            text: "custom profile only"
                            color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.body
                            wrapMode: Text.WordWrap
                        }
                    }

                    // ---------- RIGHT: FAN + CHARGE ----------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(4)

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: fanHeader.implicitHeight

                            PanelSectionHeader {
                                id: fanHeader
                                text: "FAN"
                                foreground: root.bar ? root.bar.foreground : Color.foreground
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            }
                            Text {
                                text: root.manual
                                    ? (root.fanTach > 0 ? "Fan Speed: " + root.fanTach + " RPM" : "Fan Speed: --")
                                    : "Fan Speed: EC curve"
                                color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
                                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                                font.pixelSize: Style.font.caption
                                anchors.right: parent.right
                                anchors.rightMargin: Style.space(2)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "SET TO AUTO"
                            active: root.manual
                            accent: root.manual ? Color.urgent : Color.accent
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            fontSize: Style.font.caption
                            verticalPadding: Style.space(2)
                            enabled: root.manual && !root.busy
                            opacity: root.manual ? 1.0 : 0.5
                            onClicked: root.exec(["set-fan-auto"], {fan_mode: "auto"}, "fan")
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(4)

                            Button {
                                Layout.fillWidth: true
                                text: "MIN"
                                active: Math.abs(root.fanSel - root.clampMin) <= 100
                                accent: Color.accent
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                                fontSize: Style.font.caption
                                verticalPadding: Style.space(2)
                                enabled: !root.busy
                                onClicked: root.setFan(root.clampMin)
                            }
                            Button {
                                Layout.fillWidth: true
                                text: "BALANCED"
                                active: Math.abs(root.fanSel - root.fanMid) <= 100
                                accent: Color.accent
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                                fontSize: Style.font.caption
                                verticalPadding: Style.space(2)
                                enabled: !root.busy
                                onClicked: root.setFan(root.fanMid)
                            }
                            Button {
                                Layout.fillWidth: true
                                text: "MAX"
                                active: Math.abs(root.fanSel - root.clampMax) <= 100
                                accent: Color.accent
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                                fontSize: Style.font.caption
                                verticalPadding: Style.space(2)
                                enabled: !root.busy
                                onClicked: root.setFan(root.clampMax)
                            }
                        }

                        PanelSeparator {
                            Layout.fillWidth: true
                            foreground: root.bar ? root.bar.foreground : Color.foreground
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(chargeHeader.implicitHeight, chargeSwitch.implicitHeight)

                            PanelSectionHeader {
                                id: chargeHeader
                                text: "CHARGE LIMIT"
                                foreground: root.bar ? root.bar.foreground : Color.foreground
                                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                                anchors.left: parent.left
                            }
                            ToggleSwitch {
                                id: chargeSwitch
                                checked: root.bhoOn
                                interactive: !root.setup && !root.busy
                                accent: Color.accent
                                anchors.right: parent.right
                                anchors.rightMargin: Style.space(2)
                                anchors.verticalCenter: parent.verticalCenter
                                onToggled: root.bhoOn
                                    ? root.exec(["set-bho", "off"], {bho_on: false}, "bho")
                                    : root.exec(["set-bho", "on", String(root.bhoThreshold)],
                                        {bho_on: true, bho_threshold: root.bhoThreshold}, "bho")
                            }
                        }
                        SectionRow {
                            label: "Threshold"
                            value: root.bhoOn ? root.bhoThreshold + "%" : "off"
                            valueColor: root.bhoOn
                                ? (root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground)
                                : (root.bar ? Qt.darker(root.bar.foreground, 1.8) : Color.foreground)
                        }
                        Button {
                            visible: root.bhoOn
                            Layout.fillWidth: true
                            text: "CYCLE " + String((root.bhoThreshold >= 80 ? 50 : root.bhoThreshold + 5)) + "%"
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            fontSize: Style.font.caption
                            verticalPadding: Style.space(2)
                            enabled: !root.busy
                            onClicked: root.exec([
                                "set-bho", "on",
                                String(root.bhoThreshold >= 80 ? 50 : root.bhoThreshold + 5),
                            ], {
                                bho_on: true,
                                bho_threshold: root.bhoThreshold >= 80 ? 50 : root.bhoThreshold + 5,
                            }, "bho")
                        }
                    }

                    // ---------- BOTTOM ROW: PROFILE (spans both columns) ----------
                    Item {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        implicitHeight: profileHeader.implicitHeight

                        PanelSectionHeader {
                            id: profileHeader
                            text: "PROFILE"
                            foreground: root.bar ? root.bar.foreground : Color.foreground
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                        }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        columns: 4
                        columnSpacing: Style.space(4)

                        Button {
                            text: "Balanced"
                            active: root.profile === "Balanced"
                            accent: Color.accent
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            fontSize: Style.font.caption
                            verticalPadding: Style.space(2)
                            Layout.fillWidth: true
                            enabled: !root.busy
                            onClicked: root.exec(["set-profile", "balanced"],
                                {profile: "Balanced"}, "profile")
                        }
                        Button {
                            text: "Gaming"
                            active: root.profile === "Gaming"
                            accent: Color.accent
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            fontSize: Style.font.caption
                            verticalPadding: Style.space(2)
                            Layout.fillWidth: true
                            enabled: !root.busy
                            onClicked: root.exec(["set-profile", "gaming"],
                                {profile: "Gaming"}, "profile")
                        }
                        Button {
                            text: "Creator"
                            active: root.profile === "Creator"
                            accent: Color.accent
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            fontSize: Style.font.caption
                            verticalPadding: Style.space(2)
                            Layout.fillWidth: true
                            enabled: !root.busy
                            onClicked: root.exec(["set-profile", "creator"],
                                {profile: "Creator"}, "profile")
                        }
                        Button {
                            text: "Custom"
                            active: root.profile === "Custom"
                            accent: Color.accent
                            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                            fontSize: Style.font.caption
                            verticalPadding: Style.space(2)
                            Layout.fillWidth: true
                            enabled: !root.busy
                            onClicked: root.exec(["set-profile", "custom", "2", "2"],
                                {profile: "Custom"}, "profile")
                        }
                    }
                }
            }
        }
    }

    function boostName(level) {
        return ["Low", "Normal", "High", "Boost"][level] || "?"
    }
}