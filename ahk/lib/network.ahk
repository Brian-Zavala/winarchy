; What the bar's network icon shows (network.json in the pack), read from Windows itself:
; Zebar's network provider gives nothing on some PCs, and it picks the VPN (Tailscale exit
; node) or an unplugged Wi-Fi card as "default" on others.
;   {"type":"ethernet","name":"Ethernet"}
;   {"type":"wifi","ssid":"Home","signal":72}
;   {"type":"none"}
; A wired link wins over Wi-Fi, as Windows' own metrics do.

NetworkRefresh() {
    static last := ""
    kind := "none", name := ""
    try {
        wired := "", wifi := ""
        for a in ComObjGet("winmgmts:").ExecQuery("SELECT Name,NetConnectionID,AdapterType,PhysicalAdapter FROM Win32_NetworkAdapter WHERE NetConnectionStatus=2") {
            id := a.NetConnectionID " " a.Name
            if a.PhysicalAdapter != -1 && a.PhysicalAdapter != 1 || id ~= "i)tailscale|bluetooth|virtual|vethernet|vmware|hyper-v|wsl|loopback|tap-|wireguard|openvpn"
                continue
            if id ~= "i)wi-?fi|wireless|802\.11|wlan"
                wifi := a.NetConnectionID
            else if a.AdapterType ~= "i)ethernet"
                wired := wired != "" ? wired : a.NetConnectionID
        }
        if wired != ""
            kind := "ethernet", name := wired
        else if wifi != ""
            kind := "wifi", name := wifi
    }
    json := '{"type":"' kind '"'
    if kind = "ethernet"
        json .= ',"name":"' StrReplace(name, '"', "") '"'
    else if kind = "wifi" {
        ssid := "", signal := 0
        try {
            out := ""
            tmp := A_Temp "\winarchy-wlan.txt"
            RunWait A_ComSpec ' /c netsh wlan show interfaces > "' tmp '" 2>nul', , "Hide"
            out := FileRead(tmp, "CP0")
            FileDelete tmp
            if RegExMatch(out, "m)^\s*SSID\s*:\s*(.+?)\s*$", &m)
                ssid := m[1]
            if RegExMatch(out, "m)^\s*Signal\s*:\s*(\d+)%", &m)
                signal := Integer(m[1])
        }
        json .= ',"ssid":"' StrReplace(StrReplace(ssid, "\", "\\"), '"', '\"') '","signal":' signal
    }
    json .= "}"
    if json = last
        return
    pack := Env("pack")
    tmp := pack "\network.json.tmp"
    f := FileOpen(tmp, "w", "UTF-8-RAW")
    f.Write(json)
    f.Close()
    FileMove tmp, pack "\network.json", true
    last := json
}
