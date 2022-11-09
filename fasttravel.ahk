

#Include resources.ahk
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



SetKeyDelay 10, 60
SetMouseDelay 10, 60

; FF14WND = "ahk_class FFXIVGAME"/


global REGION_SELECT_DATA_CENTER := new Region(728, 466, 915, 491, Images.selectdatacenter)
global REGION_OK := new Region(800, 500, 1100, 700, Images.ok)
global REGION_CRYSTAL := new Region(790, 460, 900, 510, Images.crystal)


global DATA_CENTERS := new DataCenters(2 ; home dc's index, start from 1 -> Crystal
	, new DataCenter("Aether", "aether")
	, new DataCenter("Crystal", "traveled", true)
	, new DataCenter("Dynamis", "dynamis")
	, new DataCenter("Primal", "primal"))
	; order needs to be same as in game






class RegionProto {

	__New(Name, X1, Y1, X2, Y2) {
		this.Name := Name
		this.X1 := X1
		this.Y1 := Y1
		this.X2 := X2
		this.Y2 := Y2
	}

	FullName(Suffix) {
		return this.Name . Suffix
	}

	CreateRegion(Suffix) {
		return new Region(this.FullName(Suffix), this.X1, this.Y1, this.X2, this.Y2, Images.Get(this.FullName(Suffix)))
	}
}

REGION_PROTOS := [new RegionProto("ox", 0, 600, 600, 1080)
	, new RegionProto("selectdatacenter", 600, 400, 1100, 700)
	, new RegionProto("proceed", 500, 500, 1200, 1000)
	, new RegionProto("ok", 200, 200, 1620, 800)
	, new RegionProto("traveled", 0, 0, 600, 1080)
	, new RegionProto("aether", 1000, 0, 1920, 400)
	, new RegionProto("dynamis", 1000, 0, 1920, 400)
	, new RegionProto("primal", 1000, 0, 1920, 400)
	, new RegionProto("crystal", 600, 300, 1000, 600)]

global regions = new Regions(REGION_PROTOS)

class Regions {


	__New(protos) {
		this.regions := []
		for i, proto in protos {
			for j, scale in Scales {
				this.regions[proto.FullName(scale)] := proto.CreateRegion(scale)
			}
		}
	}

	Initialize() {
		this.Scale := 0
		if (this.regions["ox10"].IsVisible()) {
			this.Scale := 10
		} else if (this.regions["ox15"].IsVisible()) {
			this.Scale := 15
		}
		return this.Scale > 0
	}

	Get(key) {
		return this.regions[key . this.Scale]
	}
}


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


class DataCenters {

	__New(DcHomeIndex, DcArray*) {
		this.DcArray := DcArray
		for i, dc in this.DcArray {
			dc.Offset := i - DcHomeIndex
		}
		this.DcHome := this.DcArray[DcHomeIndex]
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

	__New(Name, RegionName, InverseMatch := False) {
		this.Name := Name
		this.Matcher := new RegionMatcher(RegionName, InverseMatch)
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

class RegionMatcher {
	__New(RegionName, Inverse := False) {
		this.RegionName := RegionName
		this.Inverse := Inverse
	}

	Matches() {
		if (this.Inverse) {
			return !regions.get(this.RegionName).IsVisible()
		} else {
			return regions.get(this.RegionName).IsVisible()
		}
	}
}

Test(file) {
		ImageSearch,,, 0, 0, 1920, 1080, % "*100 *Trans00FF00 " . file
		if (ErrorLevel == 0) {
			return true
		} else if (ErrorLevel == 1) {
			return false
		} else {
			MsgBox % "Error: " . ErrorLevel . " " . this.hImage
		}
}

class Region {

	__New(Name, X1, Y1, X2, Y2, hImage) {
		this.Name := Name
		this.X1 := X1
		this.Y1 := Y1
		this.X2 := X2
		this.Y2 := Y2
		this.hImage := hImage
	}


	IsVisible() {
		ImageSearch,,, % this.X1, % this.Y1, % this.X2, % this.Y2, % "*80 *Trans00FF00 HBITMAP:*" . this.hImage
		if (ErrorLevel == 0) {
			return true
		} else if (ErrorLevel == 1) {
			return false
		} else {
			MsgBox % "Failed too lookup region " . this.Name . "`nError: " . ErrorLevel . " " . this.hImage
		}
	}

	AwaitUntilVisible() {
		while(!this.IsVisible()) {
			Sleep, 200
		}
	}
}
