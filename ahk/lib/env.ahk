; Machine paths and settings written by `winarchy apply`
; (%USERPROFILE%\.winarchy\generated\winarchy.ini), so no script hard-codes a path.

global OW := LoadOmarchyEnv()

LoadOmarchyEnv() {
    ini := EnvGet("USERPROFILE") "\.winarchy\generated\winarchy.ini"
    env := Map()
    env.CaseSense := false
    for section in ["paths", "config"] {
        try {
            for line in StrSplit(IniRead(ini, section), "`n", "`r") {
                if p := InStr(line, "=")
                    env[SubStr(line, 1, p - 1)] := SubStr(line, p + 1)
            }
        }
    }
    return env
}

Env(key, default := "") {
    global OW
    return OW.Has(key) && OW[key] != "" ? OW[key] : default
}

; Run a winarchy CLI verb hidden (bin\winarchy.ps1 under PowerShell 7).
OmarchyCmd(args*) {
    try Run OmarchyCmdLine(args*), , "Hide"
}

; Same, waiting for it: returns the exit code (1 = failed; the log says why).
OmarchyCmdWait(args*) {
    try return RunWait(OmarchyCmdLine(args*), , "Hide")
    return 1
}

OmarchyCmdLine(args*) {
    cmd := '"' Env("pwsh", "pwsh.exe") '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' Env("code") '\bin\winarchy.ps1"'
    for a in args
        if a != ""
            cmd .= ' "' StrReplace(a, '"', '\"') '"'
    return cmd
}

; Open a command in the user's terminal (Windows Terminal if present, else its own console).
; Started in your home folder, the way a new terminal opens: otherwise it inherits this
; script's own folder (the code's ahk\), and Herdr names its workspace after that repo.
RunInTerminal(title, command, dir := EnvGet("USERPROFILE")) {
    if Env("wt") {
        try {
            Run 'wt.exe new-tab --title "' title '" -d "' dir '" ' command
            return
        }
    }
    Run command, dir
}

; Windows Terminal with these arguments, or the fallback command line without it.
RunWt(args, fallback := "") {
    if Env("wt") {
        try {
            Run 'wt.exe ' args
            return
        }
    }
    if fallback
        try Run fallback
}

; Physical-pixel coordinates (what GlazeWM uses) for this thread.
PerMonitorDpi() {
    DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")
}

; Effective DPI of monitor N (96 = 100 %).
MonitorDpi(n) {
    MonitorGet n, &l, &t, &r, &b
    pt := ((l + 1) & 0xFFFFFFFF) | ((t + 1) << 32)
    hmon := DllCall("MonitorFromPoint", "int64", pt, "uint", 2, "ptr")
    dpiX := 96, dpiY := 96
    try DllCall("Shcore\GetDpiForMonitor", "ptr", hmon, "int", 0, "uint*", &dpiX, "uint*", &dpiY)
    return dpiX
}

; Monitors in GlazeWM / Zebar order (left to right, then top to bottom):
; returns the 0-based position of AHK monitor number n.
MonitorPosition(n) {
    MonitorGet n, &l, &t
    pos := 0
    loop MonitorGetCount() {
        MonitorGet A_Index, &l2, &t2
        if l2 < l || (l2 = l && t2 < t)
            pos++
    }
    return pos
}

MonitorFromPoint(x, y) {
    loop MonitorGetCount() {
        MonitorGet A_Index, &l, &t, &r, &b
        if x >= l && x < r && y >= t && y < b
            return A_Index
    }
    return 0
}

MonitorUnderMouse() {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    return MonitorFromPoint(mx, my) || MonitorGetPrimary()
}

; The monitor you are working on: the one under the pointer, unless keyboard focus has
; moved to another monitor since the pointer last moved (a workspace key, Super+arrows).
; The pointer stays put on those (cursor_jump is off), so "under the mouse" alone would
; open the menu or an OSD on the screen you just left. winarchy.ahk tracks this
; (WorkMonitor) and sets WorkMonitorFn; other scripts ask it over message 0x5558.
global WorkMonitorFn := 0

WorkingMonitor() {
    global WorkMonitorFn
    if WorkMonitorFn
        return WorkMonitorFn()
    prev := A_DetectHiddenWindows
    DetectHiddenWindows true
    mon := 0
    try if hwnd := WinExist("winarchy.ahk ahk_class AutoHotkey")
        mon := SendMessage(0x5558, 0, 0, , hwnd, , , , 300)
    DetectHiddenWindows prev
    return mon >= 1 && mon <= MonitorGetCount() ? mon : MonitorUnderMouse()
}

; An error in a helper script goes to the log, not a modal dialog (which would pop over
; a game). winarchy.ahk and game-helper.ahk have their own; the others call OnError with it.
ScriptLogError(err, mode) {
    try FileAppend FormatTime(, "HH:mm:ss") " [" RegExReplace(A_ScriptName, "\.ahk$") "] error: "
        . (err is Error ? Type(err) ": " err.Message " (" RegExReplace(err.File, ".*\\") ":" err.Line ")" : String(err))
        . "`n", Env("log", A_Temp "\winarchy.log"), "UTF-8"
    return 1
}
