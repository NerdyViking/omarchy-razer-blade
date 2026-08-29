// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
    property string label: ""
    property string value: ""
    property color valueColor: Color.foreground
    property bool valueBold: false
    property var bar: null
    Layout.fillWidth: true
    spacing: Style.space(12)

    Text {
        text: parent.label
        color: parent.bar ? parent.bar.foreground : Color.foreground
        font.family: parent.bar ? parent.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
    Text {
        text: parent.value
        color: parent.valueColor
        font.family: parent.bar ? parent.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        font.bold: parent.valueBold
        Layout.alignment: Qt.AlignRight
    }
}
