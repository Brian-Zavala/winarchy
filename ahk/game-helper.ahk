; winarchy game helper: the part of winarchy that runs as administrator (optional).
;
; Many games are set to "Run as administrator". Windows then keeps normal programs
; away from them: winarchy.ahk and GlazeWM don't get the keys pressed while such a game
; is in front (Super+W fell through to Windows' Widgets), and can't close it. This
; helper, started at login by the task `winarchy game-setup` creates (one UAC prompt),
; does only that:
;   - Super+W / Super+Q with an admin window in front: close it (WM_CLOSE, like its X);
;     on a game, again within 15 s: force-quit.
;   - Super alone (tapped or held) doesn't open the Start menu there either.
;   - winarchy.ahk's "close game" (bar gamepad icon) for admin games, via message 0x5556
;     (wParam 1 = close, 2 = force-quit; lParam = the window), games only.
; It runs from an admin-only copy (%ProgramData%\winarchy-games) and includes nothing
; user-writable: it only reads the game list (Game Bar's + config "games") as data.
; Undo: winarchy uninstall (or winarchy game-setup -Remove).

#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
Persistent
KeyHistory 0
ListLines false

; winarchy.ahk (not elevated) may post this one message to this window.
DllCall("ChangeWindowMessageFilterEx", "ptr", A_ScriptHwnd, "uint", 0x5556, "uint", 1, "ptr", 0)
OnMessage 0x5556, OnCloseRequest

#HotIf ElevatedActive()
~LWin::Send "{Blind}{vkE8}"
LWin up::Send "{Blind}{vkE8}{LWin up}"
#w::
#q::CloseWindow(WinExist("A"), false)
#HotIf

OnCloseRequest(wParam, lParam, *) {
    hwnd := lParam
    if !DllCall("IsWindow", "ptr", hwnd) || !IsGameWindow(hwnd)
        return 0
    SetTimer () => CloseWindow(hwnd, wParam = 2), -10
    return 1
}

; WM_CLOSE; a game closed again within 15 s (or force = true) is force-quit.
CloseWindow(hwnd, force) {
    static asked := 0, askedPid := 0
    try pid := WinGetPID(hwnd)
    catch
        return
    game := IsGameWindow(hwnd)
    if game && (force || (pid = askedPid && A_TickCount - asked < 15000)) {
        askedPid := 0
        ProcessClose pid
        return
    }
    asked := A_TickCount, askedPid := pid
    PostMessage 0x10, 0, 0, , hwnd
}

; The active window belongs to an elevated process (cached per process).
ElevatedActive() {
    static byPid := Map()
    if !(hwnd := WinExist("A"))
        return false
    try pid := WinGetPID(hwnd)
    catch
        return false
    if !byPid.Has(pid) {
        if byPid.Count > 200
            byPid.Clear()
        byPid[pid] := IsElevated(pid)
    }
    return byPid[pid]
}

IsElevated(pid) {
    elevated := false
    if h := DllCall("OpenProcess", "uint", 0x1000, "int", 0, "uint", pid, "ptr") {   ; QUERY_LIMITED_INFORMATION
        token := 0
        if DllCall("advapi32\OpenProcessToken", "ptr", h, "uint", 8, "ptr*", &token) {  ; TOKEN_QUERY
            value := 0, size := 0
            DllCall("advapi32\GetTokenInformation", "ptr", token, "int", 20, "uint*", &value, "uint", 4, "uint*", &size)  ; TokenElevation
            elevated := value != 0
            DllCall("CloseHandle", "ptr", token)
        }
        DllCall("CloseHandle", "ptr", h)
    }
    return elevated
}

IsGameWindow(hwnd) {
    try return GameNames().Has(RegExReplace(WinGetProcessName(hwnd), "i)\.exe$"))
    return false
}

; Process names (no .exe): Windows' Game Bar list + config "games" (from winarchy apply).
GameNames() {
    static names := Map(), loaded := 0
    if loaded && A_TickCount - loaded < 60000
        return names
    loaded := A_TickCount
    names := Map()
    names.CaseSense := false
    try loop reg, "HKCU\System\GameConfigStore\Children", "K" {
        try {
            SplitPath RegRead(A_LoopRegKey "\" A_LoopRegName, "MatchedExeFullPath"), , , , &stem
            if stem
                names[stem] := true
        }
    }
    try {
        games := IniRead(EnvGet("USERPROFILE") "\.winarchy\generated\winarchy.ini", "config", "games", "")
        for g in StrSplit(games, "|")
            if g := Trim(RegExReplace(g, "i)\.exe$"))
                names[g] := true
    }
    return names
}
