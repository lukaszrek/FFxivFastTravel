#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


SetKeyDelay 10, 60
SetMouseDelay 10, 60

; FF14WND = "ahk_class FFXIVGAME"

global REGION_OX := new Region(35, 990, 106, 1047, "ox.png")
global REGION_SELECT_DATA_CENTER := new Region(728, 466, 915, 491, "SelectDataCenter.png")
global REGION_PROCEED := new Region(764, 708, 943, 750, "Proceed.png")
global REGION_OK := new Region(800, 500, 1100, 700, "OK.png")
global REGION_CRYSTAL := new Region(790, 460, 900, 510, "Crystal.png")


global DATA_CENTERS := new DataCenters(2 ; home dc's index, start from 1-> Crystal
	, new DataCenter("Aether", new Region(1400, 90, 1700, 130, "Aether.png"))
	, new DataCenter("Crystal",new Region(25, 500, 200, 600, "TraveledFrom.png"), true)
	, new DataCenter("Dynamis", new Region(1400, 90, 1700, 130, "Dynamis.png"))
	, new DataCenter("Primal", new Region(1400, 90, 1700, 130, "Primal.png")))
	; order needs to be same as in game


; restart script hotkey
F1::
	BlockInput, MouseMoveOff
	SoundPlay, *64
	Reload
	return

F2::
	currentDc := DATA_CENTERS._RefreshCurrentDc()
	MsgBox "Current DC: " . %currentDc%
	return

; datacenter travel hotkey
^!+p::
	ShowGui() {
		if (REGION_OX.IsVisible()) {
			Gui, -SysMenu ToolWindow
			Gui, Add, Text,, Select DC you want to travel to:
			for i, name in DATA_CENTERS.DcList() {
				if (InStr(name, "-->")) {
					Gui, Add, Button, Left gOnButton w150 Disabled, %name%
				} else {
					Gui, Add, Button, Left gOnButton w150, %name%
				}
			}
			Gui, Add, Text,,
			Gui, Add, Text,, % "Currently on:`n" . DATA_CENTERS.CurrentDc.Name
			Gui, Add, Button, gOnCancel, Cancel
			Gui, Show,,

		}
		return
		OnButton:
			name := A_GuiControl
			Gui, Destroy
			DATA_CENTERS.Travel(name)
			return
		OnCancel:
			Gui, Destroy
			return
	}


SafeSend(keys*) {
    for i, key in keys {
		Send %key%
		Sleep, 100
	}
}


class DataCenters {

	__New(DcHomeIndex, DcArray*) {
		this.DcArray := DcArray
		for i, dc in this.DcArray {
			dc.Offset := i - DcHomeIndex
		}
		this.DcHome := this.DcArray[DcHomeIndex]
		this.UnknownAwayDc := new DataCenter("Unknown Data Center Away From Home", new Region(1, 1, 2, 2, "OK.png"))

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
		DcNames := []
		for i, dc in this.DcArray {
			dcname := dc.Name
			if (dc == this.CurrentDc) {
				DcNames.Push("--> " . dcname)
			}  else if (this.CurrentDc == this.UnknownAwayDc && dc != this.DcHome) {
				DcNames.Push("  ? " . dcname)
			} else {
				DcNames.Push("    " . dcname)
			}
		}
		return DcNames
	}


	Travel(Name) {
		for i, dc in this.DcArray {
			if (InStr(Name, dc.Name)) {
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
		SoundPlay, *64
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

	__New(Name, RegionObj, InverseMatch := False) {
		this.Name := Name
		this.Matcher := new RegionMatcher(RegionObj, InverseMatch)
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

		REGION_CRYSTAL.AwaitUntilVisible()
		SafeSend("{Numpad4}", "{Numpad0}") ; accept returning to home data center

		this._AcceptAndFinishTravel()
	}

	_TravelAway() {
		this._NavigateToTravelInterface()
		SafeSend("{Numpad0}")	; one more dialog to accept

		REGION_SELECT_DATA_CENTER.AwaitUntilVisible()
		this._MoveOnDataCenterList(offset)
		SafeSend("{Numpad0}", "{Numpad0}", "{Numpad0}")	; accept data center to travel to

		this._AcceptAndFinishTravel()
	}



	_NavigateToTravelInterface() {
		SafeSend("{NumpadMult}"
			   , "{Numpad2}"
			   , "{Numpad2}"
			   , "{Numpad2}"
			   , "{Numpad0}")
	}

	_AcceptAndFinishTravel() {
		REGION_PROCEED.AwaitUntilVisible()
		SafeSend("{Numpad4}", "{Numpad0}")

		REGION_OK.AwaitUntilVisible()
		SafeSend("{Numpad0}")

		REGION_OX.AwaitUntilVisible()
	}



	_MoveOnDataCenterList() {
		offset := this.Offset
		key := ""
		if (offset < 0) {
			key := "{Numpad8}"
			offset := -offset
		} else {
			key := "{Numpad2}"
		}
		while (offset > 0) {
			SafeSend(key)
			offset := offset - 1
		}
		return
	}

}

class RegionMatcher {
	__New(RegionObj, Inverse := False) {
		this.RegionObj := RegionObj
		this.Inverse := Inverse
	}

	Matches() {
		if (this.Inverse) {
			return !this.RegionObj.IsVisible()
		} else {
			return this.RegionObj.IsVisible()
		}
	}
}

class Region {

	__New(X1, Y1, X2, Y2, FileName) {
		this.X1 := X1
		this.Y1 := Y1
		this.X2 := X2
		this.Y2 := Y2
		this.FileName := FileName
	}


	IsVisible() {
		FileName := this.FileName
		ImageSearch,,, % this.X1, % this.Y1, % this.X2, % this.Y2, *100 *Trans00FF00 %FileName%
		if (ErrorLevel == 0) {
			return true
		} else if (ErrorLevel == 1) {
			return false
		} else {
			MsgBox "Error" . %ErrorLevel%
		}
	}

	AwaitUntilVisible() {
		while(!this.IsVisible()) {
			Sleep, 200
		}
	}
}
