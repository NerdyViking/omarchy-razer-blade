// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

ColumnLayout {
    id: root
    required property var host
    Layout.fillWidth: true
    spacing: Style.space(4)

    readonly property var bar: host.bar
    readonly property color muted: bar ? Qt.darker(bar.foreground, 1.4) : Color.foreground

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
        bar: root.bar
        label: "CPU"
        value: root.host.cpuTemp > 0 ? Math.round(root.host.cpuTemp) + "°C" : "--"
        valueColor: root.host.cpuTemp > 0 ? root.host.tempColor(root.host.cpuTemp) : root.muted
    }
    SectionRow {
        bar: root.bar
        label: "GPU"
        value: root.host.gpuTemp > 0 ? Math.round(root.host.gpuTemp) + "°C" : "--"
        valueColor: root.host.gpuTemp > 0 ? root.host.tempColor(root.host.gpuTemp) : root.muted
    }
    SectionRow {
        bar: root.bar
        label: "GPU util / power"
        value: (root.host.gpuUtil >= 0 ? Math.round(root.host.gpuUtil) + "%" : "--")
            + " / " + (root.host.gpuPower > 0 ? root.host.gpuPower.toFixed(1) + " W" : "--")
    }
    SectionRow {
        bar: root.bar
        label: "Battery"
        value: (root.host.batteryPct > 0 ? Math.round(root.host.batteryPct) + "%" : "--")
            + " · " + (root.host.acOnline ? "AC" : "BAT")
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
        visible: root.host.profile === "Custom"
        spacing: Style.space(4)
        Button {
            text: "CPU " + root.host.boostName(root.host.cpuBoost)
            accent: Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            enabled: root.host.canMutate
            onClicked: root.host.exec([
                "set-boost",
                String((root.host.cpuBoost + 1) % 4),
                String(root.host.gpuBoost),
            ], "boost")
        }
        Button {
            text: "GPU " + root.host.boostName(root.host.gpuBoost)
            accent: Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            enabled: root.host.canMutate
            onClicked: root.host.exec([
                "set-boost",
                String(root.host.cpuBoost),
                String((root.host.gpuBoost + 1) % 4),
            ], "boost")
        }
    }
    Text {
        visible: root.host.profile !== "Custom"
        text: "custom profile only"
        color: root.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
    }
}
