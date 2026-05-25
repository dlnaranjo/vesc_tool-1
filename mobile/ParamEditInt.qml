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

import QtQuick 2.15
import QtQuick.Controls 2.15
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
    Accessible.description: params
                            ? qsTr("Current value %1%2, range %3 to %4").arg(valueBox.realValue).arg(valueBox.suffix).arg(valueBox.realFrom).arg(valueBox.realTo)
                            : qsTr("Numeric parameter editor")

    Component.onCompleted: {
        if (params != null) {
            if (Math.abs(params.getParamMaxInt(paramName)) > params.getParamMinInt(paramName)) {
                maxVal = Math.abs(params.getParamMaxInt(paramName))
            } else {
                maxVal = Math.abs(params.getParamMinInt(paramName))
            }

            nameText.text = params.getLongName(paramName)
            valueBox.realFrom = params.getParamMinInt(paramName) * params.getParamEditorScale(paramName)
            valueBox.realTo = params.getParamMaxInt(paramName) * params.getParamEditorScale(paramName)
            valueBox.realStepSize = params.getParamStepInt(paramName)
            valueBox.visible = !params.getParamEditAsPercentage(paramName)
            valueBox.suffix = params.getParamSuffix(paramName)
            valueBox.realValue = params.getParamInt(paramName) * params.getParamEditorScale(paramName)

            var p = (params.getParamInt(paramName) * 100.0) / maxVal
            percentageBox.from = (100.0 * params.getParamMinInt(paramName)) / maxVal
            percentageBox.to = (100.0 * params.getParamMaxInt(paramName)) / maxVal
            percentageBox.visible = params.getParamEditAsPercentage(paramName)
            percentageBox.value = p

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

    function updateDisplay(value) {
        // TODO: No display for now...
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
            anchors.topMargin: 10
            anchors.margins: 5

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

            DoubleSpinBox {
                id: valueBox
                Layout.fillWidth: true
                decimals: 0
                accessibleName: nameText.text
                accessibleDescription: qsTr("Current value %1%2, range %3 to %4").arg(realValue).arg(suffix).arg(realFrom).arg(realTo)

                onRealValueChanged: {
                    if (!params.getParamEditAsPercentage(paramName)) {
                        var val = realValue / params.getParamEditorScale(paramName)

                        if (params !== null && createReady) {
                            if (params.getUpdateOnly() !== paramName) {
                                params.setUpdateOnly("")
                            }
                            params.updateParamInt(paramName, val, editor);
                        }

                        updateDisplay(val);
                    }
                }
            }

            SpinBox {
                id: percentageBox
                Layout.fillWidth: true
                editable: true
                visible: false
                Accessible.role: Accessible.SpinBox
                Accessible.name: qsTr("%1 percentage").arg(nameText.text)
                Accessible.description: qsTr("Current value %1 percent, range %2 to %3").arg(value).arg(from).arg(to)

                onValueChanged: {
                    if (params.getParamEditAsPercentage(paramName)) {
                        var val = (value / 100.0) * maxVal

                        if (params != null && createReady) {
                            if (params.getUpdateOnly() !== paramName) {
                                params.setUpdateOnly("")
                            }
                            params.updateParamInt(paramName, val, editor);
                        }

                        updateDisplay(val);
                    }
                }

                textFromValue: function(value, locale) {
                    return Number(value).toLocaleString(locale, 'f', 0) + " %"
                }

                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text.replace("%", ""))
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    id: nowButton
                    focusPolicy: Qt.NoFocus
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
                    focusPolicy: Qt.NoFocus
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
                    focusPolicy: Qt.NoFocus
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

    Connections {
        target: params

        function onParamChangedInt(src, name, newParam) {
            if (src !== editor && name === paramName) {
                valueBox.realValue = newParam * params.getParamEditorScale(paramName)
                percentageBox.value = Math.round((100.0 * newParam) / maxVal)
            }
        }
    }
}
