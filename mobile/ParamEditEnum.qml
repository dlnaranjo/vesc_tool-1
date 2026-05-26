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
    property bool createReady: false
    Accessible.role: Accessible.Group
    Accessible.name: params ? params.getLongName(paramName) : qsTr("Parameter")

    Component.onCompleted: {
        if (params != null) {
            nameText.text = params.getLongName(paramName)
            enumBox.model = params.getParamEnumNames(paramName)
            enumBox.currentIndex = params.getParamEnum(paramName)

            if (params.getParamTransmittable(paramName)) {
                nowButton.visible = true
                defaultButton.visible = true
            } else {
                nowButton.visible = false
                defaultButton.visible = false
            }

            createReady = true
        }
    }

    Rectangle {
        id: rect
        anchors.fill: parent
        color: {color = Utility.getAppHexColor("lightBackground")}
        radius: 5
        border.color:  {border.color = Utility.getAppHexColor("disabledText")}
        border.width: 2

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.bottomMargin: 2
            anchors.margins: 10

            Text {
                id: nameText
                color: {color = Utility.getAppHexColor("lightText")}
                text: paramName
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                font.pointSize: 12
                Accessible.role: Accessible.StaticText
                Accessible.name: nameText.text
            }

            ComboBox {
                id: enumBox
                focusPolicy: Qt.NoFocus
                Layout.fillWidth: true
                Accessible.role: Accessible.ComboBox
                Accessible.name: nameText.text
                Accessible.description: currentText.length > 0
                                        ? qsTr("Current selection: %1").arg(currentText)
                                        : qsTr("Dropdown list")

                background: Rectangle {
                    implicitHeight: 35
                    color: enumBox.hovered ? Utility.getAppHexColor("lightBackground") : Utility.getAppHexColor("normalBackground")
                    border.color: enumBox.hovered ? Utility.getAppHexColor("lightText") : Utility.getAppHexColor("midAccent")
                    border.width: enumBox.visualFocus ? 2 : 1
                    radius: 5
                }

                onCurrentIndexChanged: {
                    if (params != null && createReady) {
                        if (params.getUpdateOnly() !== paramName) {
                            params.setUpdateOnly("")
                        }
                        params.updateParamEnum(paramName, currentIndex, editor);
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

        function onParamChangedEnum(src, name, newParam) {
            if (src !== editor && name === paramName) {
                enumBox.currentIndex = newParam
            }
        }
    }
}
