;@Ahk2Exe-let AetherPng = , AetherI = 1


;@Ahk2Exe-AddResource images/Aether.png, 1
;@Ahk2Exe-AddResource images/Crystal.png, #2
;@Ahk2Exe-AddResource images/Dynamis.png, #3
;@Ahk2Exe-AddResource images/OK.png, #4
;@Ahk2Exe-AddResource images/ox.png, #5
;@Ahk2Exe-AddResource images/Primal.png, #6
;@Ahk2Exe-AddResource images/Proceed.png, #7
;@Ahk2Exe-AddResource images/SelectDataCenter.png, #8
;@Ahk2Exe-AddResource images/TraveledFrom.png, #9


_Descriptors := [new ImgDsc("aether", "images/Aether.png", 1)
		, new ImgDsc("crystal", "images/Crystal.png", 2)
		, new ImgDsc("dynamis", "images/Dynamis.png", 3)
		, new ImgDsc("ok", "images/OK.png", 4)
        , new ImgDsc("ox", "images/ox.png", 5)
		, new ImgDsc("primal", "images/Primal.png", 6)
		, new ImgDsc("proceed", "images/Proceed.png", 7)
		, new ImgDsc("selectdatacenter", "images/SelectDataCenter.png", 8)
		, new ImgDsc("traveledfrom", "images/TraveledFrom.png", 9)]

if A_IsCompiled {
	global Images := new CompiledImages(_Descriptors)
} else {
	global Images := new ScriptImages(_Descriptors)
}


class ImgDsc {

	__New(Name, Path, Index) {
			this.Name := Name
			this.Path := Path
			this.Index := Index
	}

	LoadFromFile() {
		return LoadPicture(this.Path)
	}

	LoadFromResource(hModule) {
		return LoadImageFromDll(hModule, this.Index)
	}
}

class ImagesBase {

	__Get(key) {
		return this.Imgs[key]
	}
}

class ScriptImages extends ImagesBase {
	__New(Dscs) {
		this.Imgs := []
		for indx, dsc in Dscs {
			this.Imgs[dsc.Name] := dsc.LoadFromFile()
		}
	}
}

class CompiledImages extends ImagesBase {

	__New(Dscs) {
		this.Imgs := []
	    GdiStartup()
		hModule := DllCall("GetModuleHandle", "Str", A_ScriptFullPath, "Ptr")
		for indx, dsc in Dscs {
			this.Imgs[dsc.Name] := dsc.LoadFromResource(hModule)
		}
	}
}


GdiStartup() {
	VarSetCapacity(si, 16, 0), si := Chr(1)
	pToken := 0
	DllCall("gdiplus\GdiplusStartup", "uint*", pToken, "uint", &si, "uint", 0)
}

LoadImageFromDll(hModule, Value) {
	hResourceInfo := DllCall("FindResource", "Ptr", hModule, "Int", Value, "Int", 10, "Ptr")
	size := DllCall("SizeofResource", "Ptr", hModule, "Ptr", hResourceInfo, "UInt")
	hResource := DllCall("LoadResource", "Ptr", hModule, "Ptr", hResourceInfo, "Ptr")
	pBytes := DllCall("LockResource", "Ptr", hResource, "Ptr")
	stream := DllCall("Shlwapi\SHCreateMemStream", "Ptr", pBytes, "UInt", size, "Ptr")

	result := DllCall("gdiplus\GdipCreateBitmapFromStream", "Ptr", stream, "Ptr*", pBitmap, "Int")
	result := DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "Int", 0, "Int")
	return hBitmap
}