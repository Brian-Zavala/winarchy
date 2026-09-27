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
;   - GlazeWM's own keys (Super+1..0, Super+arrows, Super+Tab, Super+S, Super+F) with an
;     admin window in front: GlazeWM's keyboard hook is blocked by exactly the same rule,
;     and the winarchy build of GlazeWM has no uiAccess manifest, so nothing switched
;     workspaces while an admin game was up. This helper does NOT run the GlazeWM CLI
;     itself - it lives under %USERPROFILE%, which the user can write to, and an elevated
;     process must never execute anything user-writable. It posts one integer down to
;     winarchy.ahk (message 0x5557, see Rescue) and lets that run the CLI.
;   - winarchy.ahk's "close game" (bar gamepad icon) for admin games, via message 0x5556
;     (wParam 1 = close, 2 = force-quit; lParam = the window), games only.
;   - Give an admin game the foreground back (0x5556, wParam 3) when something took it
;     without you asking: an exclusive-fullscreen game minimizes itself otherwise. The
;     helper decides whether you asked, since its hooks see your keys and clicks while
;     that game is in front and winarchy.ahk's don't.
;   - Park / unpark an admin game (0x5556, wParam 4 = minimize, 5 = restore + activate)
;     when you switch away from / back to its workspace: GlazeWM ignores games, so it
;     never hides them itself (see GameWorkspaceSync in winarchy.ahk).
; It runs from an admin-only copy (%ProgramData%\winarchy-games) and includes nothing
; user-writable: it only reads the game list (Game Bar's + config "games") as data.
; Undo: winarchy uninstall (or winarchy game-setup -Remove).

#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
Persistent
KeyHistory 0
ListLines false

; One bad window handle must not take the helper down, and must never pop a dialog over a
; game. Log it next to this script (an admin-only folder: the log can't be redirected by
; the user) and drop the failing thread. Returning 1 ends that thread; -1 would carry on
; after the failed line, with whatever half-built state caused it.
OnError LogError

LogError(err, mode) {
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " (err is Error
        ? Type(err) ": " err.Message " (" err.File ":" err.Line ")" : String(err)) "`n",
        A_ScriptDir "\errors.log", "UTF-8")
    return 1
}

; winarchy.ahk (not elevated) may post this one message to this window.
DllCall("ChangeWindowMessageFilterEx", "ptr", A_ScriptHwnd, "uint", 0x5556, "uint", 1, "ptr", 0)
OnMessage 0x5556, OnCloseRequest
; Your own input, seen even over an admin game (see GiveBack).
InstallKeybdHook
InstallMouseHook

#HotIf ElevatedActive()
~LWin::Send "{Blind}{vkE8}"
LWin up::Send "{Blind}{vkE8}{LWin up}"
#w::
#q::CloseWindow(WinExist("A"), false)
; GlazeWM's keybindings, stood in for while its own hook is blocked. Kept as one explicit
; line each, deliberately: this is the full list of keys this elevated script takes, and it
; must be readable at a glance. The numbers are the action codes winarchy.ahk decodes.
#1::Rescue(101)
#2::Rescue(102)
#3::Rescue(103)
#4::Rescue(104)
#5::Rescue(105)
#6::Rescue(106)
#7::Rescue(107)
#8::Rescue(108)
#9::Rescue(109)
#0::Rescue(110)
#+1::Rescue(201)      ; move the window there and follow it
#+2::Rescue(202)
#+3::Rescue(203)
#+4::Rescue(204)
#+5::Rescue(205)
#+6::Rescue(206)
#+7::Rescue(207)
#+8::Rescue(208)
#+9::Rescue(209)
#+0::Rescue(210)
#+!1::Rescue(301)     ; move the window there, stay where you are
#+!2::Rescue(302)
#+!3::Rescue(303)
#+!4::Rescue(304)
#+!5::Rescue(305)
#+!6::Rescue(306)
#+!7::Rescue(307)
#+!8::Rescue(308)
#+!9::Rescue(309)
#+!0::Rescue(310)
#Left::Rescue(401)
#Right::Rescue(402)
#Up::Rescue(403)
#Down::Rescue(404)
#+Left::Rescue(501)
#+Right::Rescue(502)
#+Up::Rescue(503)
#+Down::Rescue(504)
#+!Left::Rescue(601)  ; move the whole workspace to the next monitor
#+!Right::Rescue(602)
#+!Up::Rescue(603)
#+!Down::Rescue(604)
#Tab::Rescue(701)
#+Tab::Rescue(702)
#^Tab::Rescue(703)
#s::Rescue(801)
#!s::Rescue(802)
#f::Rescue(803)
#!f::Rescue(804)
#HotIf

; Hand one action code to winarchy.ahk, which is not elevated and may run the GlazeWM CLI.
; Nothing else crosses: no path, no string, no command - just an integer this script chose.
; If the daemon isn't running there is nothing to do, and the key is simply dropped.
Rescue(action) {
    if daemon := Daemon()
        PostMessage 0x5557, action, 0, , daemon
}

; winarchy.ahk's own window. Elevated -> normal messages are allowed (the block only runs
; the other way), so this needs no ChangeWindowMessageFilterEx on that side.
Daemon() {
    DetectHiddenWindows true
    SetTitleMatchMode 2
    return WinExist("\winarchy.ahk ahk_class AutoHotkey")
}

OnCloseRequest(wParam, lParam, *) {
    hwnd := lParam
    if !DllCall("IsWindow", "ptr", hwnd)
        return 0
    ; Raising a window is harmless, so this isn't limited to IsGameWindow's list (which
    ; misses games winarchy.ahk finds by their install folder or by Playnite).
    if wParam = 3 {
        SetTimer () => GiveBack(hwnd), -10
        return 1
    }
    if wParam = 4 || wParam = 5 {
        SetTimer () => Park(hwnd, wParam = 4), -10
        return 1
    }
    if !IsGameWindow(hwnd)
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

; An admin game lost the foreground: restore and activate it again, unless you pressed a
; key or clicked within the last 1.5 s (Alt+Tab, Super+1, a click on the other monitor -
; you meant to leave it).
GiveBack(hwnd) {
    if Min(A_TimeIdleKeyboard, A_TimeIdleMouse) < 1500 || !DllCall("IsWindow", "ptr", hwnd)
        return
    if WinGetMinMax(hwnd) = -1
        WinRestore hwnd
    WinActivate hwnd
}

; Its workspace was switched away from (minimize) or back to (restore + activate).
Park(hwnd, away) {
    if !DllCall("IsWindow", "ptr", hwnd)
        return
    if away {
        if WinGetMinMax(hwnd) != -1
            WinMinimize hwnd
        return
    }
    if WinGetMinMax(hwnd) = -1
        WinRestore hwnd
    WinActivate hwnd
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
