; What the bar's network icon shows (network.json in the pack), read from Windows itself:
; Zebar's network provider gives nothing on some PCs, and it picks the VPN (Tailscale exit
; node) or an unplugged Wi-Fi card as "default" on others.
;   {"type":"ethernet","name":"Ethernet"}
;   {"type":"wifi","ssid":"Home","signal":72}
;   {"type":"none"}
; A wired link wins over Wi-Fi, as Windows' own metrics do.

#DllLoad "iphlpapi.dll"
#DllLoad "*i wlanapi.dll"             ; kept loaded: WlanCurrent keeps its handle between calls

NetworkRefresh() {
    static last := ""
    kind := "none", name := ""
    ; Read straight from the IP helper: this runs every 10 s inside winarchy.ahk, where a WMI
    ; query (Win32_NetworkAdapter is a slow one) or waiting on netsh held up every key.
    try {
        wired := "", wifi := ""
        for a in NetAdapters() {
            ; Up, and an Ethernet (6) or Wi-Fi (71) interface: tunnels, loopback and the
            ; like have types of their own; virtual Ethernet adapters go by name.
            if !a.up || (a.type != 6 && a.type != 71)
                continue
            id := a.name " " a.desc
            if id ~= "i)tailscale|bluetooth|virtual|vethernet|vmware|hyper-v|wsl|loopback|tap-|wireguard|openvpn"
                continue
            if a.type = 71 || id ~= "i)wi-?fi|wireless|802\.11|wlan"
                wifi := wifi != "" ? wifi : a.name
            else
                wired := wired != "" ? wired : a.name
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
        if w := WlanCurrent()
            ssid := w.ssid, signal := w.signal
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

; Every network adapter as {name, desc, type, up}: GetAdaptersAddresses without the address
; lists (only names, type and state are read). IP_ADAPTER_ADDRESSES_LH, P = pointer size:
; Next 8, Description 8+7P, FriendlyName 8+8P, IfType 28+9P, OperStatus 32+9P.
NetAdapters() {
    ptrSize := A_PtrSize, size := 16384, r := 0, list := []
    loop 3 {
        buf := Buffer(size)
        ; AF_UNSPEC; GAA_FLAG_SKIP_UNICAST | ANYCAST | MULTICAST | DNS_SERVER
        r := DllCall("iphlpapi\GetAdaptersAddresses", "uint", 0, "uint", 0xF, "ptr", 0, "ptr", buf, "uint*", &size, "uint")
        if r != 111                       ; ERROR_BUFFER_OVERFLOW: size now says how much
            break
    }
    if r != 0
        return list
    p := buf.Ptr
    while p {                             ; up: OperStatus = IfOperStatusUp
        list.Push({type: NumGet(p, 28 + 9 * ptrSize, "uint"), up: NumGet(p, 32 + 9 * ptrSize, "int") = 1
            , name: StrGet(NumGet(p, 8 + 8 * ptrSize, "ptr"), "UTF-16"), desc: StrGet(NumGet(p, 8 + 7 * ptrSize, "ptr"), "UTF-16")})
        p := NumGet(p, 8, "ptr")
    }
    return list
}

; {ssid, signal} of the connected Wi-Fi interface, or 0: the WLAN API that netsh reads
; (netsh cost a hidden cmd, a netsh and a temp file every 10 s).
WlanCurrent() {
    static h := 0
    try {
        if !h {
            if DllCall("wlanapi\WlanOpenHandle", "uint", 2, "ptr", 0, "uint*", &ver := 0, "ptr*", &h, "uint")
                return (h := 0)
        }
        if DllCall("wlanapi\WlanEnumInterfaces", "ptr", h, "ptr", 0, "ptr*", &ifs := 0, "uint") {
            DllCall("wlanapi\WlanCloseHandle", "ptr", h, "ptr", 0), h := 0     ; the service restarted: reopen next time
            return 0
        }
        out := 0
        loop NumGet(ifs, 0, "uint") {
            ; WLAN_INTERFACE_INFO (532 bytes, from 8): GUID, WCHAR[256], isState at 528
            info := ifs + 8 + (A_Index - 1) * 532
            if NumGet(info, 528, "uint") != 1                     ; wlan_interface_state_connected
                continue
            ; wlan_intf_opcode_current_connection -> WLAN_CONNECTION_ATTRIBUTES:
            ; dot11Ssid {uSSIDLength at 520, ucSSID[32] at 524}, wlanSignalQuality (0-100) at 576
            if !DllCall("wlanapi\WlanQueryInterface", "ptr", h, "ptr", info, "uint", 7, "ptr", 0, "uint*", &n := 0, "ptr*", &data := 0, "ptr", 0, "uint") {
                ssid := Buffer(33, 0)
                DllCall("RtlMoveMemory", "ptr", ssid, "ptr", data + 524, "uptr", Min(NumGet(data, 520, "uint"), 32))
                out := {ssid: StrGet(ssid, "UTF-8"), signal: NumGet(data, 576, "uint")}
                DllCall("wlanapi\WlanFreeMemory", "ptr", data)
                break
            }
        }
        DllCall("wlanapi\WlanFreeMemory", "ptr", ifs)
        return out
    }
    return 0
}
