// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

ColumnLayout {
    id: root
    required property var host
    Layout.fillWidth: true
    Layout.columnSpan: 2
    spacing: Style.space(4)

    Item {
        Layout.fillWidth: true
        implicitHeight: profileHeader.implicitHeight
        PanelSectionHeader {
            id: profileHeader
            text: "PROFILE"
            foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
            fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: Style.space(4)

        Button {
            text: "Balanced"
            active: root.host.profile === "Balanced"
            accent: Color.accent
            fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            Layout.fillWidth: true
            enabled: root.host.canMutate
            onClicked: root.host.exec(["set-profile", "balanced"], "profile")
        }
        Button {
            text: "Gaming"
            active: root.host.profile === "Gaming"
            accent: Color.accent
            fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            Layout.fillWidth: true
            enabled: root.host.canMutate
            onClicked: root.host.exec(["set-profile", "gaming"], "profile")
        }
        Button {
            text: "Creator"
            active: root.host.profile === "Creator"
            accent: Color.accent
            fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            Layout.fillWidth: true
            enabled: root.host.canMutate
            onClicked: root.host.exec(["set-profile", "creator"], "profile")
        }
        Button {
            text: "Custom"
            active: root.host.profile === "Custom"
            accent: Color.accent
            fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            Layout.fillWidth: true
            enabled: root.host.canMutate
            onClicked: root.host.exec(["set-profile", "custom", "2", "2"], "profile")
        }
    }
}
