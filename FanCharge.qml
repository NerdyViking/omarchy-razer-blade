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
        implicitHeight: fanHeader.implicitHeight
        PanelSectionHeader {
            id: fanHeader
            text: "FAN"
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        }
        Text {
            text: root.host.manual
                ? (root.host.fanTach > 0 ? "Fan Speed: " + root.host.fanTach + " RPM" : "Fan Speed: --")
                : "Fan Speed: EC curve"
            color: root.muted
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
        active: root.host.manual
        accent: root.host.manual ? Color.urgent : Color.accent
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        fontSize: Style.font.caption
        verticalPadding: Style.space(2)
        enabled: root.host.manual && root.host.canMutate
        opacity: root.host.manual ? 1.0 : 0.5
        onClicked: root.host.setAuto()
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        Button {
            Layout.fillWidth: true
            text: "MIN"
            active: Math.abs(root.host.fanSel - root.host.clampMin) <= 100
            accent: Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            enabled: root.host.canMutate
            onClicked: root.host.setFan(root.host.clampMin)
        }
        Button {
            Layout.fillWidth: true
            text: "BALANCED"
            active: Math.abs(root.host.fanSel - root.host.fanMid) <= 100
            accent: Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            enabled: root.host.canMutate
            onClicked: root.host.setFan(root.host.fanMid)
        }
        Button {
            Layout.fillWidth: true
            text: "MAX"
            active: Math.abs(root.host.fanSel - root.host.clampMax) <= 100
            accent: Color.accent
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            enabled: root.host.canMutate
            onClicked: root.host.setFan(root.host.clampMax)
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
            checked: root.host.bhoHold ? root.host.bhoHoldOn : root.host.bhoOn
            interactive: !root.host.setup && root.host.canMutate
            accent: Color.accent
            anchors.right: parent.right
            anchors.rightMargin: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
            onToggled: {
                root.host.bhoHold = true
                root.host.bhoHoldOn = !root.host.bhoOn
                if (root.host.bhoOn)
                    root.host.exec(["set-bho", "off"], "bho")
                else
                    root.host.exec(["set-bho", "on", String(root.host.bhoThreshold)], "bho")
            }
        }
    }
    SectionRow {
        bar: root.bar
        label: "Threshold"
        value: root.host.bhoOn ? root.host.bhoThreshold + "%" : "off"
        valueColor: root.host.bhoOn
            ? root.muted
            : (root.bar ? Qt.darker(root.bar.foreground, 1.8) : Color.foreground)
    }
    Button {
        visible: root.host.bhoOn
        Layout.fillWidth: true
        text: "CYCLE " + String((root.host.bhoThreshold >= 80 ? 50 : root.host.bhoThreshold + 5)) + "%"
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        fontSize: Style.font.caption
        verticalPadding: Style.space(2)
        enabled: root.host.canMutate
        onClicked: root.host.exec([
            "set-bho", "on",
            String(root.host.bhoThreshold >= 80 ? 50 : root.host.bhoThreshold + 5),
        ], "bho")
    }
}
