#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetKeyDelay 10, 60
SetMouseDelay 10, 60

#Include version.ahk
#Include menu.ahk
#Include resources.ahk
#Include regions.ahk


global dataCenters := new CDataCenters(2 ; home dc's index, start from 1 -> Crystal
	, new DataCenter("Aether", "aether")
	, new DataCenter("Crystal", "traveled", true)
	, new DataCenter("Dynamis", "dynamis")
	, new DataCenter("Primal", "primal"))
	; order needs to be same as in game


; restart script hotkey
^!+o::
	BlockInput, MouseMoveOff
	SoundPlay, *64
	Reload
	return

; datacenter travel hotkey
^!+p::
	ShowGui() {
		if (regions.Initialize()) {
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

		}
		return
		OnButton:
			name := A_GuiControl
			Gui, DcSelect:Destroy
			dataCenters.Travel(name)
			return
		OnCancel:
			Gui, DcSelect:Destroy
			return
	}


SafeSend(keys*) {
    for i, key in keys {
		if (key == "LEFT") {
			Send ^!+{Left}
			Send {Numpad4}
		} else if (key == "RIGHT") {
			Send ^!+{Right}
			Send {Numpad6}
		} else if (key == "DOWN") {
			Send ^!+{Down}
			Send {Numpad2}
		} else if (key == "UP") {
			Send ^!+{Up}
			Send {Numpad8}
		} else {
			Send %key%
		}
		Sleep, 100
	}
}


class CDataCenters {

	__New(dcHomeIndex, dcArray*) {
		this.DcArray := dcArray
		for i, dc in this.DcArray {
			dc.Offset := i - dcHomeIndex
		}
		this.DcHome := this.DcArray[dcHomeIndex]
		this.UnknownAwayDc := new DataCenter("Unknown Data Center Away From Home", new Region("asd", 1, 1, 2, 2, Images.ok)) ; Dummy region

	}

	_RefreshCurrentDc() {
		dcFound := false
		for i, dc in this.DcArray {
			if (dc.IsCurrent()) {
				dcFound := true
				this.CurrentDc := dc
			}
		}

		if (!dcFound) {
			this.CurrentDc := this.UnknownAwayDc
		}

		return this.CurrentDc.Name
	}

	DcList() {
		this._RefreshCurrentDc()
		dcNames := []
		for i, dc in this.DcArray {
			dcName := dc.Name
			if (dc == this.CurrentDc) {
				dcNames.Push("--> " . dcName)
			}  else if (this.CurrentDc == this.UnknownAwayDc && dc != this.DcHome) {
				dcNames.Push("  ? " . dcName)
			} else {
				dcNames.Push("    " . dcName)
			}
		}
		return dcNames
	}


	Travel(label) {
		for i, dc in this.DcArray {
			if (InStr(label, dc.Name)) {
				travelTo := dc
				break
			}
		}

		this._InitTravel()
		if (this.CurrentDc != this.DcHome) {
			this.DcHome.Travel()
		}
		if (travelTo != this.DcHome) {
			travelTo.Travel()
		}
		this._LoginAndFinalize()
	}

	_InitTravel() {
		BlockInput, MouseMove
		SafeSend("{Esc}", "{Esc}")
	}

	_LoginAndFinalize() {
		SafeSend("{Numpad0}", "{Numpad0}")
		BlockInput, MouseMoveOff
		SoundPlay, *64
	}

}

class DataCenter {

	__New(name, regionName, inverseMatch := False) {
		this.Name := name
		this.Matcher := new RegionMatcher(regionName, inverseMatch)
	}

	IsCurrent() {
		return this.Matcher.Matches()
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

		regions.get("crystal").AwaitUntilVisible()
		SafeSend("LEFT", "{Numpad0}") ; accept returning to home data center

		this._AcceptAndFinishTravel()
	}

	_TravelAway() {
		this._NavigateToTravelInterface()
		SafeSend("{Numpad0}")	; one more dialog to accept

		regions.Get("selectdatacenter").AwaitUntilVisible()
		this._MoveOnDataCenterList(offset)
		SafeSend("{Numpad0}", "{Numpad0}", "{Numpad0}")	; accept data center to travel to

		this._AcceptAndFinishTravel()
	}



	_NavigateToTravelInterface() {
		SafeSend("{NumpadMult}"
			   , "DOWN"
			   , "DOWN"
			   , "DOWN"
			   , "{Numpad0}")
	}

	_AcceptAndFinishTravel() {
		regions.Get("proceed").AwaitUntilVisible()
		SafeSend("LEFT", "{Numpad0}")

		regions.Get("ok").AwaitUntilVisible()
		SafeSend("{Numpad0}")

		regions.Get("ox").AwaitUntilVisible()
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


