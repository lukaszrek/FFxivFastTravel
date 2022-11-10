
global version := ReadVersion()
global optionsImageMatchingSensitivitySlider := 0
global optionsImageMatchingSensitivityText := 0
global optionsImageMatchingSensitivityWarning := 0

global settings = new CSettings()

InitializeMenu()
InitializeOptionsGui()

ReadVersion() {
	file := FileOpen(".version", "r")
	v := Trim(file.ReadLine())
	file.Close()
	if (v == "${VERSION}") {
		return "UNKNOWN"
	} else {
		return v
	}
}

InitializeMenu() {
	VersionText := "FastTraval v" . version,
	Menu, Tray, NoStandard
	Menu, Tray, Add, %VersionText%, NoOp
	Menu, Tray, Disable, 1&
	Menu, Tray, Add
	Menu, Tray, Add, Options, Options
	Menu, Tray, Add
	Menu, Tray, Add, Exit, Exit
}

InitializeOptionsGui() {
	Gui, Options:New, -SysMenu ToolWindow , FastTravel Options

	; ImageMatchingSensitivity
	Gui, Options:Add, Text, xm, Controls how sensitive screen matching is.`nIncrease when script does not work or does not send intputs during operations.`nDecrease when script does not wait long enough and sends input too early
	; newline
	Gui, Options:Add, Text,, Image comparison sensitivity
	Gui, Options:Add, Slider
		, cRed AltSubmit gOptionsImageMatchingSensitivitySliderAction voptionsImageMatchingSensitivitySlider Range0-255 x+3
		, 0
	Gui, Options:Add, Edit, voptionsImageMatchingSensitivityText Disabled x+3 w35, 0
	; newline
	Gui, Options:Add, Text, xm w320 cRed voptionsImageMatchingSensitivityWarning,

	; Buttons
	Gui, Options:Add, Button, gOptionsSave xm y+10, Save
	Gui, Options:Add, Button, gOptionsCancel x+10, Cancel


}

; Tray actions
Exit() {
	ExitApp
}

Options() {
	Gui, Options:Show
	settings.CommitToGui()
}

; Options actions
OptionsImageMatchingSensitivitySliderAction() {
	GuiControl, Options:Text, optionsImageMatchingSensitivityText, %optionsImageMatchingSensitivitySlider%
	if (optionsImageMatchingSensitivitySlider < 60) {
			GuiControl, Options:Text, optionsImageMatchingSensitivityWarning, Sensitivity is very low, script may not work properly
	} else if (optionsImageMatchingSensitivitySlider > 200) {
			GuiControl, Options:Text, optionsImageMatchingSensitivityWarning, Sensitivity is very high, script may not work properly
	} else {
			GuiControl, Options:Text, optionsImageMatchingSensitivityWarning,
	}
}

OptionsSave() {
	Gui Options:Submit
	settings.CommitFromGui()
}

OptionsCancel() {
	Gui Options:Hide
}


class CSettings {

	__New() {
		this.Path :=  A_AppData . "\FFxivFastTravel"
		this.FileName := this.Path . "\settings.ini"
		this.ImageMappingSensitivity := 130
		this.Load()
	}

	Load() {
		ImageMappingSensitivity := this.ImageMappingSensitivity
		IniRead, ImageMappingSensitivity, % this.FileName, General, ImageMappingSensitivity, % ImageMappingSensitivity
		this.ImageMappingSensitivity := ImageMappingSensitivity
	}

	Save() {
		if (!FileExist(this.Path)) {
			FileCreateDir, % this.Path
		}
		IniWrite, % this.ImageMappingSensitivity, % this.FileName, General, ImageMappingSensitivity
	}

	CommitFromGui() {
		this.ImageMappingSensitivity := optionsImageMatchingSensitivitySlider
		this.Save()
	}

	CommitToGui() {
		GuiControl, Options:,optionsImageMatchingSensitivitySlider, % this.ImageMappingSensitivity
		Gui Options:Submit, NoHide
		OptionsImageMatchingSensitivitySliderAction()
	}
}


NoOp() {
}