; What the app launcher keys need (ahk/launchers.ahk, and your copy of it in
; %USERPROFILE%\.winarchy, which gets this file through AutoHotkey's /include switch).
#Include %A_LineFile%\..\env.ahk
#Include %A_LineFile%\..\osd.ahk

; --- Web apps (default/webapps.json -> generated\webapps.ini, written by winarchy apply) --
; Omarchy's web app keys: the browser is started here, straight away, in app mode. Keys
; your own Startup script has are left to it (BindUnlessUser).
WebAppIni() => Env("data") "\generated\webapps.ini"

BindWebAppKeys() {
    try sections := IniRead(WebAppIni())
    catch
        return
    for key in StrSplit(sections, "`n", "`r") {
        if key = "browser"
            continue
        if hk := IniRead(WebAppIni(), key, "hotkey", "")
            BindUnlessUser(hk, OpenWebApp.Bind(key))
    }
}

; The window each key opened: with focus=1 (WhatsApp, Messages, ...) the key brings it back
; instead of opening a second one, Omarchy's omarchy-launch-or-focus-webapp.
global WebAppWindows := Map()

OpenWebApp(key, *) {
    ini := WebAppIni()
    url := IniRead(ini, key, "url", "")
    if url = ""
        return
    exe := IniRead(ini, "browser", "exe", "")
    focus := IniRead(ini, key, "focus", "0") = "1"
    if focus && (hwnd := FindWebAppWindow(key, exe)) {
        try WinActivate "ahk_id " hwnd     ; GlazeWM follows: its workspace comes up
        return
    }
    if exe = "" || !FileExist(exe) {
        try Run url                        ; no Chromium browser: a tab in the default one
        return
    }
    name := RegExReplace(exe, ".*\\")
    before := Map()
    for h in WinGetList("ahk_exe " name)
        before[h] := true
    try Run '"' exe '" --app="' url '"'
    catch
        return
    if focus
        SetTimer RememberWebApp.Bind(key, name, before, A_TickCount), -300
}

; The new window of the browser that appeared after the key: that one is this web app.
RememberWebApp(key, name, before, started) {
    global WebAppWindows
    for h in WinGetList("ahk_exe " name) {
        if !before.Has(h) && WinGetTitle(h) != "" {
            WebAppWindows[key] := h
            return
        }
    }
    if A_TickCount - started < 8000
        SetTimer RememberWebApp.Bind(key, name, before, started), -300
}

; An open one: the window this key opened, else (opened from Start, or before a restart)
; a window of the browser titled with the site's own name. The site's name comes from
; the site, not from Windows' language; a normal browser window is told apart by the
; browser's name at the end of its title, which app windows don't have.
FindWebAppWindow(key, exe) {
    global WebAppWindows
    if WebAppWindows.Has(key) && WinExist("ahk_id " WebAppWindows[key])
        return WebAppWindows[key]
    title := IniRead(WebAppIni(), key, "title", "")
    if title = "" || exe = ""
        return 0
    for h in WinGetList("ahk_exe " RegExReplace(exe, ".*\\")) {
        t := WinGetTitle(h)
        if t = "" || RegExMatch(t, "i) - (Google Chrome|Microsoft.?Edge|Brave|Vivaldi|Chromium|Thorium)$")
            continue
        if RegExMatch(t, "i)(^|[^\w])\Q" title "\E([^\w]|$)")
            return h
    }
    return 0
}

; --- Omarchy's own apps, built for Windows (lib/ports.ps1, Install > Omarchy Apps) ------
RunPort(name, label) {
    exe := EnvGet("LOCALAPPDATA") "\Programs\Winarchy\oma\" name "\" name ".exe"
    if FileExist(exe)
        Run '"' exe '"'
    else
        Osd(label " is not installed: Install > Omarchy Apps > " label, 2500)
}

; --- Terminal apps -------------------------------------------------------------------
; FindCommand (env.ahk): found on PATH as it is now, not as it was at login.
; Open a terminal app, or say where to install it from.
RunTui(title, name, args := "", where := "") {
    exe := FindCommand(name)
    if exe = "" {
        Osd(title " is not installed" (where ? ": Install > " where : ""), 2500)
        return
    }
    RunInTerminal(title, '"' exe '"' (args ? " " args : ""))
}
