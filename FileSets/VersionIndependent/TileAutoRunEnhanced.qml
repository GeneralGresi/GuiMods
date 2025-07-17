//// Modified for GeneratorConnector / GuiMods
//		allow smaller inactive tile
//		expand tile to fit content when active
//		for auto run - no TileSpinBox

import QtQuick 1.1
import "utils.js" as Utils

ListView {
	id: root

	property int count: countownTime
	property int countownTime: 5
	property string bindPrefix
	property alias startCountdown: countdownTimer.running
	property bool connected: true
	property VBusItem state: VBusItem { bind: Utils.path(bindPrefix, "/State") }
	property VBusItem autoStart: VBusItem { bind: Utils.path(settingsBindPrefix, "/AutoStartEnabled") }
	property bool autoStartEnabled: autoStart.valid && autoStart.value == 1
	property int tileHeight: 40
	property bool buttonState: autoStartEnabled

	model: tileModel
	height: startTile.height

	Keys.onSpacePressed: { startTile.edit(false); event.accepted = true }

	VisibleItemModel {
		id: tileModel
		Tile {
			id: startTile
			title:
			{
				if (autoStartEnabled)
					return qsTr("AUTO START - Bereit")
				else
					return qsTr ("AUTO START - Deaktiviert")
			}
			width: root.width
			height: root.startCountdown ? contentHeight : tileHeight
			readOnly: !autoStart.valid 
			color: mouseArea.containsMouse ? "#78edd5" : "#16a085" 

			function edit(isMouse)
			{
				if (!connected)
				{
					toast.createToast(qsTr("Generator nicht verbunden"))
					return
				}
				else
					startCountdown = !startCountdown
			}

			MouseArea {
				id: mouseArea
				anchors.fill: parent
				onClicked: {
					parent.edit(true)
				}
			}

			values: [
				TileTextMultiLine {
					font.pixelSize: 12
					text:
					{
						if (root.activeFocus)
							return qsTr("Drücken für")
						else
							return qsTr ("Drücken für")
					}
					width: root.width - 6
					visible: !root.startCountdown || (root.startCountdown && !buttonState || countdownText.visible)
				},
				TileTextMultiLine {
					text:
					{
						if (root.startCountdown)
							return qsTr ("ABBRUCH")
						else if (buttonState)
							return qsTr("DEAKTIVIEREN")
						else
							return qsTr("AKTIVIEREN")
					}
					font.pixelSize: 22
					verticalAlignment: Text.AlignTop
					width: root.width - 6
				},
				TileTextMultiLine {
					id: countdownText
					text:
					{
						if (buttonState)
							return qsTr("Deaktiviert in %1 s").arg(root.count)
						else
							return qsTr("Aktiviert in %1 s").arg(root.count)
					}
					width: root.width - 6
					visible: root.startCountdown
				}
			]
		}
	}

	Timer {
		id: countdownTimer
		interval: 1000
		running: root.startCountdown
		repeat: root.count >= 0
		onRunningChanged: root.count = root.countownTime
		onTriggered: {
			if (root.count == 0)
			{
				autoStart.setValue (autoStartEnabled ? 0 : 1)
				root.startCountdown = false
			}
			root.count--
		}
	}
}
