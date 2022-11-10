


regionProtos := [new RegionProto("ox", 0, 600, 600, 1080)
	, new RegionProto("selectdatacenter", 600, 400, 1100, 700)
	, new RegionProto("proceed", 500, 500, 1200, 1000)
	, new RegionProto("ok", 200, 200, 1620, 800)
	, new RegionProto("traveled", 0, 0, 600, 1080)
	, new RegionProto("aether", 1000, 0, 1920, 400)
	, new RegionProto("dynamis", 1000, 0, 1920, 400)
	, new RegionProto("primal", 1000, 0, 1920, 400)
	, new RegionProto("crystal", 600, 300, 1000, 600)]

global regions := new CRegions(regionProtos)


class RegionProto {

	__New(name, x1, y1, x2, y2) {
		this.Name := name
		this.X1 := x1
		this.Y1 := y1
		this.X2 := x2
		this.Y2 := y2
	}

	FullName(suffix) {
		return this.Name . suffix
	}

	CreateRegion(suffix) {
		return new Region(this.FullName(suffix), this.x1, this.y1, this.x2, this.y2, images.Get(this.FullName(suffix)))
	}
}


class CRegions {

	__New(protos) {
		this.Regions := []
		for i, proto in protos {
			for j, scale in Scales {
				this.Regions[proto.FullName(scale)] := proto.CreateRegion(scale)
			}
		}
	}

	Initialize() {
		this.Scale := 0
		if (this.Regions["ox10"].IsVisible()) {
			this.Scale := 10
		} else if (this.Regions["ox15"].IsVisible()) {
			this.Scale := 15
		}
		return this.Scale > 0
	}

	Get(key) {
		return this.Regions[key . this.Scale]
	}
}


class RegionMatcher {
	__New(regionName, inverse := False) {
		this.RegionName := regionName
		this.Inverse := inverse
	}

	Matches() {
		if (this.Inverse) {
			return !regions.get(this.RegionName).IsVisible()
		} else {
			return regions.get(this.RegionName).IsVisible()
		}
	}
}

class Region {

	__New(name, x1, y1, x2, y2, hImage) {
		this.Name := name
		this.X1 := x1
		this.Y1 := y1
		this.X2 := x2
		this.Y2 := y2
		this.hImage := hImage
	}


	IsVisible() {
		ImageSearch,,, % this.X1, % this.Y1, % this.X2, % this.Y2, % "*" . settings.ImageMappingSensitivity . " *Trans00FF00 HBITMAP:*" . this.hImage
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
