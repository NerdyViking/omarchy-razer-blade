// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Item {
    id: root
    required property var host
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight
    visible: host.setup

    Column {
        id: column
        width: parent.width
        spacing: Style.space(8)

        Text {
            text: "This widget controls the Razer Blade EC: fans, power profiles, CPU/GPU boost and the battery charge limit, with live temps."
            color: root.host.bar ? root.host.bar.foreground : Color.foreground
            font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            width: parent.width
            wrapMode: Text.WordWrap
        }
        Text {
            text: "Why a daemon: the EC is owned by a userspace driver (razer-control-revived). This widget relays every command through razer-blade-daemon (root), which clamps fan RPM, verifies writes by readback and reverts to auto on a watchdog — the widget alone cannot touch the EC."
            color: root.host.bar ? Qt.darker(root.host.bar.foreground, 1.4) : Color.foreground
            font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            width: parent.width
            wrapMode: Text.WordWrap
        }
        Text {
            text: "Install:"
            color: root.host.bar ? root.host.bar.foreground : Color.foreground
            font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
        }
        Text {
            text: "1. razer-control-revived from its releases — your USB PID (lsusb: 1532:xxxx) must be listed\n2. git clone https://github.com/NerdyViking/razer-blade.git && cd razer-blade && git checkout --detach 293e03babf7f75466a8e2f422dd05c972e34cd0c && cargo build --release\n3. sudo ./scripts/install.sh\n4. sudo systemctl enable --now razer-blade-daemon"
            color: root.host.bar ? Qt.darker(root.host.bar.foreground, 1.4) : Color.foreground
            font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            width: parent.width
            wrapMode: Text.WordWrap
            lineHeight: 1.6
        }
        Text {
            text: "Live temps need the NVIDIA driver (NVML). After installing, press CHECK AGAIN — the panel switches to the controls automatically."
            color: root.host.bar ? Qt.darker(root.host.bar.foreground, 1.4) : Color.foreground
            font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            width: parent.width
            wrapMode: Text.WordWrap
        }
        Button {
            text: "CHECK AGAIN"
            fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            fontSize: Style.font.caption
            verticalPadding: Style.space(2)
            onClicked: root.host.reload()
        }
    }
}
