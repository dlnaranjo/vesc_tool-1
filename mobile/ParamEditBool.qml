/*
    Copyright 2018 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Accessibility 1.0

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.utility 1.0

Item {
    id: editor
    property string paramName: ""
    property ConfigParams params: null
    height: 140
    Layout.fillWidth: true
    property real maxVal: 1.0
    Accessible.role: Accessible.Group
    Accessible.name: params ? params.getLongName(paramName) : qsTr("Parameter")
    Accessible.description: qsTr("Current state: %1").arg(boolSwitch.checked ? qsTr("enabled") : qsTr("disabled"))

    Component.onCompleted: {
        if (params != null) {
            nameText.text = params.getLongName(paramName)
            boolSwitch.checked = params.getParamBool(paramName)

            if (params.getParamTransmittable(paramName)) {
                nowButton.visible = true
                defaultButton.visible = true
            } else {
                nowButton.visible = false
                defaultButton.visible = false
            }
        }
    }

    Rectangle {
        id: rect
        anchors.fill: parent
        color: Utility.getAppHexColor("lightBackground")
        radius: 5
        border.color:  Utility.getAppHexColor("disabledText")
        border.width: 2

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.topMargin: 10
            anchors.margins: 5

            Text {
                id: nameText
                color: Utility.getAppHexColor("lightText")
                text: paramName
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                font.pointSize: 12
                Accessible.role: Accessible.StaticText
                Accessible.name: nameText.text
            }

            Switch {
                id: boolSwitch
                focusPolicy: Qt.StrongFocus
                Accessible.role: Accessible.CheckBox
                Accessible.name: nameText.text
                Accessible.description: checked ? qsTr("Enabled") : qsTr("Disabled")

                Layout.fillWidth: true

                onCheckedChanged: {
                    if (params != null) {
                        if (params.getUpdateOnly() !== paramName) {
                            params.setUpdateOnly("")
                        }
                        params.updateParamBool(paramName, checked, editor);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    id: nowButton
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: qsTr("Read current value")
                    Accessible.description: qsTr("Update to current controller value")

                    Layout.fillWidth: true
                    Layout.preferredWidth: 500
                    flat: true
                    text: "Current"
                    onClicked: {
                        params.setUpdateOnly(paramName)
                        params.requestUpdate()
                    }
                }

                Button {
                    id: defaultButton
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: qsTr("Load default value")
                    Accessible.description: qsTr("Reset to default")

                    Layout.fillWidth: true
                    Layout.preferredWidth: 500
                    flat: true
                    text: "Default"
                    onClicked: {
                        params.setUpdateOnly(paramName)
                        params.requestUpdateDefault()
                    }
                }

                Button {
                    id: helpButton
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: qsTr("Show help")
                    Accessible.description: qsTr("Show parameter description")

                    Layout.fillWidth: true
                    Layout.preferredWidth: 500
                    flat: true
                    text: "Help"
                    onClicked: {
                        VescIf.emitMessageDialog(
                                    params.getLongName(paramName),
                                    params.getDescription(paramName),
                                    true, true)
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+R"
        context: Qt.WindowShortcut
        onActivated: nowButton.clicked()
    }

    Shortcut {
        sequence: "Ctrl+D"
        context: Qt.WindowShortcut
        onActivated: defaultButton.clicked()
    }

    Shortcut {
        sequence: "F1"
        context: Qt.WindowShortcut
        onActivated: helpButton.clicked()
    }

    Connections {
        target: params

        function onParamChangedBool(src, name, newParam) {
            if (src !== editor && name === paramName) {
                boolSwitch.checked = newParam
            }
        }
    }
}
