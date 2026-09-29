; Omarchy Quattro's Display panel (omarchy.monitor) on Windows: brightness, scale and which
; monitors are on, for menu.ahk. Quattro's scripts and their counterparts here:
;   omarchy-brightness-display     -> SetBrightness: WMI for a laptop panel, DDC/CI (dxva2)
;                                     for an external monitor that supports it
;   omarchy-hyprland-monitor-scaling -> SetScale: Settings > Display > Scale, per monitor
;   hyprctl keyword monitor ,disable -> SetMonitorEnabled: Settings > Display > Disconnect
;   omarchy-monitor-state          -> WriteDisplayState: display.json for the panel
; Monitors are AHK monitor numbers (MonitorGet); a monitor that is off has none, so the
; panel names those by their DisplayConfig target ("adapter:target").

; Settings > Display's scale steps; DisplayConfig speaks in steps relative to the
; recommended one.
global DisplayScales := [100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500]

; --- DisplayConfig ---------------------------------------------------------------------
; DISPLAYCONFIG_PATH_INFO is 72 bytes: source {LUID 0, id 8, modeIdx 12, flags 16},
; target {LUID 20, id 28, modeIdx 32, tech 36, ..., available 60, flags 64}, flags 68.
; DISPLAYCONFIG_MODE_INFO is 64 bytes.

DisplayPaths(all := false) {
    flags := all ? 1 : 2                        ; QDC_ALL_PATHS : QDC_ONLY_ACTIVE_PATHS
    loop 3 {
        np := 0, nm := 0
        if DllCall("GetDisplayConfigBufferSizes", "uint", flags, "uint*", &np, "uint*", &nm)
            return 0
        paths := Buffer(np * 72, 0), modes := Buffer(nm * 64, 0)
        r := DllCall("QueryDisplayConfig", "uint", flags, "uint*", &np, "ptr", paths, "uint*", &nm, "ptr", modes, "ptr", 0)
        if r = 0
            return {paths: paths, np: np, modes: modes, nm: nm}
        if r != 122                              ; ERROR_INSUFFICIENT_BUFFER: changed, ask again
            return 0
    }
    return 0
}

; DISPLAYCONFIG_DEVICE_INFO_HEADER {type, size, LUID adapterId, id} = 20 bytes.
DeviceInfo(type, size, luidLow, luidHigh, id) {
    b := Buffer(size, 0)
    NumPut("int", type, "uint", size, "uint", luidLow, "int", luidHigh, "uint", id, b)
    return DllCall("DisplayConfigGetDeviceInfo", "ptr", b) = 0 ? b : 0
}

; The GDI name of a path's source (\\.\DISPLAY1), which is what MonitorGetName returns.
SourceGdiName(paths, i) {
    o := i * 72
    if b := DeviceInfo(1, 84, NumGet(paths, o, "uint"), NumGet(paths, o + 4, "int"), NumGet(paths, o + 8, "uint"))
        return StrGet(b.Ptr + 20, 32, "UTF-16")
    return ""
}

; The monitor's own name (EDID), e.g. "Odyssey G70B"; "" when it reports none.
TargetName(paths, i) {
    o := i * 72
    if b := DeviceInfo(2, 420, NumGet(paths, o + 20, "uint"), NumGet(paths, o + 24, "int"), NumGet(paths, o + 28, "uint"))
        return StrGet(b.Ptr + 36, 64, "UTF-16")
    return ""
}

SourceKey(paths, i) {
    o := i * 72
    return Format("{:x}.{:x}:{}", NumGet(paths, o + 4, "int"), NumGet(paths, o, "uint"), NumGet(paths, o + 8, "uint"))
}

TargetKey(paths, i) {
    o := i * 72
    return Format("{:x}.{:x}:{}", NumGet(paths, o + 24, "int"), NumGet(paths, o + 20, "uint"), NumGet(paths, o + 28, "uint"))
}

; Built into the machine: INTERNAL, or an embedded DisplayPort / UDI panel.
TargetInternal(paths, i) {
    tech := NumGet(paths, i * 72 + 36, "uint")
    return tech = 0x80000000 || tech = 11 || tech = 13
}

; The path index (in DisplayPaths()) of AHK monitor n, or -1.
PathOfMonitor(dc, n) {
    name := MonitorGetName(n)
    loop dc.np
        if SourceGdiName(dc.paths, A_Index - 1) = name
            return A_Index - 1
    return -1
}

; --- Scale ------------------------------------------------------------------------------
; DISPLAYCONFIG_DEVICE_INFO_GET_DPI_SCALE (-3): {min, cur, max} steps relative to the
; recommended scale, from the source. Returns {cur, list} in percent, or 0.
MonitorScale(dc, i) {
    global DisplayScales
    o := i * 72
    b := DeviceInfo(-3, 32, NumGet(dc.paths, o, "uint"), NumGet(dc.paths, o + 4, "int"), NumGet(dc.paths, o + 8, "uint"))
    if !b
        return 0
    lo := NumGet(b, 20, "int"), cur := NumGet(b, 24, "int"), hi := NumGet(b, 28, "int")
    rec := Abs(lo)                               ; index of the recommended step
    list := []
    loop DisplayScales.Length {
        k := A_Index - 1
        if k >= rec + lo && k <= rec + hi
            list.Push(DisplayScales[A_Index])
    }
    ci := Max(0, Min(DisplayScales.Length - 1, rec + cur))
    return {cur: DisplayScales[ci + 1], rec: DisplayScales[Min(rec, DisplayScales.Length - 1) + 1], list: list}
}

; DISPLAYCONFIG_DEVICE_INFO_SET_DPI_SCALE (-4), what Settings > Display > Scale does.
SetScale(n, pct) {
    global DisplayScales
    PerMonitorDpi()
    if !(dc := DisplayPaths()) || (i := PathOfMonitor(dc, n)) < 0
        return false
    if !(s := MonitorScale(dc, i))
        return false
    want := 0, rec := 0
    loop DisplayScales.Length {
        if DisplayScales[A_Index] = Integer(pct)
            want := A_Index
        if DisplayScales[A_Index] = s.rec
            rec := A_Index
    }
    if !want || !rec
        return false
    o := i * 72
    b := Buffer(24, 0)
    NumPut("int", -4, "uint", 24, "uint", NumGet(dc.paths, o, "uint"), "int", NumGet(dc.paths, o + 4, "int"),
        "uint", NumGet(dc.paths, o + 8, "uint"), "int", want - rec, b)
    return DllCall("DisplayConfigSetDeviceInfo", "ptr", b) = 0
}

; --- Brightness -------------------------------------------------------------------------
; Physical monitor handles behind AHK monitor n (DDC/CI). Free with FreePhysical.
PhysicalMonitors(n) {
    MonitorGet n, &l, &t
    hmon := DllCall("MonitorFromPoint", "int64", ((l + 1) & 0xFFFFFFFF) | ((t + 1) << 32), "uint", 2, "ptr")
    count := 0
    if !DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR", "ptr", hmon, "uint*", &count) || !count
        return 0
    buf := Buffer(count * (A_PtrSize + 256), 0)       ; PHYSICAL_MONITOR {HANDLE; WCHAR[128]}
    if !DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "ptr", hmon, "uint", count, "ptr", buf)
        return 0
    return {buf: buf, count: count}
}

FreePhysical(pm) {
    if pm
        DllCall("dxva2\DestroyPhysicalMonitors", "uint", pm.count, "ptr", pm.buf)
}

; VCP 0x10 is luminance (MCCS). Returns {cur, max} of the first monitor that answers.
DdcBrightness(pm) {
    loop pm.count {
        h := NumGet(pm.buf, (A_Index - 1) * (A_PtrSize + 256), "ptr")
        cur := 0, mx := 0
        if DllCall("dxva2\GetVCPFeatureAndVCPFeatureReply", "ptr", h, "uchar", 0x10, "ptr", 0, "uint*", &cur, "uint*", &mx) && mx
            return {h: h, cur: cur, max: mx}
    }
    return 0
}

; The laptop panel's brightness (WMI), or -1 without one.
WmiBrightness() {
    try {
        for m in ComObjGet("winmgmts:\\.\root\wmi").ExecQuery("SELECT CurrentBrightness FROM WmiMonitorBrightness WHERE Active=TRUE")
            return m.CurrentBrightness
    }
    return -1
}

WmiSetBrightness(pct) {
    try {
        for m in ComObjGet("winmgmts:\\.\root\wmi").ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods WHERE Active=TRUE") {
            m.WmiSetBrightness(1, pct)
            return true
        }
    }
    return false
}

; Brightness of AHK monitor n in percent, or -1 when it can't be changed from here
; (Quattro: "FIXED BRIGHTNESS").
GetBrightness(n, dc := 0) {
    if !dc
        dc := DisplayPaths()
    if dc && (i := PathOfMonitor(dc, n)) >= 0 && TargetInternal(dc.paths, i)
        return WmiBrightness()
    pm := PhysicalMonitors(n)
    if !pm
        return -1
    r := DdcBrightness(pm)
    FreePhysical(pm)
    return r ? Round(r.cur * 100 / r.max) : -1
}

; Quattro keeps 1-100: a monitor at 0 can look switched off.
SetBrightness(n, pct) {
    pct := Max(1, Min(100, Round(pct)))
    PerMonitorDpi()
    dc := DisplayPaths()
    if dc && (i := PathOfMonitor(dc, n)) >= 0 && TargetInternal(dc.paths, i)
        return WmiSetBrightness(pct) ? pct : -1
    if !(pm := PhysicalMonitors(n))
        return -1
    done := -1
    if r := DdcBrightness(pm)
        if DllCall("dxva2\SetVCPFeature", "ptr", r.h, "uchar", 0x10, "uint", Round(pct * r.max / 100))
            done := pct
    FreePhysical(pm)
    return done
}

; Scroll on the bar icon (Quattro: 5 per wheel step) plus the brightness OSD.
StepBrightness(n, delta) {
    cur := GetBrightness(n)
    if cur < 0 {
        Osd("This monitor's brightness can't be changed from here (no DDC/CI)")
        return
    }
    now := SetBrightness(n, cur + delta)
    if now >= 0
        Osd(Chr(0xF00DF) "  " now "%")
}

; --- Monitors on / off ------------------------------------------------------------------
; Turn the monitor with target key `key` (TargetKey) on or off, as Settings > Display's
; "Disconnect this display" does. The last monitor that is on stays on.
SetMonitorEnabled(key, on) {
    if !(dc := DisplayPaths(true))
        return false
    active := 0, mine := -1, spare := -1, used := Map()
    loop dc.np {
        o := (A_Index - 1) * 72
        if NumGet(dc.paths, o + 68, "uint") & 1 {
            active++
            used[SourceKey(dc.paths, A_Index - 1)] := true
            if TargetKey(dc.paths, A_Index - 1) = key
                mine := A_Index - 1
        }
    }
    ; To turn it on: a path Windows offers for it (targetAvailable) from a source no other
    ; monitor is using - a used one would mirror that monitor instead.
    loop dc.np {
        i := A_Index - 1, o := i * 72
        if spare < 0 && !(NumGet(dc.paths, o + 68, "uint") & 1) && TargetKey(dc.paths, i) = key
            && NumGet(dc.paths, o + 60, "int") && !used.Has(SourceKey(dc.paths, i))
            spare := i
    }
    if on {
        if mine >= 0
            return true
        if spare < 0
            return false
        ; A path Windows offers for it: mark it active, let Windows pick the modes.
        o := spare * 72
        NumPut("uint", NumGet(dc.paths, o + 68, "uint") | 1, dc.paths, o + 68)
        NumPut("uint", 0xFFFFFFFF, dc.paths, o + 12)
        NumPut("uint", 0xFFFFFFFF, dc.paths, o + 32)
    } else {
        if mine < 0
            return true
        if active <= 1
            return false
        o := mine * 72
        NumPut("uint", NumGet(dc.paths, o + 68, "uint") & ~1, dc.paths, o + 68)
    }
    ; Only the active paths go back, the new one with invalidated modes.
    keep := Buffer(dc.np * 72, 0), k := 0
    loop dc.np {
        o := (A_Index - 1) * 72
        if NumGet(dc.paths, o + 68, "uint") & 1 {
            DllCall("RtlMoveMemory", "ptr", keep.Ptr + k * 72, "ptr", dc.paths.Ptr + o, "uptr", 72)
            k++
        }
    }
    ; SDC_APPLY | SDC_USE_SUPPLIED_DISPLAY_CONFIG | SDC_ALLOW_CHANGES | SDC_SAVE_TO_DATABASE
    if DllCall("SetDisplayConfig", "uint", k, "ptr", keep, "uint", dc.nm, "ptr", dc.modes, "uint", 0x80 | 0x20 | 0x400 | 0x200) = 0
        return true
    ; Turning one on can still be refused (no mode Windows likes for that layout): extend
    ; the desktop to every connected monitor instead, which is what Win+P > Extend does.
    return on && DllCall("SetDisplayConfig", "uint", 0, "ptr", 0, "uint", 0, "ptr", 0, "uint", 0x80 | 0x4) = 0
}

; --- State for the panel ----------------------------------------------------------------
; display.json: every monitor (on or off) with what the panel can do with it. `focused` is
; the monitor the panel opened on (Quattro acts on the focused monitor).
WriteDisplayState(focused) {
    PerMonitorDpi()
    dc := DisplayPaths()
    all := DisplayPaths(true)
    items := [], seen := Map()
    loop MonitorGetCount() {
        n := A_Index
        i := dc ? PathOfMonitor(dc, n) : -1
        key := i >= 0 ? TargetKey(dc.paths, i) : "m" n
        seen[key] := true
        name := i >= 0 ? TargetName(dc.paths, i) : ""
        if name = ""
            name := i >= 0 && TargetInternal(dc.paths, i) ? "Built-in display" : "Display " n
        s := i >= 0 ? MonitorScale(dc, i) : 0
        b := GetBrightness(n, dc)
        MonitorGet n, &l, &t, &r, &bt
        scales := ""
        if s
            for v in s.list
                scales .= (scales = "" ? "" : ",") v
        items.Push('{"n":' n ',"key":"' key '","name":"' JsonEscape(name) '","enabled":true'
            . ',"primary":' JsonBool(n = MonitorGetPrimary()) ',"focused":' JsonBool(n = focused)
            . ',"internal":' JsonBool(i >= 0 && TargetInternal(dc.paths, i))
            . ',"width":' (r - l) ',"height":' (bt - t) ',"brightness":' b
            . ',"scale":' (s ? s.cur : 100) ',"recommended":' (s ? s.rec : 100) ',"scales":[' scales ']}')
    }
    ; Monitors that are plugged in but turned off (only their target: no GDI name, no size).
    if all {
        loop all.np {
            i := A_Index - 1
            if !NumGet(all.paths, i * 72 + 60, "int")
                continue
            key := TargetKey(all.paths, i)
            if seen.Has(key)
                continue
            seen[key] := true
            name := TargetName(all.paths, i)
            if name = ""
                continue                          ; an unused output with nothing on it
            items.Push('{"n":0,"key":"' key '","name":"' JsonEscape(name) '","enabled":false,"primary":false'
                . ',"focused":false,"internal":' JsonBool(TargetInternal(all.paths, i)) ',"brightness":-1,"scale":100,"scales":[]}')
        }
    }
    text := '{"updated":' A_TickCount ',"focused":' focused ',"monitors":['
    for it in items
        text .= (A_Index > 1 ? "," : "") it
    text .= "]}"
    WriteAtomic(Env("pack") "\display.json", text)
}

JsonBool(v) => v ? "true" : "false"

JsonEscape(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '"', '\"')
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "`r", "")
    s := StrReplace(s, "`t", " ")
    return s
}

; The bar and panels poll these files: never let them read half of one.
WriteAtomic(path, text) {
    f := FileOpen(path ".tmp", "w", "UTF-8-RAW")
    f.Write(text)
    f.Close()
    FileMove path ".tmp", path, true
}
