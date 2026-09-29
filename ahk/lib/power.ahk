; Omarchy Quattro's Power panel (omarchy.power) on Windows: the battery and Windows' power
; mode, for menu.ahk. Quattro's scripts and their counterparts here:
;   omarchy-battery-status --shell   -> WritePowerState: GetSystemPowerStatus, and WMI's
;                                       root\wmi battery classes for rate, size and cycles
;   omarchy-powerprofiles-list       -> PowerMode: the power mode overlay (Settings > Power)
;   omarchy-powerprofiles-set        -> SetPowerMode (menu.ahk)
; Needs display.ahk (JsonEscape, JsonBool, WriteAtomic) included before it.

; Windows' power modes on top of the Balanced plan. 3AF9... is Windows 10's "Better
; performance", which is its middle step, so it reads as Balanced.
PowerModeIds() => Map("saver", "{961CC777-2547-4F9D-8174-7D86181B8A7A}"
    , "balanced", "{00000000-0000-0000-0000-000000000000}"
    , "performance", "{DED574B5-45A0-4F42-8737-46345C09C238}")

; SYSTEM_POWER_STATUS: AC line, battery flag, percent, seconds left. A failed call reads as
; no battery (flag 128, percent unknown), not as an empty one.
PowerStatus() {
    ps := Buffer(12, 0)
    if !DllCall("GetSystemPowerStatus", "ptr", ps)
        return { ac: 255, flag: 128, pct: 255, secs: 0xFFFFFFFF }
    return { ac: NumGet(ps, 0, "uchar"), flag: NumGet(ps, 1, "uchar"), pct: NumGet(ps, 2, "uchar")
        , secs: NumGet(ps, 4, "uint") }
}

HasBattery() {
    s := PowerStatus()
    return !(s.flag & 128) && s.pct != 255
}

; saver / balanced / performance, or "" when Windows has no power mode to report (another
; plan than Balanced is active, which turns the modes off).
PowerMode() {
    guid := Buffer(16, 0)
    try {
        if DllCall("powrprof\PowerGetEffectiveOverlayScheme", "ptr", guid, "uint") != 0
            return ""
    } catch
        return ""
    buf := Buffer(80, 0)
    DllCall("ole32\StringFromGUID2", "ptr", guid, "ptr", buf, "int", 40)
    id := StrGet(buf, "UTF-16")
    if id = "{3AF9B8D9-7C97-431D-AD78-34A8BFEA439F}"
        return "balanced"
    for name, g in PowerModeIds()
        if id = g
            return name
    return ""
}

; "2h 15m", "2h", "40m" (omarchy-battery-status's time format).
PowerDuration(mins) {
    mins := Round(mins)
    if mins < 60
        return mins "m"
    h := mins // 60, m := Mod(mins, 60)
    return m ? h "h " m "m" : h "h"
}

; Watts with one decimal, "12.0" as "12".
PowerWatts(mw) {
    w := Format("{:.1f}", mw / 1000)
    return RegExReplace(w, "\.0$") "W"
}

; power.json: what the panel shows (Quattro's battery-status fields, plus the power mode).
WritePowerState(*) {
    s := PowerStatus()
    if (s.flag & 128) || s.pct = 255 {
        WriteAtomic(Env("pack") "\power.json", '{"updated":' A_TickCount ',"present":false,"mode":"' PowerMode() '"}')
        return
    }
    pct := s.pct, ac := s.ac = 1
    charging := (s.flag & 8) != 0
    chargeRate := 0, dischargeRate := 0, remaining := 0, full := 0, cycles := ""
    ; A laptop can have two batteries: add them up. Each class is optional (firmware
    ; leaves some out), so each gets its own try.
    wmi := ""
    try wmi := ComObjGet("winmgmts:\\.\root\wmi")
    if wmi {
        try {
            for b in wmi.ExecQuery("SELECT * FROM BatteryStatus") {
                chargeRate += Abs(Integer(b.ChargeRate))
                dischargeRate += Abs(Integer(b.DischargeRate))
                remaining += Integer(b.RemainingCapacity)
                if b.Charging
                    charging := true
            }
        }
        try {
            for b in wmi.ExecQuery("SELECT FullChargedCapacity FROM BatteryFullChargedCapacity")
                full += Integer(b.FullChargedCapacity)
        }
        try {
            for b in wmi.ExecQuery("SELECT CycleCount FROM BatteryCycleCount")
                if Integer(b.CycleCount) > 0
                    cycles := Integer(b.CycleCount)
        }
    }
    ; Quattro's states. Plugged in and not charging below full is a charge limit (a vendor's
    ; battery care setting): "holding", as Quattro's charge threshold.
    if !ac
        state := "discharging"
    else if pct >= 99
        state := "full"
    else if charging
        state := "charging"
    else
        state := "holding"
    time := ""
    if state = "discharging" {
        if s.secs != 0xFFFFFFFF && s.secs > 0
            time := PowerDuration(s.secs / 60)
        else if dischargeRate > 0 && remaining > 0
            time := PowerDuration(remaining / dischargeRate * 60)
    } else if state = "charging" && chargeRate > 0 && full > remaining
        time := PowerDuration((full - remaining) / chargeRate * 60)
    rate := state = "discharging" ? dischargeRate : state = "charging" ? chargeRate : 0
    text := '{"updated":' A_TickCount ',"present":true,"percent":' pct ',"ac":' JsonBool(ac)
        . ',"state":"' state '","rate":"' PowerWatts(rate) '","size":"' (full ? Round(full / 1000) "Wh" : "") '"'
        . ',"cycles":"' cycles '","time":"' time '","threshold":"' (state = "holding" ? pct "%" : "") '"'
        . ',"mode":"' PowerMode() '"}'
    WriteAtomic(Env("pack") "\power.json", text)
}
