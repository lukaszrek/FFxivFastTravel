#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetKeyDelay 10, 60
SetMouseDelay 10, 60
CoordMode, Mouse, Screen


#Include version.ahk
#Include travellog.ahk
#Include menu.ahk
#Include pcap.ahk
#Include detection.ahk

global FFXIVWND := "FINAL FANTASY XIV"

global dataCenters := new CDataCenters(2 ; home dc's index, start from 1 -> Crystal
	, new DataCenter("Aether", AETHER_HOST)
	, new DataCenter("Crystal", CRYSTAL_HOST)
	, new DataCenter("Dynamis", DYNAMIS_HOST)
	, new DataCenter("Primal", PRIMAL_HOST))
	; order needs to be same as in game

global detector := CreateDetector(dataCenters.AllAreas())
global guic := new CGuiControl()


SetTimer, Update, 500

Update() {
	dataCenters.Update()
	guic.Update()
}

; tab into / out of ffxiv game during travel
Hotkey, Tab, TabHK
Hotkey, Tab, Off
TabHK() {
	guic.ToggleWindow()
	return
}

; datacenter travel hotkey
Hotkey, ^!+p, ShowGuiHK
Hotkey, ^!+p, Off
ShowGuiHK() {
	Gui, DcSelect:New ,-SysMenu ToolWindow
	Gui, DcSelect:Add, Text,, Select DC you want to travel to:
	for i, name in dataCenters.DcList() {
		if (InStr(name, "-->")) {
			Gui, DcSelect:Add, Button, Left gOnButton w150 Disabled, %name%
		} else {
			Gui, DcSelect:Add, Button, Left gOnButton w150, %name%
		}
	}
	Gui, DcSelect:Add, Text,,
	Gui, DcSelect:Add, Text,, % "Currently on:`n" . dataCenters.CurrentDc.Name
	Gui, DcSelect:Add, Button, gOnCancel, Cancel
	Gui, DcSelect:Show,,

	return
	OnButton:
		name := A_GuiControl
		Gui, DcSelect:Destroy
		WinActivate, %FFXIVWND%
		dataCenters.Travel(name)
		return
	OnCancel:
		Gui, DcSelect:Destroy
		return
}


; restart script hotkey
^!+o::
	BlockInput, MouseMoveOff
	SoundPlay, *64
	Reload
	return

SafeSend(keys*) {
    for i, key in keys {
		if (key == "LEFT") {
			SendToFF("^!+{Left}")
			SendToFF("{Numpad4}")
		} else if (key == "RIGHT") {
			SendToFF("^!+{Right}")
			SendToFF("{Numpad6}")
		} else if (key == "DOWN") {
			SendToFF("^!+{Down}")
			SendToFF("{Numpad2}")
		} else if (key == "UP") {
			SendToFF("^!+{Up}")
			SendToFF("{Numpad8}")
		} else {
			SendToFF(key)
		}
		Sleep, 200
	}
}

SendToFF(key) {
	ControlSend, ahk_parent, %key%, %FFXIVWND%
}


class CGuiControl {

	__New() {
		this.winActive := false
		this.inputBlocked := false
	}

	Update() {
		this.winActive := WinActive(FFXIVWND)

		startHotkeyActive := !dataCenters.Traveling && dataCenters.CurrentDc && this.winActive
		tabHotkeyActive := dataCenters.Traveling
		osdVisible := (dataCenters.CurrentDc || dataCenters.Traveling) && this.winActive
		inputShouldBeBlocked := dataCenters.Traveling && dataCenters.winActive

		Hotkey, ^!+p, % this.OnOff(startHotkeyActive)
		Hotkey, Tab, % this.OnOff(tabHotkeyActive)
		travelLog.Toggle(osdVisible)

		if (this.inputBlocked && !inputShouldBeBlocked) {
			BlockInput, MouseMoveOff
			this.inputBlocked := false
		} else if (!this.inputBlocked && inputShouldBeBlocked) {
			BlockInput, MouseMove
			MouseGetPos, MouseX, MouseY
			this.MouseX := MouseX
			this.MouseY := MouseY
			this.inputBlocked := true
		}
		travelLog.Debug(Format("p:{1} t:{2} o:{3} i:{4}", startHotkeyActive, tabHotkeyActive, osdVisible, inputShouldBeBlocked))
	}

	OnOff(flag) {
		if (flag) {
			return "On"
		} else {
			return "Off"
		}
	}

	ToggleWindow() {
		if (this.winActive) {
			Send !{Tab}
		} else {
			BlockInput, MouseMove
			this.inputBlocked := true
			MouseMove, % this.MouseX, % this.MouseY
			WinActivate, %FFXIVWND%
		}
		Update()
	}
}

class CDataCenters {

	__New(dcHomeIndex, dcArray*) {
		this.DcArray := dcArray
		for i, dc in this.DcArray {
			dc.Offset := i - dcHomeIndex
		}
		this.DcHome := this.DcArray[dcHomeIndex]
		this.Traveling := false
	}

	AllAreas() {
		ret := []
		for i, dc in this.DcArray {
			ret.Push(dc.Area())
		}
		return ret
	}


	DcList() {
		this.Update()
		dcNames := []
		for i, dc in this.DcArray {
			dcName := dc.Name
			if (dc == this.CurrentDc) {
				dcNames.Push("--> " . dcName)
			} else {
				dcNames.Push("    " . dcName)
			}
		}
		return dcNames
	}

	Update() {
		if (!this.Traveling) {
			if (currentArea := detector.GetCurrentArea()) {
				for i, dc in this.DcArray {
					if (dc.Name == currentArea.Name) {
						this.CurrentDc := dc
					}
				}
				travelLog.On(currentArea.Name)
			} else {
				this.CurrentDc := 0
			}
		}
	}

	Travel(label) {

		for i, dc in this.DcArray {
			if (InStr(label, dc.Name)) {
				travelTo := dc
				break
			}
		}
		if (!travelTo) {
			MsgBox % "label not found " . label
		}

		this._InitTravel(travelTo)
		if (this.CurrentDc != this.DcHome) {
			this.DcHome.Travel()
		}
		if (travelTo != this.DcHome) {
			travelTo.Travel()
		}
		this._LoginAndFinalize()

	}

	_InitTravel(travelTo) {
		this.Traveling := true
		travelLog.StartTravel(this.CurrentDc.Name, travelTo.Name)
		guic.Update()
		SafeSend("{Esc}", "{Esc}")
	}

	_LoginAndFinalize() {
		SafeSend("{Numpad0}", "{Numpad0}")
		SoundPlay, *64
		travelLog.Hide()
		this.Traveling := false
		guic.Update()
	}

}

class DataCenter {

	__New(name, addr) {
		this.Name := name
		this.Addr := addr
	}

	Area() {
		return new CArea(this.Name, this.Addr)
	}

	Travel() {
		if (this.Offset == 0) {
			this._TravelHome()
		} else {
			this._TravelAway()
		}
	}

	_TravelHome() {
		this._NavigateToTravelInterface()

		travelLog.SetWaitingForSelectWorld()
		detector.WaitForSelectWorld()

		travelLog.SetSelectingWorld()
		SafeSend("LEFT", "{Numpad0}") ; accept returning to home data center

		this._AcceptAndFinishTravel()
	}

	_TravelAway() {
		this._NavigateToTravelInterface()
		SafeSend("{Numpad0}")	; one more dialog to accept

		travelLog.SetWaitingForSelectWorld()
		detector.WaitForSelectWorld()

		travelLog.SetSelectingWorld()
		this._MoveOnDataCenterList(offset)
		SafeSend("{Numpad0}", "{Numpad0}", "{Numpad0}")	; accept data center to travel to

		this._AcceptAndFinishTravel()
	}

	_NavigateToTravelInterface() {
		travelLog.SetNavigatingToSelectWorld()
		SafeSend("{NumpadMult}"
			   , "DOWN"
			   , "DOWN"
			   , "DOWN"
			   , "{Numpad0}")
	}

	_AcceptAndFinishTravel() {

		travelLog.SetWaitingForTravelConfirmation()
		detector.WaitForTravelConfirmationMenu()

		travelLog.SetAcceptingTravel()
		SafeSend("LEFT", "{Numpad0}")

		travelLog.SetTravelingTo(this.Name)
		detector.WaitForTravelFinish()

		travelLog.SetConfirmingDataCenterArrival()
		SafeSend("{Numpad0}")

		travelLog.SetConnectingToDataCenter()
		detector.WaitForConnectingToDataCenter()
	}

	_MoveOnDataCenterList() {
		offset := this.Offset
		key := ""
		if (offset < 0) {
			key := "UP"
			offset := -offset
		} else {
			key := "DOWN"
		}
		while (offset > 0) {
			SafeSend(key)
			offset := offset - 1
		}
		return
	}
}


