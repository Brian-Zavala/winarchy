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

; --- Keys your own scripts have ------------------------------------------------------
; winarchy apply lists the hotkeys your own Startup scripts bind (lib/keys.ps1, "userKeys"):
; winarchy's keys leave those to you, instead of both firing or whichever started last
; winning. BindUnlessUser binds a key only when no script of yours has it.
BindUnlessUser(hk, fn, opts := "") {
    if UserKeys().Has(KeyId(hk))
        return false
    Hotkey hk, fn, opts
    return true
}

UserKeys() {
    static keys := 0
    if !keys {
        keys := Map()
        keys.CaseSense := false
        for k in StrSplit(Env("userKeys"), "|")
            if k != ""
                keys[k] := true
    }
    return keys
}

; A hotkey in the one form lib/keys.ps1 (ConvertTo-KeyId) writes: modifiers in the order
; # ^ ! +, then the key, punctuation as its scan code ("#+/" = "#+SC035" = "#+sc035").
KeyId(hk) {
    hk := RegExReplace(Trim(hk), "i)\s+up$")
    static mods := Map("lwin", "#", "rwin", "#", "ctrl", "^", "control", "^", "lctrl", "^", "rctrl", "^"
        , "lcontrol", "^", "rcontrol", "^", "alt", "!", "lalt", "!", "ralt", "!", "shift", "+", "lshift", "+", "rshift", "+")
    if RegExMatch(hk, "^(.+?)\s+&\s+(.+)$", &m) {
        prefix := LTrim(Trim(m[1]), "~*$")
        if mods.Has(StrLower(prefix))
            return mods[StrLower(prefix)] KeyIdName(Trim(m[2]))
        return "combo:" KeyIdName(prefix) "&" KeyIdName(Trim(m[2]))
    }
    have := ""
    while StrLen(hk) > 1 && InStr("#^!+<>*~$", c := SubStr(hk, 1, 1)) {
        if InStr("#^!+", c)
            have .= c
        hk := SubStr(hk, 2)
    }
    out := ""
    for c in ["#", "^", "!", "+"]
        if InStr(have, c)
            out .= c
    return out KeyIdName(hk)
}

KeyIdName(k) {
    static alias := Map("return", "enter", "esc", "escape", "bs", "backspace", "del", "delete", "ins", "insert")
    if StrLen(k) = 1 {
        if k ~= "^[A-Za-z0-9]$"
            return StrLower(k)
        vk := DllCall("VkKeyScanW", "ushort", Ord(k), "short") & 0xFF
        if vk = 0xFF
            return k
        sc := DllCall("MapVirtualKeyW", "uint", vk, "uint", 0, "uint")
        return sc ? Format("sc{:03x}", sc) : Format("vk{:02x}", vk)
    }
    if RegExMatch(k, "i)^sc([0-9a-f]+)$", &m)
        return Format("sc{:03x}", Integer("0x" m[1]))
    if RegExMatch(k, "i)^vk([0-9a-f]{2})(?:sc[0-9a-f]+)?$", &m) {
        vk := Integer("0x" m[1])
        sc := DllCall("MapVirtualKeyW", "uint", vk, "uint", 0, "uint")
        return sc ? Format("sc{:03x}", sc) : Format("vk{:02x}", vk)
    }
    k := StrLower(k)
    return alias.Has(k) ? alias[k] : k
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
