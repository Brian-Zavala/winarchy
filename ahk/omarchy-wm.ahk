#Requires AutoHotkey v2.0
#SingleInstance Force
#Include lib\env.ahk

; Omarchy extras that GlazeWM can't do itself: the bar's screen space, menus,
; toggles, panels, capture, drag, clipboard and utility keys.
; Window management binds live in ~/.glzr/glazewm/config.yaml (generated).
; Menus/pickers are the Zebar "menu" widget, opened through menu.ahk.
; Everything machine-specific comes from `omarchy-win apply` (lib\env.ahk).
; Undo everything: omarchy-win uninstall

GlazeCli := Env("glazewmCli")
Zebar := Env("zebar")
Pack := Env("pack")
BarTitle := "Zebar - omarchy / bar ahk_exe zebar.exe"

BarEnabled := true
Awake := false
OsdGui := 0
Transparent := Map()
Reserved := Map()      ; monitor index -> true while its work area holds the bar
PanelSeen := Map()     ; quick panel kind -> tick it was last seen open
MonitorCount := MonitorGetCount()

; No Windows taskbar at all (Omarchy has only the top bar). Auto-hide alone
; still pops it up at the bottom edge, so keep the taskbar windows hidden
; while GlazeWM runs; they come back if GlazeWM is gone or this script exits.
HideTaskbars() {
    static missingSince := 0
    if Env("hideTaskbar", "1") != "1"
        return
    ; Never leave the desktop with no taskbar and no tiling: GlazeWM gone for 10 s
    ; (crashed or quit) -> show the taskbars until it is back.
    if !ProcessExist("glazewm.exe") {
        missingSince := missingSince || A_TickCount
        if A_TickCount - missingSince > 10000 {
            ShowTaskbars()
            return
        }
    } else
        missingSince := 0
    for cls in ["Shell_TrayWnd", "Shell_SecondaryTrayWnd"]
        for hwnd in WinGetList("ahk_class " cls)
            WinHide hwnd
}
ShowTaskbars(*) {
    DetectHiddenWindows true
    for cls in ["Shell_TrayWnd", "Shell_SecondaryTrayWnd"]
        for hwnd in WinGetList("ahk_class " cls)
            WinShow hwnd
}
HideTaskbars()
SetTimer HideTaskbars, 1000
OnExit ShowTaskbars

; --- Robustness -------------------------------------------------------------
; Keep the bar's strip out of every monitor's work area. Zebar's own appbar
; reservation (dockToEdge) doesn't hold with the taskbar hidden, so it is set
; here from each bar's real height (any DPI, any number of monitors) and put back
; whenever Explorer resets it. GlazeWM tiles inside the work area, and maximized
; windows respect it too.
SetTimer ReserveBarSpace, 1000
OnMessage 0x001A, OnSettingChange                             ; WM_SETTINGCHANGE
OnExit ReleaseBarSpace
; The bar stays above windows, except a fullscreen one on its monitor.
SetTimer FullscreenWatch, 400
; Bring the bar back if Zebar dies or a monitor lost its bar; reopen the bars
; after Explorer restarts or the display layout changes (monitor wake, dock).
SetTimer BarGuard, 5000
OnMessage DllCall("RegisterWindowMessage", "Str", "TaskbarCreated", "UInt"), (*) => SetTimer(RestartBar, -3000)
OnMessage 0x007E, (*) => SetTimer(OnDisplayChange, -3000)    ; WM_DISPLAYCHANGE
; Commands from menu.ahk (menu widget actions that need this script's state).
OnMessage 0x5555, OnMenuCommand
WriteIndicators()
SetTimer WriteIndicators, 5000     ; nightlight / do-not-disturb also change from Quick Settings
; Weather for the bar (every 15 min) and the update indicator (2 min after start, then 6 h).
if Env("weather", "1") = "1" {
    SetTimer () => OmarchyCmd("weather"), -20000
    SetTimer () => OmarchyCmd("weather"), 900000
}
SetTimer () => OmarchyCmd("update-check"), -120000
SetTimer () => OmarchyCmd("update-check"), 21600000
; Bluetooth on/off for the bar icon (bluetooth.ps1 writes bluetooth.json).
SetTimer BluetoothStatus, 30000
BluetoothStatus()
; Pick up new favorite backgrounds after login settles (local only, no downloads).
if Env("syncAtLogin", "1") = "1"
    SetTimer () => OmarchyCmd("sync", "-Offline"), -90000
; Project app launchers (Super+Return terminal, ...) unless you use your own.
if Env("launchers", "1") = "1"
    try Run('"' A_AhkPath '" "' A_ScriptDir '\launchers.ahk"')

; --- Screensaver (Omarchy: effects after 2.5 min idle; any input ends it) -----
SsFlag := Env("data") "\generated\screensaver-off"
SsActive := false, SsStart := 0, SsIdleBase := 0
SsEnabled := Env("screensaver", "0") = "1" && !FileExist(SsFlag)
SystemCursor(true)            ; in case a previous run died with the cursor hidden
OnExit ScreensaverStop
if Env("screensaver", "0") = "1"
    SetTimer ScreensaverIdle, 5000

ScreensaverIdle() {
    global SsActive, SsEnabled
    if SsActive || !SsEnabled || A_TimeIdlePhysical < Env("screensaverIdle", 150) * 1000
        return
    ; Not while something keeps the display on (video, presentation, Stay Awake),
    ; the session is locked, or a fullscreen app is in front.
    if DisplayRequired() || !InputDesktopActive()
        return
    PerMonitorDpi()
    if (fg := WinExist("A")) && IsFullscreenWindow(fg)
        return
    ScreensaverStart()
}

ScreensaverStart() {
    global SsActive, SsStart, SsIdleBase
    if SsActive
        return
    SsActive := true, SsStart := A_TickCount, SsIdleBase := A_TimeIdlePhysical
    PerMonitorDpi()
    loop MonitorGetCount() {
        MonitorGet A_Index, &l, &t
        try Run('wt.exe -w new --pos ' (l + 40) ',' (t + 40) ' --fullscreen -p "' Env("screensaverProfile", "Omarchy Screensaver") '"', , "Hide")
    }
    SystemCursor(false)
    SetTimer ScreensaverWatch, 100
}

ScreensaverWatch() {
    global SsStart, SsIdleBase
    elapsed := A_TickCount - SsStart
    if elapsed < 1500
        return
    ; Physical input since the start resets the idle counter. Also stop if the
    ; windows are gone (a key press inside one ends its script).
    if A_TimeIdlePhysical + 300 < SsIdleBase + elapsed
        || (elapsed > 8000 && !WinExist("Omarchy Screensaver ahk_exe WindowsTerminal.exe"))
        ScreensaverStop()
}

ScreensaverStop(*) {
    global SsActive
    if !SsActive
        return
    SsActive := false
    SetTimer ScreensaverWatch, 0
    for hwnd in WinGetList("Omarchy Screensaver ahk_exe WindowsTerminal.exe")
        try PostMessage 0x10, 0, 0, , hwnd
    SystemCursor(true)
}

ToggleScreensaver() {
    global SsEnabled, SsFlag
    SsEnabled := !SsEnabled
    if SsEnabled {
        try FileDelete SsFlag
    } else {
        try FileAppend "", SsFlag
    }
    Osd("Screensaver " (SsEnabled ? "on" : "off"))
}

; --- Nightlight (Windows Night light; Omarchy: hyprsunset) ----------------------
; State lives in a CloudStore blob: byte 18 is 0x15 when on / 0x13 when off, "on"
; carries two extra bytes (10 00) at 23, and bytes 10-14 hold a varint unix time that
; must move forward for Windows to pick the change up.
NightlightKey() => "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate"

NightlightBytes() {
    try hex := RegRead(NightlightKey(), "Data")
    catch
        return 0
    b := []
    loop StrLen(hex) // 2
        b.Push(Integer("0x" SubStr(hex, 2 * A_Index - 1, 2)))
    ; Only touch the layout we know (header 43 42 01 00, state 13/15).
    if b.Length < 30 || b[1] != 0x43 || b[2] != 0x42 || (b[19] != 0x13 && b[19] != 0x15)
        return 0
    return b
}

NightlightOn() {
    b := NightlightBytes()
    return b ? b[19] = 0x15 : false
}

ToggleNightlight() {
    if !(b := NightlightBytes()) {
        Run "ms-settings:nightlight"      ; unknown layout: let Settings do it
        return
    }
    on := b[19] = 0x15
    if on {
        b[19] := 0x13
        if b[24] = 0x10 && b[25] = 0x00
            b.RemoveAt(24, 2)
    } else {
        b[19] := 0x15
        b.InsertAt(24, 0x10, 0x00)
    }
    t := DateDiff(A_NowUTC, "19700101000000", "Seconds")
    loop 5 {
        v := t & 0x7F, t >>= 7
        b[10 + A_Index] := A_Index < 5 ? v | 0x80 : v
    }
    hex := ""
    for x in b
        hex .= Format("{:02X}", x)
    RegWrite hex, "REG_BINARY", NightlightKey(), "Data"
    Osd("Nightlight " (on ? "off" : "on"))
    SetTimer WriteIndicators, -300
}

; --- Do not disturb (Omarchy: notification silencing) ---------------------------
; Windows keeps the active "quiet hours" profile in a WNF state: 0 = off (all
; notifications), 1 = priority only, 2 = alarms only (also set by Windows' own
; automatic rules, e.g. during fullscreen apps).
DndProfile() {
    static name := 0x0D83063EA3BF1C75
    n := name, buf := Buffer(4, 0), size := 4, stamp := 0
    if DllCall("ntdll\NtQueryWnfStateData", "int64*", &n, "ptr", 0, "ptr", 0, "uint*", &stamp, "ptr", buf, "uint*", &size) != 0
        return -1
    return NumGet(buf, 0, "uint")
}

ToggleDnd() {
    static name := 0x0D83063EA3BF1C75
    cur := DndProfile()
    if cur < 0 {
        Run "ms-settings:notifications"
        return
    }
    buf := Buffer(4, 0)
    NumPut "uint", cur ? 0 : 1, buf
    n := name
    DllCall("ntdll\NtUpdateWnfStateData", "int64*", &n, "ptr", buf, "uint", 4, "ptr", 0, "ptr", 0, "uint", 0, "uint", 0)
    Sleep 150
    now := DndProfile()
    if (now != 0) = (cur != 0) {
        Run "ms-settings:notifications"   ; Windows didn't take it: open the setting
        return
    }
    Osd("Do not disturb " (now ? "on" : "off"))
    SetTimer WriteIndicators, -100
}

; --- Text capture (OCR): snip a region, its text lands on the clipboard ----------
CaptureText() {
    static busy := false
    if busy
        return
    busy := true
    flag := Env("data") "\generated\ocr.flag"
    ; The screenshot watcher (if on) skips re-copying the snip while this flag is fresh.
    try FileDelete flag
    FileAppend "", flag
    seq := DllCall("GetClipboardSequenceNumber")
    Send "#+s"
    start := A_TickCount
    got := false
    while A_TickCount - start < 30000 {
        Sleep 150
        if DllCall("GetClipboardSequenceNumber") != seq && DllCall("IsClipboardFormatAvailable", "uint", 2) {
            got := true
            break
        }
    }
    if got {
        FileSetTime A_Now, flag
        out := Env("data") "\generated\ocr.out"
        try FileDelete out
        RunWait('"' Env("powershell", "powershell.exe") '" -NoProfile -STA -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' Env("code") '\ps51\ocr.ps1" -Out "' out '"', , "Hide")
        n := 0
        try n := Integer(Trim(FileRead(out)))
        Osd(n > 0 ? "Copied " n " line" (n = 1 ? "" : "s") " of text" : "No text found")
    }
    busy := false
}

; --- Info popups (Omarchy: Super+Ctrl+Alt+T/B/W) ----------------------------------
ShowTime() => Osd(FormatTime(, "dddd d MMMM  ") FormatTime(, Is24h() ? "HH:mm" : "h:mm tt"))
Is24h() {
    try return InStr(RegRead("HKCU\Control Panel\International", "sShortTime"), "H", true) > 0
    return false
}
ShowBattery() {
    ps := Buffer(12, 0)
    DllCall("GetSystemPowerStatus", "ptr", ps)
    flag := NumGet(ps, 1, "uchar"), pct := NumGet(ps, 2, "uchar"), ac := NumGet(ps, 0, "uchar")
    if flag = 128 || pct = 255
        Osd("No battery (plugged in)")
    else
        Osd("Battery " pct "%" (ac = 1 ? " (charging)" : ""))
}
ShowWeather() {
    try {
        json := FileRead(Env("pack") "\weather.json", "UTF-8")
        if RegExMatch(json, '"text":\s*"([^"]*)"', &m) {
            Osd(m[1])
            return
        }
    }
    Osd("No weather yet")
    OmarchyCmd("weather")
}

; --- Activity (Omarchy: btop) -------------------------------------------------------
Activity() {
    btop := Env("btop")
    if btop && FileExist(btop)
        Run 'wt.exe -w new --title Activity "' btop '"'
    else
        Run "taskmgr.exe"
}

; Any app asking to keep the display on (ES_DISPLAY_REQUIRED in the system state).
DisplayRequired() {
    state := 0
    DllCall("PowrProf\CallNtPowerInformation", "int", 16, "ptr", 0, "uint", 0, "uint*", &state, "uint", 4)
    return state & 0x2
}

; False while the lock screen / a secure desktop is up.
InputDesktopActive() {
    if h := DllCall("OpenInputDesktop", "uint", 0, "int", 0, "uint", 0x100, "ptr") {
        DllCall("CloseDesktop", "ptr", h)
        return true
    }
    return false
}

; Hide the pointer (blank system cursors) / bring the real ones back.
SystemCursor(show) {
    static ids := [32512, 32513, 32514, 32515, 32516, 32642, 32643, 32644, 32645, 32646, 32648, 32649, 32650, 32651]
    if show {
        DllCall("SystemParametersInfo", "uint", 0x57, "uint", 0, "ptr", 0, "uint", 0)   ; SPI_SETCURSORS
        return
    }
    andMask := Buffer(128, 0xFF), xorMask := Buffer(128, 0)
    for id in ids {
        blank := DllCall("CreateCursor", "ptr", 0, "int", 0, "int", 0, "int", 32, "int", 32, "ptr", andMask, "ptr", xorMask, "ptr")
        DllCall("SetSystemCursor", "ptr", blank, "uint", id)
    }
}

BarGuard() {
    global BarEnabled, Zebar
    static lastRestart := 0
    if !BarEnabled
        return
    if !ProcessExist("zebar.exe") {
        try Run('"' Zebar '" startup', , "Hide")
        return
    }
    if BarWindows().Count < MonitorGetCount() && A_TickCount - lastRestart > 20000 {
        lastRestart := A_TickCount
        RestartBar()
    }
}

RestartBar() {
    global BarEnabled, Zebar
    HideTaskbars()
    if !BarEnabled
        return
    CloseBar()
    try Run('"' Zebar '" startup', , "Hide")
    SetTimer ReserveBarSpace, -2000
    SetTimer () => Glaze("wm-redraw"), -2500
}

; A monitor was added or removed (laptop dock/undock): re-split the workspaces.
OnDisplayChange() {
    global MonitorCount
    if MonitorGetCount() != MonitorCount {
        MonitorCount := MonitorGetCount()
        OmarchyCmd("apply", "-MonitorsOnly")
    }
    RestartBar()
}

; Close just the bar windows; Zebar itself keeps running for the menu widget.
; WM_CLOSE is posted because WinClose can stall on these webview windows.
CloseBar() {
    global BarTitle
    for hwnd in WinGetList(BarTitle)
        try PostMessage 0x10, 0, 0, , hwnd
    loop 20 {
        if !WinExist(BarTitle)
            break
        Sleep 100
    }
}

; {monitor index: {hwnd, bottom}} for each open bar window (physical pixels).
BarWindows() {
    global BarTitle
    PerMonitorDpi()
    bars := Map()
    for hwnd in WinGetList(BarTitle) {
        try {
            WinGetPos &x, &y, &w, &h, hwnd
            if m := MonitorFromPoint(x + w // 2, y + h // 2)
                bars[m] := {hwnd: hwnd, bottom: y + h}
        }
    }
    return bars
}

ReserveBarSpace() {
    global BarEnabled, Reserved
    PerMonitorDpi()
    bars := BarEnabled ? BarWindows() : Map()
    loop MonitorGetCount() {
        MonitorGet A_Index, &l, &t, &r, &b
        MonitorGetWorkArea A_Index, &wl, &wt, &wr, &wb
        if bars.Has(A_Index) {
            want := Max(t, bars[A_Index].bottom)
            Reserved[A_Index] := true
        } else if Reserved.Has(A_Index) {
            want := t   ; bar gone (toggled off): hand the strip back once
            Reserved.Delete(A_Index)
        } else
            continue
        if wt != want
            SetWorkArea(wl, want, wr, wb)
    }
}

ReleaseBarSpace(*) {
    global Reserved
    PerMonitorDpi()
    for m in Reserved {
        if m > MonitorGetCount()
            continue
        MonitorGet m, &l, &t
        MonitorGetWorkArea m, &wl, &wt, &wr, &wb
        if wt != t
            SetWorkArea(wl, t, wr, wb)
    }
}

SetWorkArea(l, t, r, b) {
    rc := Buffer(16)
    NumPut "int", l, "int", t, "int", r, "int", b, rc
    ; SPI_SETWORKAREA, SPIF_SENDCHANGE (GlazeWM re-tiles on the broadcast)
    DllCall("SystemParametersInfo", "uint", 0x2F, "uint", 0, "ptr", rc, "uint", 2)
}

OnSettingChange(wParam, *) {
    if wParam = 0x2F   ; someone (usually Explorer) changed a work area
        SetTimer ReserveBarSpace, -100
}

; Topmost bar, but a fullscreen window (Super+F, video, game) may cover it.
FullscreenWatch() {
    global BarEnabled
    if !BarEnabled
        return
    PerMonitorDpi()
    fg := WinExist("A"), fsMon := 0
    if fg && IsFullscreenWindow(fg)
        fsMon := MonitorOfWindow(fg)
    for m, bar in BarWindows() {
        try {
            onTop := WinGetExStyle(bar.hwnd) & 0x8
            if m != fsMon {
                if !onTop
                    WinSetAlwaysOnTop 1, bar.hwnd
            } else if onTop {
                WinSetAlwaysOnTop 0, bar.hwnd
                ; Leaving topmost lifts it over normal windows: tuck it under the fullscreen one.
                DllCall("SetWindowPos", "ptr", bar.hwnd, "ptr", fg, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x13)
            }
        }
    }
}

IsFullscreenWindow(hwnd) {
    try {
        cls := WinGetClass(hwnd)
        if cls ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$" || WinGetProcessName(hwnd) = "zebar.exe"
            return false
        WinGetPos &x, &y, &w, &h, hwnd
        MonitorGet MonitorOfWindow(hwnd), &l, &t, &r, &b
        return x <= l && y <= t && x + w >= r && y + h >= b
    }
    return false
}

MonitorOfWindow(hwnd) {
    WinGetPos &x, &y, &w, &h, hwnd
    return MonitorFromPoint(x + w // 2, y + h // 2) || MonitorGetPrimary()
}

; Omarchy's audio / bluetooth panels -> Windows' quick panels (Sound output
; flyout, Quick Settings Bluetooth list). The key or bar icon again closes it.
TogglePanel(kind) {
    global PanelSeen
    if ShellFlyoutActive() {
        Send "{Esc}"
        return
    }
    ; Clicking the bar icon closes an open flyout before the click lands here.
    if PanelSeen.Has(kind) && A_TickCount - PanelSeen[kind] < 800
        return
    if kind = "audio"
        Send "#^v"
    else
        Run "ms-actioncenter:controlcenter/bluetooth"
    WatchPanel(kind, A_TickCount)
}

WatchPanel(kind, started) {
    global PanelSeen
    if ShellFlyoutActive()
        PanelSeen[kind] := A_TickCount
    else if A_TickCount - Max(PanelSeen.Has(kind) ? PanelSeen[kind] : 0, started) > 1500 {
        if kind = "bluetooth"
            BluetoothStatus()
        return
    }
    SetTimer WatchPanel.Bind(kind, started), -100
}

; Quick settings and flyouts belong to the shell host (ShellHost.exe on 24H2+,
; ShellExperienceHost.exe before) - matched by process, so any UI language works.
ShellFlyoutActive() {
    try return WinGetProcessName("A") ~= "i)^(ShellHost|ShellExperienceHost)\.exe$"
    return false
}

BluetoothStatus() {
    Run('"' Env("powershell", "powershell.exe") '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' Env("code") '\ps51\bluetooth.ps1"', , "Hide")
}

OnMenuCommand(wParam, *) {
    switch wParam {
        case 1: ToggleBar()
        case 2: ToggleGaps()
        case 3: ToggleAwake()
        case 4: ToggleTransparency()
        case 5: SetTimer ColorPicker, -10
        case 6: TogglePanel("audio")
        case 7: TogglePanel("bluetooth")
        case 8: SetTimer ScreensaverStart, -400
        case 9: ToggleScreensaver()
        case 10: SetTimer CaptureText, -300
        case 11: ToggleNightlight()
        case 12: ToggleDnd()
        case 13: ShowWeather()
        case 14: Activity()
    }
}

; --- Keys -------------------------------------------------------------------
; Tapping Super alone (or a quick Super+N handled by GlazeWM) must not open
; the Start menu. The unassigned vkE8 key masks the lone Win press.
; Start menu is still on Ctrl+Esc.
~LWin::Send "{Blind}{vkE8}"

; Win+Space and its Ctrl/Shift variants are Windows' keyboard-layout switch.
; Omarchy uses them, so they are only taken over when config allows it
; (the installer asks when more than one layout / an IME is installed).
if Env("takeOverWinSpace", "1") = "1" {
    Hotkey "#Space", (*) => Send(Env("flowHotkey", "!{Space}"))   ; app launcher (Flow Launcher)
    Hotkey "#^Space", (*) => OpenMenu("background")                ; background picker
    Hotkey "#^+Space", (*) => OpenMenu("theme")                    ; theme picker
    Hotkey "#+Space", (*) => ToggleBar()                           ; top bar
}

; Omarchy menus (Zebar menu widget)
#!Space::OpenMenu("root")             ; Omarchy menu
#Escape::OpenMenu("system")           ; lock / suspend / restart / shutdown
#k::OpenMenu("keys")                  ; keybindings
#^c::OpenMenu("capture")              ; capture (also the way in without a PrtScn key)
#^o::OpenMenu("toggle")
#^h::OpenMenu("setup")

; Toggles
#Backspace::ToggleTransparency()      ; active window transparency
#+Backspace::ToggleGaps()             ; window gaps
#^i::ToggleAwake()                    ; stay awake

; Capture (Win+PrtScn stays Windows' save-to-Screenshots)
!PrintScreen::Send "#+r"              ; screen recording (Snipping Tool)
#^PrintScreen::SetTimer(ColorPicker, -10)
#+PrintScreen::SetTimer(CaptureText, -10)   ; text capture (OCR) -> clipboard

; Super + left drag: move the window from anywhere inside it.
; The window follows the mouse; on release drop.ps1 re-tiles a tiled window
; where it was dropped (Hyprland-style), or re-homes it on the other monitor.
#LButton::
{
    PerMonitorDpi()
    hwnd := WindowUnderCursor()
    if !hwnd
        return
    info := GlazeWindowInfo(hwnd)
    if info && info.state != "tiling" && info.state != "floating"
        return  ; fullscreen / minimized
    CoordMode "Mouse", "Screen"
    MouseGetPos &sx, &sy
    WinGetPos &wx, &wy, , , hwnd
    WinActivate hwnd
    while GetKeyState("LButton", "P") {
        MouseGetPos &x, &y
        WinMove wx + x - sx, wy + y - sy, , , hwnd
        Sleep 10
    }
    MouseGetPos &x, &y
    if info
        Run('"' Env("pwsh", "pwsh.exe") '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' Env("code") '\lib\drop.ps1" -Id ' info.id ' -X ' x ' -Y ' y ' -Cli "' GlazeCli '"', , "Hide")
}

; Super + right drag: resize through GlazeWM so tiled neighbours adjust too.
; Grabbing the left/top half of a window makes dragging left/up grow it.
#RButton::
{
    PerMonitorDpi()
    hwnd := WindowUnderCursor()
    if !hwnd
        return
    info := GlazeWindowInfo(hwnd)
    if !info
        return
    CoordMode "Mouse", "Screen"
    MouseGetPos &lastX, &lastY
    WinGetPos &wx, &wy, &ww, &wh, hwnd
    signX := lastX < wx + ww / 2 ? -1 : 1
    signY := lastY < wy + wh / 2 ? -1 : 1
    step := Round(8 * MonitorDpi(MonitorUnderMouse()) / 96)   ; ignore jitter, any DPI
    while GetKeyState("RButton", "P") {
        Sleep 40
        MouseGetPos &x, &y
        dx := (x - lastX) * signX, dy := (y - lastY) * signY
        args := ""
        if Abs(dx) >= step
            args .= " --width " (dx > 0 ? "+" : "") dx "px", lastX := x
        if Abs(dy) >= step
            args .= " --height " (dy > 0 ? "+" : "") dy "px", lastY := y
        if args
            RunWait('"' GlazeCli '" command --id ' info.id ' resize' args, , "Hide")
    }
}

; Super + J: togglesplit. GlazeWM's own toggle-tiling-direction only affects
; the next window, so flip the workspace of the active window instead, which
; re-tiles its windows side-by-side <-> stacked.
#j::
{
    info := GlazeWindowInfo(WinExist("A"))
    if info {
        RunWait('"' GlazeCli '" command --id ' info.workspace ' toggle-tiling-direction', , "Hide")
        ; toggle-tiling-direction on a workspace doesn't re-layout by itself.
        RunWait('"' GlazeCli '" command wm-redraw', , "Hide")
    }
    ; Each fire flips the layout, so key auto-repeat must not fire it again
    ; (two flips = no change). Hold this thread until J is released.
    KeyWait "j"
}

; Super + scroll: next / previous workspace
#WheelDown::Glaze("focus --next-active-workspace")
#WheelUp::Glaze("focus --prev-active-workspace")

; Ctrl + Alt + Tab: focus the next / previous monitor
^!Tab::FocusMonitor(1)
^!+Tab::FocusMonitor(-1)

; Universal clipboard (Omarchy v4): Super + C/V/X/A
#c::Send IsTerminal() ? "^+c" : "^c"
#v::Send IsTerminal() ? "^+v" : "^v"
#x::Send "^x"
#a::Send "^a"

; Super + Ctrl + V: clipboard history, Super + Ctrl + E: emoji picker
#^v::Send "#v"
#^e::Send "#{vkBE}"                   ; Win+. by key code, so it works on any layout

; Voice dictation (Windows voice typing, same as Win+H) - talk and it types.
; Shift + F9 (no Fn needed on most laptops too); Super + Ctrl + X is Omarchy's toggle.
+F9::Send "#h"
#^x::Send "#h"

; Super + Ctrl + L: lock
#^l::DllCall("LockWorkStation")

; Omarchy utility panels -> closest Windows equivalents
#^q::Run "calc.exe"                               ; calculator
#^t::Activity()                                   ; activity (btop; Task Manager if missing)
#^n::ToggleNightlight()                           ; nightlight
#^SC033::ToggleDnd()                              ; Super+Ctrl+Comma: do not disturb
#^!t::ShowTime()                                  ; time popup
#^!b::ShowBattery()                               ; battery popup
#^!w::ShowWeather()                               ; weather popup
#^a::TogglePanel("audio")                         ; audio panel (again: close)
#^b::TogglePanel("bluetooth")                     ; bluetooth panel (again: close)
#^w::Run "ms-settings:network"                    ; network
#^d::Run "ms-settings:display"                    ; display
#^p::Run "ms-settings:powersleep"                 ; power
#^!d::Send "#n"                                   ; calendar
#+!SC033::Send "#n"                               ; Super+Shift+Alt+Comma: notification history
#^z::Send "#{NumpadAdd}"                          ; zoom in (Magnifier)
#^!z::Send "#{Esc}"                               ; reset zoom

; Super + Shift + Return: browser (Omarchy v4); + Alt + B: private window
#+Enter::OpenBrowser()
#+!b::OpenBrowser(true)

OpenBrowser(private := false) {
    exe := Env("browser")
    args := private ? " " Env("browserPrivate", "--incognito") : ""
    try Run(exe ? '"' exe '"' args : "https://")
    catch
        Run "msedge.exe" (private ? " --inprivate" : "")
}

; --- Toggles ----------------------------------------------------------------
ToggleBar() {
    global BarEnabled, Zebar
    BarEnabled := !BarEnabled
    if BarEnabled {
        try Run('"' Zebar '" startup', , "Hide")
    } else {
        CloseBar()
    }
    SetTimer ReserveBarSpace, BarEnabled ? -2000 : -10
    Osd("Top bar " (BarEnabled ? "on" : "off"))
}

ToggleGaps() {
    file := Env("glazeConfig")
    yaml := FileRead(file, "UTF-8")
    on := !RegExMatch(yaml, "inner_gap:\s*'0px'")
    gap := on ? 0 : Env("gap", 10)
    yaml := RegExReplace(yaml, "'\d+px'(\s*# gaps)", "'" gap "px'$1")
    f := FileOpen(file, "w", "UTF-8-RAW")
    f.Write(yaml)
    f.Close()
    Glaze("wm-reload-config")
    Osd("Window gaps " (on ? "off" : "on"))
}

ToggleAwake() {
    global Awake
    Awake := !Awake
    ; ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED keeps screen + PC awake.
    DllCall("SetThreadExecutionState", "UInt", Awake ? 0x80000003 : 0x80000000)
    WriteIndicators()
    Osd("Stay awake " (Awake ? "on" : "off"))
}

ToggleTransparency() {
    global Transparent
    hwnd := WinExist("A")
    if !hwnd
        return
    if Transparent.Has(hwnd) {
        WinSetTransparent "Off", hwnd
        Transparent.Delete(hwnd)
    } else {
        WinSetTransparent 230, hwnd
        Transparent[hwnd] := true
    }
}

; Click anywhere to copy that pixel's color as #rrggbb (Esc cancels).
ColorPicker() {
    static picking := false
    if picking
        return
    picking := true
    PerMonitorDpi()
    CoordMode "Mouse", "Screen"
    CoordMode "Pixel", "Screen"
    CoordMode "ToolTip", "Screen"
    st := {clicked: false}
    Hotkey "*LButton", (*) => st.clicked := true, "On"
    while !st.clicked && !GetKeyState("Escape", "P") {
        MouseGetPos &x, &y
        ToolTip "#" SubStr(Format("{:06x}", PixelGetColor(x, y)), -6) "  (click to copy, Esc to cancel)", x + 16, y + 16
        Sleep 30
    }
    Hotkey "*LButton", "Off"
    ToolTip
    if st.clicked {
        MouseGetPos &x, &y
        hex := "#" SubStr(Format("{:06x}", PixelGetColor(x, y)), -6)
        A_Clipboard := hex
        Osd("Copied " hex)
    }
    picking := false
}

; --- Helpers ----------------------------------------------------------------
OpenMenu(route) {
    Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" open ' route)
}

Glaze(cmd) {
    global GlazeCli
    try Run('"' GlazeCli '" command ' cmd, , "Hide")
}

; GlazeWM numbers monitors left to right, then top to bottom.
FocusMonitor(step) {
    PerMonitorDpi()
    n := MonitorGetCount()
    cur := 0
    if hwnd := WinExist("A")
        cur := MonitorPosition(MonitorOfWindow(hwnd))
    Glaze("focus --monitor " Mod(cur + step + n, n))
}

; Small Omarchy-style OSD at the bottom center of the active monitor.
Osd(text) {
    global OsdGui
    colors := ThemeColors()
    OsdHide()
    PerMonitorDpi()   ; size + place it in the monitor's real pixels (mixed-DPI setups)
    mon := MonitorUnderMouse()
    scale := MonitorDpi(mon) / 96
    OsdGui := g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Border -DPIScale", "omarchy-osd")
    g.BackColor := colors.bg
    g.MarginX := Round(18 * scale), g.MarginY := Round(10 * scale)
    g.SetFont("s" Round(11 * scale * 96 / A_ScreenDPI) " c" colors.fg, colors.font)
    g.AddText(, text)
    g.Show("Hide AutoSize")
    g.GetPos(, , &w, &h)
    MonitorGetWorkArea(mon, &l, &t, &r, &b)
    g.Show("NoActivate x" (l + (r - l - w) // 2) " y" (b - h - Round(60 * scale)))
    SetTimer OsdHide, -1200
}
OsdHide() {
    global OsdGui
    if OsdGui
        OsdGui.Destroy()
    OsdGui := 0
}

; Current theme colors (theme.css) and font (status.json); Tokyo Night if missing.
ThemeColors() {
    global Pack
    c := {bg: "1a1b26", fg: "a9b1d6", font: "JetBrainsMono Nerd Font"}
    try {
        css := FileRead(Pack "\theme.css")
        if RegExMatch(css, "--bg:\s*#([0-9a-fA-F]{6})", &m)
            c.bg := m[1]
        if RegExMatch(css, "--fg:\s*#([0-9a-fA-F]{6})", &m)
            c.fg := m[1]
    }
    try {
        if RegExMatch(FileRead(Pack "\status.json"), '"font":\s*"([^"]+)"', &m)
            c.font := m[1]
    }
    return c
}

; indicators.json feeds the bar's indicator icons (this script is its only writer).
WriteIndicators() {
    global Pack, Awake
    static last := ""
    b := v => v ? "true" : "false"
    json := '{"awake":' b(Awake) ',"nightlight":' b(NightlightOn()) ',"dnd":' b(DndProfile() > 0) '}'
    if json = last
        return
    try {
        f := FileOpen(Pack "\indicators.json", "w", "UTF-8-RAW")
        f.Write(json)
        f.Close()
        last := json
    }
}

IsTerminal() {
    return WinActive("ahk_exe WindowsTerminal.exe")
        || WinActive("ahk_class ConsoleWindowClass")
        || WinActive("ahk_exe wezterm-gui.exe")
        || WinActive("ahk_exe alacritty.exe")
}

WindowUnderCursor() {
    MouseGetPos , , &hwnd
    if !hwnd
        return 0
    hwnd := DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr")  ; GA_ROOT
    cls := WinGetClass(hwnd)
    if cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd" || cls = "Shell_SecondaryTrayWnd"
        return 0
    return hwnd
}

GlazeQuery(what) {
    global GlazeCli
    tmp := A_Temp "\glazewm-" what ".json"
    RunWait(A_ComSpec ' /c ""' GlazeCli '" query ' what ' > "' tmp '""', , "Hide")
    try return FileRead(tmp)
    return ""
}

; {id, state, workspace} of the GlazeWM window with this handle, or 0.
GlazeWindowInfo(hwnd) {
    if !hwnd
        return 0
    json := GlazeQuery("workspaces")
    pos := RegExMatch(json, '"handle":' hwnd '[,}]')
    if !pos
        return 0
    head := SubStr(json, 1, pos)
    id := "", ws := "", wpos := 0, p := 1
    while p := RegExMatch(head, '"type":"window","id":"([^"]+)"', &m, p)
        id := m[1], wpos := p, p += m.Len
    p := 1
    while p := RegExMatch(head, '"type":"workspace","id":"([^"]+)"', &m, p)
        ws := m[1], p += m.Len
    state := RegExMatch(head, '"state":\{"type":"(\w+)"', &m, wpos) ? m[1] : ""
    return id ? {id: id, state: state, workspace: ws} : 0
}
