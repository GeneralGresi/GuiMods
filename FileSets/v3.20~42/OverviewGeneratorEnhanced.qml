// GuiMods enhanced generator overview
// This file has been modified to:
//	add Auto Start display and control
//	show voltage, current, frequency, and power gauge in AC input tile
//	show the generator running state inside the icon top left
// 	show a warning when the generator digital input and expected generator state disagree
//	move current run time to separate tile
 
import QtQuick 1.1
import "utils.js" as Utils
import "enhancedFormat.js" as EnhFmt

OverviewPage {
	id: root
 
	property string settingsBindPrefix
	property string bindPrefix
	property variant sys: theSystem
//////// added to show alternator in place of inactive genset
    property string guiModsPrefix: "com.victronenergy.settings/Settings/GuiMods"
    VBusItem { id: replaceAcInItem; bind: Utils.path(guiModsPrefix, "/ReplaceInactiveAcIn") }
    property bool hasAlternator: sys.alternator.power.valid
    property bool showAlternator: replaceAcInItem.valid && replaceAcInItem.value == 1 && hasAlternator && ! sys.genset.power.valid
    property bool showAcIn: ! showAlternator     
    
	property string icon: "overview-generator"
	property VBusItem state: VBusItem { bind: Utils.path(bindPrefix, "/State") }
	property VBusItem error: VBusItem { bind: Utils.path(bindPrefix, "/Error") }
	property VBusItem runningTime: VBusItem { bind: Utils.path(bindPrefix, "/Runtime") }
	property VBusItem runningBy: VBusItem { bind: Utils.path(bindPrefix, "/RunningByConditionCode") }
	VBusItem { id: totalAcummulatedTime; bind: Utils.path(settingsBindPrefix, "/AccumulatedTotal") }
	VBusItem { id: totalAccumulatedTimeOffset; bind: Utils.path(settingsBindPrefix, "/AccumulatedTotalOffset") }
	property VBusItem quietHours: VBusItem { bind: Utils.path(bindPrefix, "/QuietHours") }
	property VBusItem testRunDuration: VBusItem { bind: Utils.path(settingsBindPrefix, "/TestRun/Duration") }
	property VBusItem nextTestRun: VBusItem { bind: Utils.path(bindPrefix, "/NextTestRun") }
	property VBusItem skipTestRun: VBusItem { bind: Utils.path(bindPrefix, "/SkipTestRun") }

	property VBusItem todayRuntime: VBusItem { bind: Utils.path(bindPrefix, "/TodayRuntime") }
	property VBusItem manualTimer: VBusItem { bind: Utils.path(bindPrefix, "/ManualStartTimer") }
	property VBusItem autoStart: VBusItem { bind: Utils.path(settingsBindPrefix, "/AutoStartEnabled") }

	property bool errors: ! state.valid || state.value == 10

    property VBusItem externalOverrideItem: VBusItem { bind: Utils.path(bindPrefix, "/ExternalOverride") }
    property bool externalOverride: externalOverrideItem.valid && externalOverrideItem.value == 1 && ! errors
    property VBusItem runningState: VBusItem { bind: Utils.path(bindPrefix, "/GeneratorRunningState") }

    VBusItem { id: showGaugesItem; bind: Utils.path(guiModsPrefix, "/ShowGauges") }
    property bool showGauges: showGaugesItem.valid ? showGaugesItem.value === 1 ? true : false : false
	property bool editMode: autoRunTile.editMode || manualTile.editMode

    VBusItem { id: serviceInterval; bind: Utils.path(settingsBindPrefix, "/ServiceInterval") }
    VBusItem { id: serviceCounterItem; bind: Utils.path(bindPrefix, "/ServiceCounter") }
    property bool showServiceInfo: serviceCounterItem.valid && serviceInterval.valid && serviceInterval.value > 0
	property bool serviceOverdue: showServiceInfo && serviceCounterItem.value < 0

	property VBusItem startSoc: VBusItem { bind: Utils.path(settingsBindPrefix, "/Soc/StartValue") }
	property VBusItem stopSoc: VBusItem { bind: Utils.path(settingsBindPrefix, "/Soc/StopValue") }
	property VBusItem conditionEnabledSoc: VBusItem { bind: Utils.path(settingsBindPrefix, "/Soc/Enabled") }

	property VBusItem startBatVoltage: VBusItem { bind: Utils.path(settingsBindPrefix, "/BatteryVoltage/StartValue") }
	property VBusItem stopBatVoltage: VBusItem { bind: Utils.path(settingsBindPrefix, "/BatteryVoltage/StopValue") }
	property VBusItem conditionEnabledBatVoltage: VBusItem { bind: Utils.path(settingsBindPrefix, "/BatteryVoltage/Enabled") }

	title: qsTr("Generator")

	property bool autoStartSelected: false

    Component.onCompleted:
    { 
		setFocusManual ()
	}

	Keys.forwardTo: [keyHandler]
	Item
	{
		id: keyHandler
		Keys.onUpPressed:
		{ 
			setFocusAuto ()
			event.accepted = true
		}
		Keys.onDownPressed:
		{ 
			setFocusManual ()
			event.accepted = true			
		}
		// prevents page changes while timers are running
		//// Keys.onReturnPressed: event.accepted = manualTile.startCountdown || autoRunTile.startCountdown
		//// Keys.onEscapePressed: event.accepted = manualTile.startCountdown || autoRunTile.startCountdown
	}

	function setFocusManual ()
	{
		autoStartSelected = false
	}

	function setFocusAuto ()
	{
		autoStartSelected = true
	}

	function formatTime (time)
	{
		var calc_hours = Math.floor(time / 3600)
		var calc_minutes = Math.floor(((time - (calc_hours * 3600))) / 60)
		var calc_seconds = Math.floor(time - (calc_hours * 3600) - (calc_minutes * 60))
		
		var message = ""
		if (calc_hours > 0) {
			message = message + calc_hours + " h "
		}
		if (calc_minutes > 0 || calc_hours > 0) {
			message = message + calc_minutes + " m "
		}
		return (message + calc_seconds + " s")
	}

	function stateDescription()
	{
		if (!state.valid)
			return qsTr ("")
		else if (state.value === 10)
		{
			switch(error.value)
			{
			case 1:
				return qsTr("Error: Remote switch control disabled")
			case 2:
				return qsTr("Error: Generator in fault condition")
			case 3:
				return qsTr("Error: Generator not detected at AC input")
			default:
				return qsTr("Error")
			}
		}
		else
		{
			var condition = ""
			var running = true
			var manual = false
			switch (runningBy.value)
			{
			case 0:	// stopped
				condition = ""
				running = false
				break;;
			case 1:
				manual = true
				condition = ""
				break;;
			case 2:
				condition = qsTr("Testlauf")
				break;;
			case 3:
				condition = qsTr("Kommunikationsverlust")
				break;;
			case 4:
				condition = qsTr("SOC Nied")
				break;;
			case 5:
				condition = qsTr("AC Last Hoch")
				break;;
			case 6:
				condition = qsTr("Batterie Strom Hoch")
				break;;
			case 7:
				condition = qsTr("Batterie Spannung Niedrig")
				break;;
			case 8:
				condition = qsTr("Wechselrichter Temperatur")
				break;;
			case 9:
				condition = qsTr("Wechselrichter Überlast")
				break;;
			default:
				condition = qsTr("???")
				break;;
			}

			if (externalOverride)
			{
				if (running && ! manual)
					return qsTr ("Starte Automatisch: ") + condition
				else
					return " "
			}
			else if (manual)
			{
				if (manualTimer.valid && manualTimer.value > 0)
					return qsTr("Zeitbasierter Lauf")
				else
					return qsTr("Manueller Betrieb")
			}
			else if (running)
				return qsTr ("Automatischer Betrieb: ") + condition
			else
				return " "
		}
	}

	function getNextTestRun()
	{
		if ( ! root.state.valid)
			return ""
		if (!nextTestRun.value)
			return qsTr("Kein Testlauf programmiert")

		var todayDate = new Date()
		var nextDate = new Date(nextTestRun.value * 1000)
		var nextDateEnd = new Date(nextDate.getTime())
		var message = ""
		// blank "next run" if test run is active
		if (runningBy.value == 2)
			return " "
		else if (todayDate.getDate() == nextDate.getDate() && todayDate.getMonth() == nextDate.getMonth())
		{
			message = qsTr("Nächster Testlauf heute, %1").arg(
						Qt.formatDateTime(nextDate, "hh:mm").toString())
		}
		else
		{
			message = qsTr("Nächster Testlauf am %1").arg(
						Qt.formatDateTime(nextDate, "dd.MM.yyyy").toString())
						nextDateEnd.setSeconds(testRunDuration.value)		}

		if (skipTestRun.value === 1)
			message += qsTr(" \(übersprungen\)")

		return message
	}

	Tile {
		id: imageTile
		width: 180
		height: 136
		MbIcon {
			id: generator
			iconId: icon
			anchors.centerIn: parent
		}
		anchors { top: parent.top; left: parent.left }
        values: [
                // spacer
                TileText {
                    width: imageTile.width - 5
                    text: " "
                    font.pixelSize: 62
                },
                TileText {
                    width: imageTile.width - 5
                    text: runningState.valid ? runningState.value == "R" ? "In Betrieb " : runningState.value == "S" ? "Gestoppt " : "" : ""
                }
        ]
	}

	Tile {
		id: statusTile
		height: imageTile.height
		color: "#4789d0"
		anchors { top: parent.top; left: imageTile.right; right: root.right }
		title: qsTr("STATUS")
		values: [
            TileText
            {
                width: statusTile.width - 5
                color: externalOverride ? "yellow" : "white"
				text:
				{
					var runPrefix
					var message
					if ( ! root.state.valid)
						return qsTr ("Generator nicht verbunden")
					else if (root.state.value === 2)
						runPrefix = qsTr("Aufwärmen, Laufzeit: ")
					else if (root.state.value === 3)
                                                runPrefix = qsTr("Abkühlen, Laufzeit: ")
					else
						runPrefix = qsTr ("In Betrieb, Laufzeit: ")
					if (!root.state.valid)
						message = ""
					else if (externalOverride)
						message = qsTr("Generator Fehler? - gestoppt")
					else if (root.state.value === 4)
						message = qsTr("Stoppen")
					else if (runningBy.value == 0)
						message = qsTr ("Gestoppt")
					else if ( ! runningTime.valid)
						message = runPrefix + "??"
					else
					{
						message = runPrefix + formatTime (runningTime.value) 
						if (manualTimer.valid && manualTimer.value > 0)
							message += qsTr ("  endet in ") + formatTime (manualTimer.value)
					}
					return message
				}
            },
			Rectangle
			{
				width: parent.width
				height: 3
				color: "transparent"
			},
			TileTextMultiLine
			{
				text: stateDescription()
				width: statusTile.width - 5
			},
			Rectangle
			{
				width: parent.width
				height: 3
				color: "transparent"
			},
			TileText
			{
				text: qsTr("\nRuhezeiten");
				width: statusTile.width - 5
				font.bold: runningBy.valid && runningBy.value != 0
				color: font.bold ? "yellow" : "white"
				visible: quietHours.value === 1
			},
			Rectangle
			{
				width: parent.width
				height: 3
				color: "transparent"
			},
			TileTextMultiLine
			{
				width: statusTile.width - 5
				text: getNextTestRun()
			}
		]
	}

	Tile {
		id: autoStartConditionsTile
		title: qsTr("AutoStart Bedingungen")
		width: 150
		height: 136
		color: "#82acde"
		anchors { top: imageTile.bottom; left: parent.left }
		visible: autoStart.valid && autoStart.value === 1
		values:
		[
			Rectangle
			{
				width: parent.width
				height: 3
				color: "transparent"
			},
			TileText
			{
				width: autoStartConditionsTile.width - 5
				text: {
					if (conditionEnabledSoc.valid && conditionEnabledSoc.value === 1 && startSoc.valid) {
						qsTr ("Start SOC: " + startSoc.value + " %")
					} else {
						qsTr ("")
					}
				}
			},
			TileText
			{
				width: autoStartConditionsTile.width - 5
				text: {
					if (conditionEnabledSoc.valid && conditionEnabledSoc.value === 1 && stopSoc.valid) {
						qsTr ("Stop SOC: " + stopSoc.value + " %")
					} else {
						qsTr ("")
					}
				}
			},
			TileText
			{
				width: autoStartConditionsTile.width - 5
				text: {
					if (conditionEnabledBatVoltage.valid && conditionEnabledBatVoltage.value === 1 && startBatVoltage.valid) {
						qsTr ("Start Bat V: " + startBatVoltage.value.toFixed(1) + " V")
					} else {
						qsTr ("")
					}
				}
			},
			TileText
			{
				width: autoStartConditionsTile.width - 5
				text: {
					if (conditionEnabledBatVoltage.valid && conditionEnabledBatVoltage.value === 1 && stopBatVoltage.valid) {
						qsTr ("Stop Bat V: " + stopBatVoltage.value.toFixed(1) + " V")
					} else {
						qsTr ("")
					}
				}
			},
			Rectangle
			{
				width: parent.width
				height: 8
				color: "transparent"
			},
			TileText
			{
				width: autoStartConditionsTile.width - 5
				text: qsTr ("Gresi was here")
				visible: conditionEnabledSoc.valid && conditionEnabledSoc.value === 1 && startSoc.valid
			}
		]
////// add power bar graph
        PowerGauge
        {
            id: acInBar
            width: parent.width
            height: 12
            anchors
            {
                top: parent.top; topMargin: 20
                horizontalCenter: parent.horizontalCenter
            }
			connection: sys.genset
			useInputCurrentLimit: true
            maxForwardPowerParameter: ""
            maxReversePowerParameter: ""
            visible: showGauges
        }
	}
//////// added to show alternator in place of AC generator
	Tile {
		id: alternatorTile
		title: qsTr("ALTERNATOR POWER")
		color: "#157894"
		anchors.fill: autoStartConditionsTile
		visible: showAlternator
		values:
		[
			TileText
			{
				text: EnhFmt.formatVBusItem (sys.alternator.power, "W")
				font.pixelSize: 22
			}
		]
////// add power bar graph
        PowerGauge
        {
            id: alternatorGauge
            width: parent.width
            height: 12
            anchors
            {
                top: parent.top; topMargin: 20
                horizontalCenter: parent.horizontalCenter
            }
            connection: sys.alternator
            maxForwardPowerParameter: "com.victronenergy.settings/Settings/GuiMods/GaugeLimits/MaxAlternatorPower"
            visible: showGauges && showAlternator
        }
	}

	Tile {
		id: runTimeTile
		title: qsTr("Laufzeiten")
		width: 140
		anchors { top: autoStartConditionsTile.top; bottom: parent.bottom; left: autoStartConditionsTile.right }
		values: [
			TileText
			{
				width: runTimeTile.width - 5
				text: qsTr ("Heute")
			},
			TileText {
				width: runTimeTile.width - 5
				text: todayRuntime.valid ? formatTime (todayRuntime.value) : "--"
			},
			Rectangle
			{
				width: parent.width
				height: 3
				color: "transparent"
			},
			TileText
			{
				width: runTimeTile.width - 5
				text: qsTr ("Gesamt")
			},
			TileText
			{
				width: runTimeTile.width - 5
				text:
				{
					if ( ! totalAcummulatedTime.valid)
						return "--"
					else if (totalAccumulatedTimeOffset.valid )
						return formatTime (totalAcummulatedTime.value - totalAccumulatedTimeOffset.value)
					else
						return formatTime (totalAcummulatedTime.value)
				}
			},
			Rectangle
			{
				width: parent.width
				height: 3
				color: "transparent"
			},
			TileText
			{
				width: runTimeTile.width - 5
				visible: showServiceInfo
				color: serviceOverdue ? "red" : "white"
				text: serviceOverdue ? qsTr ("Service Überfällig") : qsTr ("Service in")
			},
			TileText
			{
				width: runTimeTile.width - 5
				visible: showServiceInfo
				color: serviceOverdue ? "red" : "white"
				text: formatTime (Math.abs (serviceCounterItem.value))
			}
		]
	}

	TileAutoRunEnhanced
	{
		id: autoRunTile
		bindPrefix: root.bindPrefix
		focus: root.active && autoStartSelected
		connected: state.valid
		tileHeight: autoStartConditionsTile.height / 2
		anchors {
			bottom: parent.bottom; bottomMargin: tileHeight
			left: runTimeTile.right
			right: parent.right
		}
	}

	TileManualStartEnhanced
	{
		id: manualTile
		bindPrefix: root.bindPrefix
		focus: root.active && ! autoStartSelected
		connected: state.valid
		tileHeight: autoStartConditionsTile.height / 2
		anchors {
			bottom: parent.bottom
			left: runTimeTile.right
			right: parent.right
		}
	}

	// mouse areas must be AFTER their associated objects so those objects can catch mouse events
	// rejected by these areas
	// mouse targets need to be disabled while changes are pending
	MouseArea {
		id: autoRunTarget
		anchors.fill: autoRunTile
		enabled: root.active && ! editMode
		onPressed:
		{
			if ( ! root.autoStartSelected )
			{
				setFocusAuto ()
				mouse.accepted = true
			}
			else
			{
				mouse.accepted = false
			}
		} 
	}
	MouseArea {
		id: manualStartTarget
		anchors.fill: manualTile
		enabled: root.active && ! editMode
		onPressed:
		{
			if ( root.autoStartSelected )
			{
				setFocusManual ()
				mouse.accepted = true
			}
			else
			{
				mouse.accepted = false
			}
		}
	}
}
