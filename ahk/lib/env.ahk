; Machine paths and settings written by `winarchy apply`
; (%USERPROFILE%\.winarchy\generated\winarchy.ini), so no script hard-codes a path.

global OW := LoadOmarchyEnv()
ScrubAgentEnv()

; Started from a Claude Code shell, this script had NO_COLOR=1 and the session's CLAUDE_*
; variables, and so did every terminal it opened: prompts lost their colours and `claude`
; took itself for a child of that session. Drop them, keeping what the user set in their
; own environment. The winarchy CLI does the same (lib\common.ps1 Clear-AgentSessionEnv).
ScrubAgentEnv() {
    if EnvGet("CLAUDECODE") = ""
        return
    names := []
    if p := DllCall("GetEnvironmentStringsW", "ptr") {
        at := p
        while (s := StrGet(at, "UTF-16")) != "" {
            if i := InStr(s, "=", , 2)
                names.Push(SubStr(s, 1, i - 1))
            at += (StrLen(s) + 1) * 2
        }
        DllCall("FreeEnvironmentStringsW", "ptr", p)
    }
    for name in names {
        if !(name ~= "i)^(NO_COLOR|GIT_EDITOR|COREPACK_ENABLE_AUTO_PIN|CLAUDECODE|CLAUDE_PID|CLAUDE_EFFORT|CLAUDE_CODE_\w+)$")
            continue
        try {
            RegRead("HKCU\Environment", name)
            continue
        }
        try {
            RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", name)
            continue
        }
        EnvSet name
    }
}

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
            Run TerminalTabLine(title, command, dir)
            return
        }
    }
    Run command, dir
}

; wt splits tabs on ; (escaped as \;, like Start-AgentTerminal does).
TerminalTabLine(title, command, dir) {
    return 'wt.exe new-tab' WtProfileArg() ' --title "' title '" -d "' dir '" ' StrReplace(command, ";", "\;")
}

; Windows Terminal with these arguments, or the fallback command line without it.
RunWt(args, fallback := "") {
    if Env("wt") {
        try {
            Run WtLine(args)
            return
        }
    }
    if fallback
        try Run fallback
}

; No profile of its own: Omarchy Shell, placed after the window options (-w, --size...).
WtLine(args) {
    if WtProfileArg() && !RegExMatch(args, "(^|\s)(-p|--profile)\s")
        args := RegExReplace(args, "^((?:(?:-w|--window|--size|--pos)\s+\S+\s*|(?:--fullscreen|--maximized|--focus|-F|-M|-f)\s+)*)", "$1" LTrim(WtProfileArg()) " ", , 1)
    return 'wt.exe ' Trim(args)
}

; PATH as the registry has it now (Machine, then User), %VARS% expanded.
RegistryPathDirs() {
    dirs := []
    for root in ["HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "HKCU\Environment"] {
        try for d in StrSplit(RegRead(root, "Path"), ";") {
            if d = ""
                continue
            if InStr(d, "%") {                ; REG_EXPAND_SZ entries: %USERPROFILE%\...
                buf := Buffer(2048 * 2)
                if DllCall("ExpandEnvironmentStringsW", "str", d, "ptr", buf, "uint", 2048)
                    d := StrGet(buf, "UTF-16")
            }
            dirs.Push(d)
        }
    }
    return dirs
}

; A command line tool, found on PATH as it is now: this script's own PATH is from when you
; logged in, so something installed since (Install > TUI) would look missing.
FindCommand(name) {
    dirs := [EnvGet("LOCALAPPDATA") "\Microsoft\WinGet\Links"]
    dirs.Push(RegistryPathDirs()*)
    for d in dirs {
        for ext in [".exe", ".cmd", ".bat"]
            if FileExist(p := RTrim(d, "\") "\" name ext)
                return p
    }
    return ""
}

; This script's PATH again from the registry, keeping entries only this process has: a
; script started at login doesn't see what was installed since (winget, npm), and neither
; does anything it runs.
RefreshPath() {
    seen := Map()
    seen.CaseSense := false
    out := ""
    for list in [RegistryPathDirs(), StrSplit(EnvGet("PATH"), ";")]
        for d in list
            if d != "" && !seen.Has(k := RTrim(d, "\")) {
                seen[k] := true
                out .= (out = "" ? "" : ";") d
            }
    if out != ""
        EnvSet "PATH", out
}

; -p for winarchy's own terminal profile (elevate off, so "Run as administrator" in
; Terminal's defaults can't break these tabs), or nothing before `winarchy apply` wrote it.
WtProfileArg() {
    return Env("wtProfile") ? ' -p "' Env("wtProfile") '"' : ""
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
