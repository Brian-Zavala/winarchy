; Machine paths and settings written by `omarchy-win apply`
; (%USERPROFILE%\.omarchy-win\generated\omarchy.ini), so no script hard-codes a path.

global OW := LoadOmarchyEnv()

LoadOmarchyEnv() {
    ini := EnvGet("USERPROFILE") "\.omarchy-win\generated\omarchy.ini"
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

; Run an omarchy-win CLI verb hidden (bin\omarchy-win.ps1 under PowerShell 7).
OmarchyCmd(args*) {
    try Run OmarchyCmdLine(args*), , "Hide"
}

; Same, waiting for it: returns the exit code (1 = failed; the log says why).
OmarchyCmdWait(args*) {
    try return RunWait(OmarchyCmdLine(args*), , "Hide")
    return 1
}

OmarchyCmdLine(args*) {
    cmd := '"' Env("pwsh", "pwsh.exe") '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1"'
    for a in args
        if a != ""
            cmd .= ' "' StrReplace(a, '"', '\"') '"'
    return cmd
}

; Open a command in the user's terminal (Windows Terminal if present, else its own console).
RunInTerminal(title, command) {
    if Env("wt") {
        try {
            Run 'wt.exe new-tab --title "' title '" ' command
            return
        }
    }
    Run command
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
