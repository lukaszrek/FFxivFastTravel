


global MAGIC_PACKET_SIZE := 342
global WORLDLIST_PACKET_SIZE := 594
global LONG_PACKET_SIZE := 150

global GLOBAL_HOST := new IpAddr(124, 150, 157, 190)

global AETHER_HOST := new IpAddr(204, 2, 229, 9)
global CRYSTAL_HOST := new IpAddr(204, 2, 229, 11)
global DYNAMIS_HOST := new IpAddr(204, 2, 229, 137)
global PRIMAL_HOST := new IpAddr(204, 2, 229, 10)

global MAX_KEEP_ALIVE_DELAY = 30*1000
global DATA_CENTER_CONNECTION_BUFFER = 3*1000

CreateDetector(areas) {
	static detector
	detector := new CDetector(areas)
	SetTimer, PcapDispatch, 500
	return detector

	PcapDispatch:
	detector.Dispatch()
	return
}

class IpAddr {

	__New(a, b, c, d) {
		this.addr := [a, b, c, d]
	}

	Str() {
		str := ""
		for i, part in this.addr {
			if (str != "") {
				str := str . "."
			}
			str := str . part
		}
		return str
	}

	Int() {
		val := 0
		for i, part in this.addr {
			val := val + (part << ((i-1)*8))
		}
		return val
	}

}


class CArea {

	__New(name, addr) {
		this.Name := name
		this.Addr := addr
		this.LastSeen := 0
	}

	Update() {
		this.LastSeen := A_TickCount
	}
}


class CDetector {

	__New(areas) {
		this.areas := areas
		filter := "src host " . GLOBAL_HOST.Str()
		for i, area in this.areas {
			filter := filter . " or src host " . area.Addr.Str()
		}

		pcap_init()
		this.pcaps := pcap_findalldevs().open_all()
		this.pcaps.set_filter(filter)
	}

	Dispatch() {
		start := A_TickCount
		i := 0
		while ((packet := this.pcaps.next()) != 0) {
			this.Apply(packet)
			i++
		}

		time := (A_TickCount - start) / 1000
	;	travelLog.Debug("Dispatch " . time . "s items: " . i)
	}

	WaitForTravelConfirmationMenu() {
		this.MagicSizePacket := 0
		while(!this.MagicSizePacket) {
			Sleep, 1000
		}
	}

	WaitForTravelFinish() {
		this.MagicSizePacket := 0
		while(!this.MagicSizePacket) {
			Sleep, 1000
		}
	}

	WaitForSelectWorld() {
		this.WorldlistPacket := 0
		while(!this.WorldlistPacket) {
			Sleep, 1000
		}
	}

	WaitForConnectingToDataCenter() {
		this.LongPackets := -1
		while(this.LongPackets == -1 || this.LongPackets + DATA_CENTER_CONNECTION_BUFFER > A_TickCount) {
			Sleep, 1000
		}
	}

	Apply(packet) {
		; travelLog.Debug("Packet " . packet.GetLen())
		if (packet.GetLen() == MAGIC_PACKET_SIZE) {
			this.MagicSizePacket := 1
		} else if (packet.GetLen() == WORLDLIST_PACKET_SIZE) {
			this.WorldlistPacket := 1
		} else if (packet.GetLen() > LONG_PACKET_SIZE) {
			this.LongPackets := A_TickCount
		}

		for i, area in this.areas {
			addr := packet.GetSrcIpAddress()
			if (addr == area.Addr.Int()) {
				area.Update()
				travelLog.Debug("On " + area.Name)
			}
		}
	}

	GetCurrentArea() {
		lastSeen := 0

		for i, area in this.areas {
			if (!lastSeen || lastSeen.LastSeen < area.LastSeen) {
				lastSeen := area
			}
		}

		if (lastSeen.LastSeen > A_TickCount - MAX_KEEP_ALIVE_DELAY) {
			return lastSeen
		}
	}
}
