#Requires AutoHotkey v2.0
#SingleInstance Force
#Include lib\env.ahk
#Include lib\osd.ahk
#Include lib\tailscale.ahk
#Include lib\network.ahk
#Include lib\compose.ahk

; Omarchy extras that GlazeWM can't do itself: the bar's screen space, menus,
; toggles, panels, capture, drag, clipboard and utility keys.
; Window management binds live in ~/.glzr/glazewm/config.yaml (generated).
; Menus/pickers are the Zebar "menu" widget, opened through menu.ahk.
; Everything machine-specific comes from `winarchy apply` (lib\env.ahk).
; Undo everything: winarchy uninstall

; This script watches windows that can close between one call and the next, from a dozen
; timers. An uncaught error in any of them used to pop a dialog and take the whole daemon
; down - and with it every key, the bar space and the hidden taskbar, until the next login.
; So log it and drop that one thread instead. Returning 1 ends the thread; -1 would resume
; on the line after the failure, carrying on with whatever state caused it. Errors still go
; to the log, which `winarchy doctor` reads back under "Recent errors".
OnError LogError

LogError(err, mode) {
    try WmLog("error: " (err is Error
        ? Type(err) ": " err.Message " (" RegExReplace(err.File, ".*\\") ":" err.Line ")"
        : String(err)))
    return 1
}

GlazeCli := Env("glazewmCli")
Zebar := Env("zebar")
Pack := Env("pack")
BarTitle := "Zebar - omarchy / bar ahk_exe zebar.exe"
MenuTitle := "Zebar - omarchy / menu ahk_exe zebar.exe"
CalendarTitle := "Zebar - omarchy / calendar ahk_exe zebar.exe"

; Super+Shift+Space / `winarchy bar off` turns the top bar off until it's turned on again.
BarFlag := Env("data") "\generated\bar-off"
BarEnabled := !FileExist(BarFlag)
Awake := false
Transparent := Map()

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
    if !GlazeWmRunning() {
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
; The bar's strip is kept free by GlazeWM's top gap (bar height + gap, scaled per
; monitor DPI), so nothing here touches the monitor work area. (Setting the work
; area directly made Explorer and this script fight: the taskbar flickered.)
; Sleep / lock: stop the screensaver first, then give the desktop a quiet spell.
QuietUntil := 0
OnMessage 0x0218, OnPowerBroadcast                            ; WM_POWERBROADCAST
OnMessage 0x02B1, OnSessionChange                             ; WM_WTSSESSION_CHANGE
DllCall("Wtsapi32\WTSRegisterSessionNotification", "ptr", A_ScriptHwnd, "uint", 0)
; The bar stays above windows, except a fullscreen one (or a game) on its monitor.
; Games: see "Games and fullscreen apps" below.
GameMode := Env("gameMode", "1") = "1"
Games := Map()            ; game windows seen in front: hwnd -> process name
GameHome := Map()         ; hwnd -> name of the workspace the game belongs to (HomeWorkspace)
GameParked := Map()       ; hwnd -> tick: minimized by GameWorkspaceSync (its workspace was left)
BusyUntil := 0            ; a game / fullscreen app was in front until a moment ago
DisplayPending := false   ; a display change (or bar restart) waits for it to close
BlockMinimize := Env("blockMinimize", "1") = "1"
LastPad := 0              ; A_TickCount of the last gamepad input
SetTimer FullscreenWatch, 400
OnExit ShowHiddenBars
if !BarEnabled                        ; bar turned off: no strip kept free for it
    SetTimer () => ApplyGaps(GapsOn(), false), -3000
; Bring the bar back if Zebar dies or a monitor lost its bar; reopen the bars
; after Explorer restarts or the display layout changes (monitor wake, dock).
SetTimer BarGuard, 5000
; Keep these arrow bodies value-less: an arrow returns what its body evaluates to, and a
; non-empty OnMessage return swallows the message (SetTimer answers ""). Same trap as the
; OnExit arrow that used to return UnhookWinEvent's 1 - see UnhookMinimize.
OnMessage DllCall("RegisterWindowMessage", "Str", "TaskbarCreated", "UInt"), (*) => SetTimer(RestartBar, -3000)
OnMessage 0x007E, (*) => SetTimer(OnDisplayChange, -3000)    ; WM_DISPLAYCHANGE
; Commands from menu.ahk (menu widget actions that need this script's state).
OnMessage 0x5555, OnMenuCommand
; GlazeWM keys pressed while an admin window was in front, relayed by the admin game
; helper because GlazeWM's own hook never saw them (see OnRescuedKey).
OnMessage 0x5557, OnRescuedKey
; Admin (UAC) prompts parked in the hidden taskbar: shield in the bar (see UacWatch).
global UacClass := "ahk_class $$$Secure UAP Dummy Window Class For Interim Dialog"
global UacPending := ""            ; title of the parked prompt, "" when none
; Nothing minimizes (taskbar is hidden: a minimized window has no way back). Undo a
; minimize the instant it starts, unless the window is one of the exceptions in
; IsMinimizeAllowed - games, Playnite/Steam Big Picture, owned/tool windows, config
; "minimizeAllowed". Super+M is the rescue key regardless (see the keys below).
; Windows with a standard title bar lose their minimize button as they appear, so for
; them a minimize never starts at all (see StripMinimizeBox).
MinimizeHook := 0
ShowHook := 0
if BlockMinimize {
    MinimizeHook := DllCall("SetWinEventHook", "uint", 0x0016, "uint", 0x0016, "ptr", 0
        , "ptr", CallbackCreate(OnWindowMinimized, "F", 7), "uint", 0, "uint", 0, "uint", 0x0002, "ptr")  ; EVENT_SYSTEM_MINIMIZESTART, WINEVENT_SKIPOWNPROCESS
    ShowHook := DllCall("SetWinEventHook", "uint", 0x8002, "uint", 0x8002, "ptr", 0
        , "ptr", CallbackCreate(OnWindowShown, "F", 7), "uint", 0, "uint", 0, "uint", 0x0002, "ptr")      ; EVENT_OBJECT_SHOW
    SetTimer StripAllMinimizeBoxes, -2000
} else
    SetTimer RestoreMinimizeBoxes, -2000     ; blockMinimize just turned off
OnExit UnhookMinimize
; A game in exclusive fullscreen minimizes itself the moment it loses the foreground (and
; its display mode flips back, which the bar shows as a shrink and re-grow). Something
; taking the foreground from a game without you asking gets it handed straight back -
; see "Games keep the foreground" below. config "gameFocusGuard": false = off.
GameFocusGuard := GameMode && Env("gameFocusGuard", "1") = "1"
LastFg := 0                       ; foreground window before the newest switch
ForegroundHook := 0
if GameFocusGuard
    ForegroundHook := DllCall("SetWinEventHook", "uint", 0x0003, "uint", 0x0003, "ptr", 0
        , "ptr", CallbackCreate(OnForeground, "F", 7), "uint", 0, "uint", 0, "uint", 0, "ptr")  ; EVENT_SYSTEM_FOREGROUND
OnExit UnhookForeground
; GlazeWM ignores games, so it never hides one when you switch away from its workspace:
; GameWorkspaceSync does (see "Games stay on their workspace"). Woken by focus changes and
; by GlazeWM cloaking/uncloaking windows (hide_method: cloak) - only while a game is open.
WorkspaceHooks := []
if GameMode {
    cb := CallbackCreate(OnWorkspaceEvent, "F", 7)
    WorkspaceHooks.Push(DllCall("SetWinEventHook", "uint", 0x0003, "uint", 0x0003, "ptr", 0, "ptr", cb
        , "uint", 0, "uint", 0, "uint", 0x0002, "ptr"))   ; EVENT_SYSTEM_FOREGROUND, WINEVENT_SKIPOWNPROCESS
    WorkspaceHooks.Push(DllCall("SetWinEventHook", "uint", 0x8017, "uint", 0x8018, "ptr", 0, "ptr", cb
        , "uint", 0, "uint", 0, "uint", 0x0002, "ptr"))   ; EVENT_OBJECT_CLOAKED..UNCLOAKED
}
OnExit UnhookWorkspace
; A new window opens on the monitor under the mouse, not on Windows' primary display
; (see "New windows open on the hovered monitor" below). Registered whatever the monitor
; count is - a second monitor can be plugged in later; HoverPlaceWindow is the one that
; decides there is nothing to do.
HoverPlace := Env("openOnHoveredMonitor", "1") = "1"
HoverPoint := {x: 0, y: 0}        ; cursor as it was before the newest window appeared
HoverHold := 0                    ; > 0 while a placement is in flight: sampling paused
HoverHoldUntil := 0               ; absolute backstop for the hold
PrePlaceTarget := Map()          ; new window -> monitor point it belongs on (see PrePlaceOnShow)
PrePlaceHook := 0
if HoverPlace {
    HoverSample()
    SetTimer HoverSample, 120
    DllCall("RegisterShellHookWindow", "ptr", A_ScriptHwnd)
    OnMessage DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt"), OnShellHook
    ; Moves the window onto that monitor the instant it is shown (see PrePlaceOnShow), so
    ; it is never painted on the wrong one first.
    PrePlaceHook := DllCall("SetWinEventHook", "uint", 0x8002, "uint", 0x8002, "ptr", 0
        , "ptr", CallbackCreate(PrePlaceOnShow, "F", 7), "uint", 0, "uint", 0, "uint", 0x0002, "ptr")  ; EVENT_OBJECT_SHOW, WINEVENT_SKIPOWNPROCESS
    OnExit UnhookPrePlace
}
; The monitor you are working on - under the pointer, or where keyboard focus went since
; (see "The monitor you are working on" below). New windows, the menu and OSDs use it.
PointerMovedAt := 0               ; A_TickCount of the pointer's last movement
KeyMonitor := 0                   ; monitor keyboard focus moved to while the pointer was still
KeyMonitorAt := 0
PointerWatch()
SetTimer PointerWatch, 100
FocusMoveHook := DllCall("SetWinEventHook", "uint", 0x0003, "uint", 0x0003, "ptr", 0
    , "ptr", CallbackCreate(OnFocusMoved, "F", 7), "uint", 0, "uint", 0, "uint", 0x0002, "ptr")  ; EVENT_SYSTEM_FOREGROUND, WINEVENT_SKIPOWNPROCESS
OnExit UnhookFocusMove
WorkMonitorFn := WorkMonitor
OnMessage 0x5558, (*) => WorkMonitor()   ; menu.ahk / OSDs asking (see WorkingMonitor in env.ahk)
; Hyprland's follow_mouse, re-asserted (see FocusFollowWatch): GlazeWM's own
; focus_follows_cursor stops following once the pointer touches a window it doesn't
; manage - the bar, the launcher, a picker - which is most of the top of the screen.
; Focus switches as soon as the pointer touches another window.
if Env("focusFollowsCursor", "1") = "1"
    SetTimer FocusFollowWatch, 30
; Keep the dwindle auto-tiling watcher alive (see AutoTileGuard).
if Env("autoTiling", "1") = "1"
    SetTimer AutoTileGuard, 5000
WriteIndicators()
; AHK gives each function one timer, so a one-shot SetTimer WriteIndicators, -N would
; replace this repeating one: one-shots go through their own function object instead.
WriteIndicatorsOnce() => WriteIndicators()
WriteIndicatorsSoon(ms) => SetTimer(WriteIndicatorsOnce, -ms)
UacWatchOnce() => UacWatch()
SetTimer WriteIndicators, 5000     ; nightlight / do-not-disturb also change from Quick Settings
SetTimer UacWatch, 1000
; Running-windows list for the bar's chevron flyout (bar.html -> windows.json).
SetTimer WriteWindows, 1000
; These background refreshes each start a hidden PowerShell. While a game is in front they
; wait (Quiet skips a periodic tick, Later postpones a one-off): a process starting up is
; one of the things that can take the foreground off a game, which then minimizes itself.
; Weather for the bar (every 15 min) and the update indicator (2 min after start, then 6 h).
if Env("weather", "1") = "1" {
    SetTimer Later.Bind(() => OmarchyCmd("weather")), -20000
    SetTimer Quiet.Bind(() => OmarchyCmd("weather")), 900000
}
; AI coding agent usage for the bar (agents.json): once 30 s after start, then on the
; configured interval (agentUsage.refreshSeconds, default 15 min, like Omarchy's widget).
if Env("agentUsage", "1") = "1" {
    SetTimer Later.Bind(() => OmarchyCmd("agent-usage")), -30000
    SetTimer Quiet.Bind(() => OmarchyCmd("agent-usage")), 1000 * Env("agentUsageSeconds", "900")
}
SetTimer Later.Bind(() => OmarchyCmd("update-check")), -120000
SetTimer Quiet.Bind(() => OmarchyCmd("update-check")), 21600000
; Bluetooth on/off for the bar icon (bluetooth.ps1 writes bluetooth.json).
SetTimer Quiet.Bind(BluetoothStatus), 30000
BluetoothStatus()
; Tailscale for the bar icon and panel (tailscale.json + tailscale-status.json), every 30 s
; like Quattro's widget. Only a FileExist while Tailscale isn't installed.
SetTimer Quiet.Bind(TailscaleRefresh), 30000
TailscaleRefresh()
; Network type for the bar icon (network.json), read from Windows every 10 s.
SetTimer Quiet.Bind(NetworkRefresh), 10000
NetworkRefresh()
; Pick up new favorite backgrounds after login settles (local only, no downloads).
if Env("syncAtLogin", "1") = "1"
    SetTimer Later.Bind(() => OmarchyCmd("sync", "-Offline")), -90000

; A periodic background job's tick: skipped while a game / fullscreen app is in front
; (the next tick catches up).
Quiet(fn) {
    if !Busy()
        fn()
}

; A one-off background job: postponed a minute at a time while a game is in front.
Later(fn) {
    if Busy()
        SetTimer Later.Bind(fn), -60000
    else
        fn()
}
; Project app launchers (Super+Return terminal, ...) unless you use your own.
; Your copy (%USERPROFILE%\.winarchy\launchers.ahk, made by Setup > Keybindings) wins;
; it gets lib\launch.ahk (env.ahk and the launcher helpers) through /include, so it needs
; no #Include of the code folder.
if Env("launchers", "1") = "1"
    StartLaunchers()

StartLaunchers() {
    user := Env("data") "\launchers.ahk"
    try Run(FileExist(user)
        ? '"' A_AhkPath '" /include "' A_ScriptDir '\lib\launch.ahk" "' user '"'
        : '"' A_AhkPath '" "' A_ScriptDir '\launchers.ahk"')
}

; --- Live reload: saved edits take effect (Hyprland reloads its config on save) ----
;   config.json          -> winarchy apply
;   glazewm.yaml.tpl     -> rewrite GlazeWM's config and reload it
;   herdr.toml.tpl       -> rewrite Herdr's config.toml and reload a running Herdr
;   your keybindings     -> reload that script (the file itself is never touched)
Watched := Map()
SetTimer WatchEdits, 2000

WatchEdits() {
    global Watched
    data := Env("data")
    for path, action in Map(data "\config.json", "apply", data "\glazewm.yaml.tpl", "apply-glaze",
        data "\herdr.toml.tpl", "apply-herdr", KeybindingsFile(), "reload") {
        t := FileExist(path) ? FileGetTime(path, "M") : ""
        if !Watched.Has(path) {
            Watched[path] := {seen: t, pending: t, since: 0}
            continue
        }
        w := Watched[path]
        if t = w.seen
            continue
        if t != w.pending {             ; still being written: wait until it settles
            w.pending := t, w.since := A_TickCount
            continue
        }
        if A_TickCount - w.since < 1500
            continue
        w.seen := t
        if t = ""
            continue
        ; winarchy's own writes (e.g. animations on/off) apply themselves.
        if action = "apply" && FileExist(data "\generated\config.selfwrite") && Trim(FileRead(data "\generated\config.selfwrite")) = t
            continue
        WmLog("saved: " path)
        if action = "reload"
            ReloadScript(path)
        else
            Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" ' action)   ; shows the result
    }
}

; Your own scripts in the Startup folder: when one is saved, added or removed, winarchy
; keys-refresh re-reads the keys they bind, and winarchy's scripts leave those to you
; (BindUnlessUser). Only a list of names and times: the files are never touched.
SetTimer WatchStartupKeys, 3000

WatchStartupKeys() {
    static seen := "", pending := "", since := 0
    sig := ""
    loop files A_Startup "\*.*" {
        if A_LoopFileExt = "ahk" || A_LoopFileExt = "lnk"
            sig .= A_LoopFileName ":" A_LoopFileTimeModified "|"
    }
    if seen = "" && since = 0 {         ; first look: this is how it was at start
        seen := sig, pending := sig, since := 1
        return
    }
    if sig = seen
        return
    if sig != pending {                 ; still being written: wait until it settles
        pending := sig, since := A_TickCount
        return
    }
    if A_TickCount - since < 1500
        return
    seen := sig
    WmLog("Startup scripts changed: keys-refresh")
    OmarchyCmd("keys-refresh")
}

; The file Setup > Keybindings opens: your own launcher script, or your copy of ours.
KeybindingsFile() {
    if Env("launchers", "1") != "1"
        return A_Startup "\launchers.ahk"
    user := Env("data") "\launchers.ahk"
    return FileExist(user) ? user : A_ScriptDir "\launchers.ahk"
}

; AutoHotkey's own "Reload Script" command, so any script (with or without a tray icon)
; restarts with its saved changes; start it if it isn't running.
ReloadScript(path) {
    DetectHiddenWindows true
    SetTitleMatchMode 2
    if hwnd := WinExist(path " ahk_class AutoHotkey") {
        PostMessage 0x111, 65303, 0, , hwnd
    } else if path = Env("data") "\launchers.ahk" || path = A_ScriptDir "\launchers.ahk" {
        StartLaunchers()
    } else {
        try Run('"' A_AhkPath '" "' path '"')
    }
    Osd("Keybindings reloaded")
}

; --- Keep GlazeWM running -------------------------------------------------------------
; Without it there is no tiling and no Super+1..0 at all (those keys are GlazeWM's own),
; and the keys you would reach for to fix it are the ones that are gone. So restart it -
; whichever build is selected. The experimental animations build gets one extra rule: if it
; quits twice within 5 minutes, animations are switched off and the official build is used.
SetTimer GlazeGuard, 3000

; GlazeWM is running - as opposed to only its CLI, which is also called glazewm.exe (the
; auto-tiling watcher keeps one alive for its event subscription, so a bare name check says
; "running" forever and no watchdog here would ever fire). The CLI lives in a `cli`
; subfolder; the official GlazeWM's own path reads empty, because it runs with UI access,
; and that is exactly the one we must count as running.
GlazeWmRunning() {
    for pid in ProcessList("glazewm.exe") {
        path := ""
        try path := ProcessGetPath(pid)
        if !InStr(path, "\cli\")
            return true
    }
    return false
}

ProcessList(name) {
    pids := []
    for p in ComObjGet("winmgmts:").ExecQuery("Select ProcessId from Win32_Process"
        . " where Name='" name "'")
        pids.Push(p.ProcessId)
    return pids
}

GlazeGuard() {
    static gone := 0, deaths := []
    exe := Env("glazewm")
    if GlazeWmRunning() {
        gone := 0
        return
    }
    ; winarchy is switching builds right now.
    flag := Env("data") "\generated\glazewm-switch.flag"
    if FileExist(flag) && DateDiff(A_Now, FileGetTime(flag, "M"), "Seconds") < 30
        return
    if !gone {
        gone := A_TickCount
        return
    }
    ; The animation build's file is gone (Defender quarantines it at times: unsigned, built
    ; here): no restart can work, so go to the official build at once. Toggle > Window
    ; Animations then puts it back (`animations setup`: one admin prompt, no rebuild).
    if InStr(exe, "\glazewm-animations\") && !FileExist(exe) {
        gone := 0
        WmLog("GlazeWM animation build is missing (antivirus?): switching animations off")
        Osd("Window animations off: Windows Defender removed the build. Toggle > Window Animations restores it", 6000)
        OmarchyCmd("animations", "off")
        return
    }
    now := A_TickCount
    recent := []
    for d in deaths
        if now - d < 300000
            recent.Push(d)
    deaths := recent
    deaths.Push(now)
    gone := 0
    ; The experimental build gets a way out: twice in 5 minutes and it is not worth it.
    if InStr(exe, "\glazewm-animations\") && deaths.Length >= 2 {
        deaths := []
        WmLog("GlazeWM animation build stopped twice: switching animations off")
        Osd("Window animations off: the animation build stopped", 4000)
        OmarchyCmd("animations", "off")
        return
    }
    ; The official build has nothing to fall back to, so keep restarting it - but not
    ; forever: something that dies this often needs a person, not another restart.
    if deaths.Length > 5 {
        if deaths.Length = 6
            WmLog("GlazeWM stopped " deaths.Length " times in 5 min: leaving it alone")
        return
    }
    WmLog("GlazeWM stopped: restarting it")
    SplitPath exe, , &dir
    try Run('"' exe '"', dir)
    catch as e
        WmLog("GlazeWM restart failed: " e.Message)
}

; --- Screensaver (Omarchy: effects after 2.5 min idle; any input ends it) -----
SsFlag := Env("data") "\generated\screensaver-off"
SsTitle := "Omarchy Screensaver ahk_exe WindowsTerminal.exe"
SsActive := false, SsStart := 0, SsArmed := 0, SsMouse := [0, 0]
SsConfigured := Env("screensaver", "0") = "1"
SsEnabled := SsConfigured && !FileExist(SsFlag)
RestoreCursors()              ; an older version hid the pointer during the screensaver
ScreensaverStop("startup")    ; older versions left hidden screensaver windows running
OnExit ScreensaverStop
SetTimer ScreensaverIdle, 5000
#DllLoad "*i xinput1_4.dll"
if SsConfigured
    SetTimer PadWatch, 1000

OnPowerBroadcast(wParam, *) {
    global QuietUntil
    if wParam = 4 {                                   ; PBT_APMSUSPEND: about to sleep
        ScreensaverStop("sleep")
    } else if wParam = 7 || wParam = 0x12 {           ; PBT_APMRESUMESUSPEND / RESUMEAUTOMATIC
        ScreensaverStop("wake")
        QuietUntil := A_TickCount + 180000
    }
}

OnSessionChange(wParam, *) {
    global QuietUntil
    if wParam = 7                                     ; WTS_SESSION_LOCK
        ScreensaverStop("lock")
    else if wParam = 8                                ; WTS_SESSION_UNLOCK
        QuietUntil := A_TickCount + 180000
}

ScreensaverIdle() {
    global SsActive, SsEnabled, QuietUntil, LastPad
    ; Idle = no keyboard, mouse or gamepad (Windows doesn't count gamepad input).
    idle := Min(A_TimeIdlePhysical, A_TickCount - LastPad)
    if SsActive || !SsEnabled || A_TickCount < QuietUntil || idle < Env("screensaverIdle", 150) * 1000
        return
    ; Not while something keeps the display on (video, presentation, Stay Awake),
    ; the session is locked, or a game / fullscreen app is in front.
    if DisplayRequired() || !InputDesktopActive() || Busy()
        return
    ScreensaverStart()
}

; Gamepad input (XInput pads, which is what most games and Playnite use): buttons,
; triggers and sticks beyond their dead zone, sampled every second.
PadWatch() {
    global LastPad
    static last := Map(), retry := Map(), state := Buffer(16)
    loop 4 {
        pad := A_Index - 1
        if retry.Has(pad) && A_TickCount < retry[pad]
            continue
        try r := DllCall("xinput1_4\XInputGetState", "uint", pad, "ptr", state, "uint")
        catch {
            SetTimer PadWatch, 0            ; no XInput on this PC
            return
        }
        if r != 0 {                          ; not connected: look again in 10 s
            retry[pad] := A_TickCount + 10000
            if last.Has(pad)
                last.Delete(pad)
            continue
        }
        s := NumGet(state, 4, "ushort") "," (NumGet(state, 6, "uchar") > 40) "," (NumGet(state, 7, "uchar") > 40)
        loop 4                               ; sticks: a resting stick's jitter stays 0
            s .= "," Round(NumGet(state, 6 + 2 * A_Index, "short") / 12000)
        if last.Has(pad) && last[pad] != s
            LastPad := A_TickCount
        last[pad] := s
    }
}

ScreensaverStart() {
    global SsActive, SsStart, SsArmed
    if SsActive
        return
    if !Env("wt") {
        Osd("The screensaver needs Windows Terminal")
        return
    }
    SsActive := true, SsStart := A_TickCount, SsArmed := 0
    WmLog("screensaver: start")
    PerMonitorDpi()
    loop MonitorGetCount() {
        MonitorGet A_Index, &l, &t
        ; Never with "Hide": Windows Terminal honours it and the window stays invisible.
        try Run('wt.exe -w new --pos ' (l + 40) ',' (t + 40) ' --fullscreen -p "' Env("screensaverProfile", "Omarchy Screensaver") '"')
    }
    SetTimer ScreensaverWatch, 100
}

ScreensaverWatch() {
    global SsStart, SsArmed, SsMouse, SsTitle
    DetectHiddenWindows true
    PerMonitorDpi()
    CoordMode "Mouse", "Screen"
    wins := WinGetList(SsTitle)
    if !SsArmed {
        ; Terminal takes a moment: arm once every monitor has its window.
        waited := A_TickCount - SsStart
        if wins.Length >= MonitorGetCount() || (wins.Length && waited > 6000)
            SsArmed := A_TickCount, ScreensaverPlace(wins), WmLog("screensaver: " wins.Length " window(s) after " waited " ms")
        else if waited > 15000
            ScreensaverStop("no window appeared")
        return
    }
    since := A_TickCount - SsArmed
    ; 1.5 s grace from when the windows appeared (a Preview is started with the mouse);
    ; the input baseline (pointer position) is taken at its end.
    if since < 1500 {
        if since > 600 && since < 800
            ScreensaverPlace(wins)      ; again, in case GlazeWM touched one
        MouseGetPos &mx, &my
        SsMouse := [mx, my]
        return
    }
    MouseGetPos &mx, &my
    jiggle := Round(10 * MonitorDpi(MonitorUnderMouse()) / 96)
    if A_TimeIdleKeyboard < since - 1500
        ScreensaverStop("key")
    else if Abs(mx - SsMouse[1]) > jiggle || Abs(my - SsMouse[2]) > jiggle
        ScreensaverStop("mouse moved " Abs(mx - SsMouse[1]) "," Abs(my - SsMouse[2]) " px")
    else if GetKeyState("LButton", "P") || GetKeyState("RButton", "P") || GetKeyState("MButton", "P")
        ScreensaverStop("click")
    else if LastPad > SsArmed + 1500
        ScreensaverStop("gamepad")
    else if !wins.Length
        ScreensaverStop("closed")
    else if !InputDesktopActive()
        ScreensaverStop("locked")
    else if A_TickCount - SsStart > 4 * 3600000
        ScreensaverStop("timeout")
}

; Each window visible, topmost and covering its monitor, and not tiled by GlazeWM.
ScreensaverPlace(wins) {
    for i, hwnd in wins {
        try {
            if info := GlazeWindowInfo(hwnd)
                RunWait('"' GlazeCli '" command --id ' info.id ' ignore', , "Hide")
            WinShow hwnd
            MonitorGet MonitorOfWindow(hwnd), &l, &t, &r, &b
            WinGetPos &x, &y, &w, &h, hwnd
            if x != l || y != t || w != r - l || h != b - t
                WinMove l, t, r - l, b - t, hwnd
            WinSetAlwaysOnTop 1, hwnd
            if i = 1
                WinActivate hwnd
        }
    }
}

; Closes every screensaver window, hidden ones included, and anything they left
; running (older versions started them hidden, so they outlived every stop). Safe anytime.
ScreensaverStop(reason := "exit", *) {
    global SsActive, SsTitle
    SetTimer ScreensaverWatch, 0
    wasActive := SsActive
    SsActive := false
    DetectHiddenWindows true
    left := 0
    for hwnd in WinGetList(SsTitle) {
        try PostMessage 0x10, 0, 0, , hwnd
        left++
    }
    try {
        for proc in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='pwsh.exe' OR Name='powershell.exe'")
            if InStr(proc.CommandLine, "\lib\screensaver.ps1")
                ProcessClose proc.ProcessId
    }
    loop 20 {
        if !ProcessExist("ttfx.exe")
            break
        ProcessClose "ttfx.exe"
    }
    if wasActive
        WmLog("screensaver: stop (" (IsObject(reason) ? "exit" : reason) ")")
    else if left
        WmLog("screensaver: closed " left " leftover window(s)")
}

ToggleScreensaver() {
    global SsEnabled, SsFlag, SsConfigured
    if !SsConfigured {
        Osd("Screensaver is off in Setup > Settings")
        return
    }
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
    WriteIndicatorsSoon(300)
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
    WriteIndicatorsSoon(100)
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
    ; Snipping Tool's region snip by its URI rather than by sending Win+Shift+S, which a
    ; script of yours may have taken for something else.
    try Run "ms-screenclip:"
    catch
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
            Osd(m[1], 3000, "top")
            return
        }
    }
    Osd("No weather yet", 3000, "top")
    OmarchyCmd("weather")
}

; --- Activity (Omarchy: btop) -------------------------------------------------------
Activity() {
    btop := Env("btop")
    if btop && FileExist(btop)
        RunWt('-w new --title Activity "' btop '"', '"' btop '"')
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

; Reload the system pointers (undoes any hidden-cursor state; the screensaver no
; longer hides the pointer: a system-wide change is too risky around sleep/lock).
RestoreCursors() {
    DllCall("SystemParametersInfo", "uint", 0x57, "uint", 0, "ptr", 0, "uint", 0)   ; SPI_SETCURSORS
}

WmLog(msg) {
    try FileAppend FormatTime(, "HH:mm:ss") " [wm] " msg "`n", Env("log", A_Temp "\winarchy.log"), "UTF-8"
}

BarGuard() {
    global BarEnabled, Zebar
    static lastRestart := 0
    if !BarEnabled || Busy()      ; a game changing display modes: see FullscreenWatch
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

RestartBar(*) {
    global BarEnabled, Zebar, DisplayPending
    HideTaskbars()
    if !BarEnabled
        return
    ; New bar windows over a game, then GlazeWM redrawing it, knock it out of
    ; fullscreen: it switches display mode again and it all repeats. After it closes.
    if Busy() {
        DisplayPending := true
        return
    }
    CloseBar()
    try Run('"' Zebar '" startup', , "Hide")
    ; A game may be open on another workspace (cloaked, or auto-minimized from losing
    ; foreground on the workspace switch): a redraw resizes and frame-changes every
    ; managed window, including a hidden one, which is what leaves it black afterwards.
    if !GameOpen()
        SetTimer () => Glaze("wm-redraw"), -2500
}

; A monitor was added or removed (laptop dock/undock, or an Apollo/Sunshine stream's
; virtual display appearing/disappearing): re-split the workspaces. Games switch display
; modes too, and streaming ends with real monitors reappearing while a game may still be
; open on another workspace: both wait for every game to close, not just the one in front
; (RestartBar still brings the bar back promptly - see its own GameOpen check above).
OnDisplayChange() {
    global MonitorCount, DisplayPending
    if Busy() || GameOpen() {
        if !DisplayPending
            WmLog("display changed under a game / fullscreen app: bar and workspaces follow when it closes")
        DisplayPending := true
        return
    }
    DisplayPending := false
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

; GlazeWM's gaps hold the bar's strip: the top gap is the bar height (when the bar
; is on) plus the normal gap (when gaps are on). GlazeWM scales both per monitor DPI,
; like Zebar scales the bar, so they line up on any screen.
ApplyGaps(gapsOn, barOn) {
    file := Env("glazeConfig")
    yaml := FileRead(file, "UTF-8")
    gap := Integer(Env("gap", 10)), barH := Integer(Env("barHeight", 26))
    new := RegExReplace(yaml, "'\d+px'(\s*# gaps)(?!:)", "'" (gapsOn ? gap : 0) "px'$1")
    new := RegExReplace(new, "'\d+px'(\s*# gaps:top)", "'" ((barOn ? barH : 0) + (gapsOn ? gap : 0)) "px'$1")
    if new != yaml {
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write(new)
        f.Close()
        Glaze("wm-reload-config")
    }
}

GapsOn() {
    try return !RegExMatch(FileRead(Env("glazeConfig"), "UTF-8"), "inner_gap:\s*'0px'")
    return true
}

; Topmost bar, but a fullscreen window (Super+F, video, game) may cover it.
FullscreenWatch() {
    global BarEnabled, BusyUntil, DisplayPending, Games
    static lastHomeCheck := 0
    PerMonitorDpi()
    covered := CoveredMonitors()
    if covered.Count || GameRunning() || FullscreenState()
        BusyUntil := A_TickCount + 5000
    ; The heavy catch-up (monitor resplit, workspace repair, a redrawing wm-redraw) waits
    ; for every game to finish, not just the grace period after one was last in front.
    else if DisplayPending && A_TickCount >= BusyUntil && !GameOpen() {
        DisplayPending := false
        WmLog("display change applied (was held for a game)")
        SetTimer OnDisplayChange, -500      ; what waited for the game to close
    }
    ; Games and their workspaces (GameWorkspaceSync): the event hooks cover almost every
    ; switch, but going from a workspace that held only the game to an empty one cloaks
    ; nothing and may not move the focus. So also look now and then while a game is in
    ; front, or while the desktop is (a game to bring back) - not on every 400ms tick.
    if Games.Count && A_TickCount - lastHomeCheck > 1500 {
        fg := WinExist("A"), fgCls := ""
        try fgCls := WinGetClass("A")
        if Games.Has(fg) || fgCls = "" || fgCls ~= "^(Progman|WorkerW)$" {
            lastHomeCheck := A_TickCount
            GameWorkspaceSync()
        }
    }
    DetectHiddenWindows true
    if !BarEnabled {                        ; off: close any bar Zebar (re)opened
        if WinExist(BarTitle)
            CloseBar()
        return
    }
    for m, bar in BarWindows() {
        try {
            shown := WinGetStyle(bar.hwnd) & 0x10000000          ; WS_VISIBLE
            if covered.Has(m) {
                ; Hidden, not just put behind: a game in exclusive fullscreen and a
                ; topmost bar take turns on screen (the bar blinks over the game).
                if shown
                    DllCall("ShowWindow", "ptr", bar.hwnd, "int", 0)  ; SW_HIDE
            } else {
                if !shown
                    DllCall("ShowWindow", "ptr", bar.hwnd, "int", 8)  ; SW_SHOWNA
                if !(WinGetExStyle(bar.hwnd) & 0x8)
                    WinSetAlwaysOnTop 1, bar.hwnd
            }
        }
    }
}

; Bars hidden under a fullscreen window come back if this script exits.
ShowHiddenBars(*) {
    global BarEnabled
    if !BarEnabled
        return
    DetectHiddenWindows true
    for m, bar in BarWindows()
        try DllCall("ShowWindow", "ptr", bar.hwnd, "int", 8)
}

; --- Windows stay put: no minimizing -------------------------------------------------
; blockMinimize (config.json, default on): the taskbar is hidden, so a minimized window
; has no way back on its own. Two layers:
;   - Windows with a standard title bar lose WS_MINIMIZEBOX as they appear: the button
;     greys out and the title-bar menu's Minimize with it, so a minimize never starts.
;     Chrome/Electron/Store apps draw their own buttons and minimize themselves, so
;     the style doesn't stop them - the next layer does.
;   - SetWinEventHook undoes any minimize that does happen the moment it's done. apply
;     turns off the minimize animation (Set-MinimizeAnimationPolicy), so that's a
;     one-frame blink rather than the window shrinking away and growing back.
; (A game / fullscreen app snapping back on Alt+Tab, then re-fullscreening, would loop
; the same way the old bar/GlazeWM redraw loop did - IsMinimizeAllowed excuses those.)
; Super+M is the rescue key: it restores everything, allowed or not.

; Drop the hooks and put the minimize buttons back on the way out (uninstall, or a
; reload). A named function, and no value returned: a
; non-zero return from an OnExit callback cancels the exit, and UnhookWinEvent answers
; 1 - as a one-liner here it kept the script from ever exiting (so Reload never took).
UnhookMinimize(*) {
    global MinimizeHook, ShowHook
    if MinimizeHook
        DllCall("UnhookWinEvent", "ptr", MinimizeHook)
    if ShowHook
        DllCall("UnhookWinEvent", "ptr", ShowHook)
    MinimizeHook := ShowHook := 0
    RestoreMinimizeBoxes()
}

; EVENT_SYSTEM_MINIMIZESTART callback (idObject/idChild/idEventThread/dwmsEventTime
; unused: only top-level windows, object 0, matter here).
OnWindowMinimized(hWinEventHook, event, hwnd, idObject, idChild, *) {
    if idObject != 0 || idChild != 0 || !hwnd
        return
    SetTimer(RestoreBlocked.Bind(hwnd), -1)
}

; Undo it as soon as the window is minimized (the event can arrive a moment before
; that's finished: check again a few times rather than waiting a fixed while).
RestoreBlocked(hwnd, tries := 0) {
    global BlockMinimize
    if !BlockMinimize
        return
    try {
        if !DllCall("IsWindow", "ptr", hwnd)
            return
        if !DllCall("IsIconic", "ptr", hwnd) {
            if tries < 5
                SetTimer(RestoreBlocked.Bind(hwnd, tries + 1), -10)
            return
        }
        if IsMinimizeAllowed(hwnd)
            return
        WinRestore hwnd
        WinActivate hwnd
    }
}

; EVENT_OBJECT_SHOW callback: fires for every control too, so only top-level windows
; go on (to a timer: the style check wants a moment and this callback must be quick).
OnWindowShown(hWinEventHook, event, hwnd, idObject, idChild, *) {
    if idObject != 0 || idChild != 0 || !hwnd
        return
    if DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") != hwnd    ; GA_ROOT: top-level only
        return
    ; Explorer re-shows the taskbar when windows come and go (opening and closing the menu
    ; quickly); the 1 s poll alone left it up for a moment, so hide it again right away.
    try {
        if WinGetClass(hwnd) ~= "^(Shell_TrayWnd|Shell_SecondaryTrayWnd)$" {
            SetTimer(HideTaskbars, -1)
            return
        }
    }
    ; No Windows open/close fade or zoom on this window (DWMWA_TRANSITIONS_FORCEDISABLED):
    ; it lives on the window, so nothing needs undoing when this script exits.
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 3, "int*", 1, "uint", 4)
    SetTimer(StripMinimizeBox.Bind(hwnd), -1)
}

; Take the minimize button off one window, unless it's allowed to minimize (games,
; Playnite, dialogs, config "minimizeAllowed") or has no normal title bar to change.
; The window keeps a property saying so, so a later instance of this script can put the
; button back even after this one was force-stopped (apply restarts it that way).
StripMinimizeBox(hwnd) {
    global BlockMinimize
    if !BlockMinimize
        return
    try {
        style := WinGetStyle(hwnd)
        if !(style & 0x20000) || (style & 0xC00000) != 0xC00000 || !(style & 0x80000)   ; WS_MINIMIZEBOX, WS_CAPTION, WS_SYSMENU
            return
        if IsMinimizeAllowed(hwnd)
            return
        WinSetStyle "-0x20000", hwnd
        DllCall("SetPropW", "ptr", hwnd, "str", "winarchy.nomin", "ptr", 1)
    }
}

; Windows already open when this script starts; one that lost its button earlier but may
; minimize now (config "minimizeAllowed" changed, recognised as a game) gets it back.
StripAllMinimizeBoxes() {
    for hwnd in WinGetList() {
        try {
            if DllCall("GetPropW", "ptr", hwnd, "str", "winarchy.nomin", "ptr") && IsMinimizeAllowed(hwnd)
                RestoreMinimizeBox(hwnd)
            else
                StripMinimizeBox(hwnd)
        }
    }
}

RestoreMinimizeBoxes(*) {
    for hwnd in WinGetList() {
        if DllCall("GetPropW", "ptr", hwnd, "str", "winarchy.nomin", "ptr")
            RestoreMinimizeBox(hwnd)
    }
}

RestoreMinimizeBox(hwnd) {
    try WinSetStyle "+0x20000", hwnd
    DllCall("RemovePropW", "ptr", hwnd, "str", "winarchy.nomin", "ptr")
}

; Windows this script leaves free to minimize: tool/owned windows (dialogs, popups -
; usually can't be minimized anyway), games (exclusive fullscreen auto-minimizes on
; losing focus), Playnite/Steam Big Picture, and config "minimizeAllowed".
IsMinimizeAllowed(hwnd) {
    try {
        if !IsRestorableWindow(hwnd)
            return true
        if IsGame(hwnd)
            return true
        name := RegExReplace(WindowProcessName(hwnd), "i)\.exe$")
    } catch
        return true
    return name ~= "i)^(zebar|Playnite\.FullscreenApp|Playnite\.DesktopApp)$"
        || GameNames().Has(name)
        || MinimizeAllowedNames().Has(name)
}

MinimizeAllowedNames() {
    static names := 0
    if !names {
        names := Map()
        names.CaseSense := false
        for g in StrSplit(Env("minimizeAllowed"), "|")
            if g := Trim(RegExReplace(g, "i)\.exe$"))
                names[g] := true
    }
    return names
}

; A real top-level window worth restoring: visible, no owner, not a tool window.
IsRestorableWindow(hwnd) {
    return (WinGetStyle(hwnd) & 0x10000000)                              ; WS_VISIBLE
        && !(WinGetExStyle(hwnd) & 0x80)                                 ; WS_EX_TOOLWINDOW
        && !DllCall("GetWindow", "ptr", hwnd, "uint", 4)                 ; GW_OWNER
}

; Super + M / Super + Home: bring back every minimized window, whether blockMinimize
; would have allowed it or not (games included) - the one way back with no taskbar.
RestoreAll(*) {
    n := 0
    fg := WinExist("A")
    for hwnd in WinGetList() {
        try {
            if DllCall("IsIconic", "ptr", hwnd) && IsRestorableWindow(hwnd) {
                WinRestore hwnd
                n++
            }
        }
    }
    if fg && DllCall("IsWindow", "ptr", fg)
        try WinActivate fg
    Osd(n ? "Restored " n " window" (n = 1 ? "" : "s") : "Nothing minimized")
}

; --- Games keep the foreground -----------------------------------------------------
; A game lost the foreground: always logged (what took it is the one thing worth knowing
; when a game keeps minimizing), and handed back unless you asked for the switch - a key,
; a click or pad input just before it - or the new window is one that may cover a game
; (the game's own windows, another game, UAC, Game Bar, Steam's overlay, Playnite, the
; screensaver, config "minimizeAllowed"). Background programs starting up, GlazeWM
; re-syncing its own focus, ... are what's left, and those are what minimized games.
; Capped: a window that keeps taking it back wins after 4 tries in 20 s (for a minute),
; rather than the two ping-ponging - the same kind of loop as the old bar/redraw one.

UnhookForeground(*) {
    global ForegroundHook
    if ForegroundHook
        DllCall("UnhookWinEvent", "ptr", ForegroundHook)
    ForegroundHook := 0
}

; EVENT_SYSTEM_FOREGROUND callback: no work here, just remember and hand it on. The idle
; time is read now, before anything else can happen: physical input only (the keyboard
; and mouse hooks are installed), so GlazeWM's own synthetic Alt press doesn't count.
OnForeground(hWinEventHook, event, hwnd, idObject, idChild, *) {
    global LastFg
    if idObject != 0 || !hwnd
        return
    prev := LastFg, LastFg := hwnd
    if prev && prev != hwnd
        SetTimer(GameFocusLost.Bind(prev, hwnd, A_TimeIdlePhysical), -1)
}

GameFocusLost(game, taker, idle) {
    global Games, LastPad, GameParked
    static tries := Map(), pausedUntil := Map()     ; game hwnd -> [ticks] / tick
    if !Games.Has(game) || !DllCall("IsWindow", "ptr", game)
        return
    if GameParked.Has(game)                        ; you left its workspace: meant to go
        return
    try {
        gamePid := WinGetPID(game)
        DetectHiddenWindows true
        exe := WinGetProcessName(taker), cls := WinGetClass(taker), title := WinGetTitle(taker)
        takerPid := WinGetPID(taker)
    } catch
        return                                     ; the new window is already gone
    if takerPid = gamePid || Games.Has(taker)
        return
    admin := IsElevated(gamePid)
    ; An admin game hides your keys and clicks from this script (its hooks are blind while
    ; that game is in front): the helper, which does see them, makes the call instead.
    asked := (!admin && idle < 1000) || A_TickCount - LastPad < 1500
    WmLog("game lost focus: " Games[game] " -> " exe " [" cls "] '" SubStr(title, 1, 60) "'"
        . (admin ? " (admin game)" : ", " idle " ms after your last input"))
    if asked || FocusMayCoverGame(taker, exe, cls)
        return
    if pausedUntil.Has(game) && A_TickCount < pausedUntil[game]
        return
    recent := []
    for t in (tries.Has(game) ? tries[game] : [])
        if A_TickCount - t < 20000
            recent.Push(t)
    if recent.Length >= 4 {
        tries.Delete(game)
        pausedUntil[game] := A_TickCount + 60000
        WmLog("game focus: " exe " took it " recent.Length " times in 20 s; leaving it for a minute")
        return
    }
    recent.Push(A_TickCount)
    tries[game] := recent
    SetTimer(GiveFocusBack.Bind(game, admin), -150)
}

; Windows allowed to come in front of a game without it being taken back.
FocusMayCoverGame(hwnd, exe, cls) {
    global SsActive, UacClass
    if SsActive || (cls != "" && InStr(UacClass, cls))
        return true
    name := RegExReplace(exe, "i)\.exe$")
    return name ~= "i)^(consent|GameBar|GameBarFTServer|GameBarPresenceWriter|gameoverlayui|gameoverlayui64|Playnite\.FullscreenApp|Playnite\.DesktopApp)$"
        || GameNames().Has(name)
        || MinimizeAllowedNames().Has(name)
}

GiveFocusBack(game, admin) {
    global Games
    if !DllCall("IsWindow", "ptr", game) || WinExist("A") = game
        return
    if admin {
        if helper := GameHelper() {
            PostMessage 0x5556, 3, game, , helper     ; restore + activate, unless you asked
            WmLog("game focus: asked the admin helper to give it back to " Games[game])
        } else
            WmLog("game focus: " Games[game] " runs as administrator: run 'winarchy game-setup' once so it can be given back")
        return
    }
    RestoreAndActivate(game)
    WmLog("game focus: gave it back to " Games[game])
}

; --- Games and fullscreen apps: stand back ------------------------------------------
; A game that switches display mode used to loop with this script: mode change ->
; bar restart (new topmost windows over the game) + GlazeWM redraw (re-tiling it) ->
; the game drops out of fullscreen and switches again. So while a game or fullscreen
; app is in front: GlazeWM ignores the game, the bar stays behind it, display changes,
; bar restarts and the screensaver wait until it closes.
; Games = the ones Windows' Game Bar recognised (GameConfigStore, like the GlazeWM
; ignore rules winarchy apply writes) + config "games". config "gameMode": false = off.

; {monitor: window} for each monitor whose front window is fullscreen or a game:
; the focused window, or the one showing at the monitor's centre (overlays such as
; NVIDIA's or Steam's are click-through, so they don't count).
; IsGame is checked first: a fullscreen window short-circuits IsFullscreenWindow||IsGame
; the other way round, so a game that already fills the screen (most of them, once
; started) would never reach IsGame and so never get registered or ignored.
CoveredMonitors() {
    covered := Map()
    ; (try: any of these windows can close between two calls)
    try {
        if (fg := WinExist("A")) && WinGetMinMax(fg) != -1 && (IsGame(fg) || IsFullscreenWindow(fg))
            covered[MonitorOfWindow(fg)] := fg
    }
    loop MonitorGetCount() {
        if covered.Has(A_Index)
            continue
        try {
            MonitorGet A_Index, &l, &t, &r, &b
            top := RootWindowAt((l + r) // 2, (t + b) // 2)
            if top && (IsGame(top) || IsFullscreenWindow(top)) && MonitorOfWindow(top) = A_Index
                covered[A_Index] := top
        }
    }
    return covered
}

RootWindowAt(x, y) {
    hwnd := DllCall("WindowFromPoint", "int64", (x & 0xFFFFFFFF) | (y << 32), "ptr")
    return hwnd ? DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") : 0
}

; A game or fullscreen app is (or was a moment ago) in front: nothing may pop over it.
Busy() {
    global BusyUntil
    PerMonitorDpi()
    return A_TickCount < BusyUntil || GameRunning() || FullscreenState() || CoveredMonitors().Count > 0
}

; Windows' own view: a fullscreen app (2), an exclusive-fullscreen Direct3D game (3)
; or presentation mode (4).
FullscreenState() {
    state := 0
    try DllCall("shell32\SHQueryUserNotificationState", "int*", &state)
    return state >= 2 && state <= 4
}

; Is this window a game's? New ones are logged and taken out of GlazeWM's tiling
; (the apply-time rules already cover games Windows knew about then). A process
; counts as a game if Windows' Game Bar (or config "games") knows it, its executable
; sits in a game library folder (config "gameDirs" + the common launchers' own), or
; it was started (however many hops back) by Playnite.
IsGame(hwnd) {
    global Games, GameMode, GameHome
    static byPid := Map()        ; pid -> {name: game process name or "", t: when checked}
    if !GameMode || !hwnd
        return false
    if Games.Has(hwnd)
        return true
    try {
        ; By process, so a game's window counts as soon as it shows (it may start hidden).
        pid := WinGetPID(hwnd)
        if !byPid.Has(pid) || (byPid[pid].name = "" && A_TickCount - byPid[pid].t > 30000) {
            if byPid.Count > 300
                byPid.Clear()
            path := WindowProcessPath(hwnd)
            SplitPath path, &procName
            stem := RegExReplace(procName, "i)\.exe$")
            isGame := stem != "" && (GameNames().Has(stem) || InGameLibrary(path) || HasPlayniteAncestor(pid))
            byPid[pid] := {name: isGame ? stem : "", t: A_TickCount}
        }
        name := byPid[pid].name
        if name = "" || !(WinGetStyle(hwnd) & 0x10000000)                 ; WS_VISIBLE
            return false
    } catch
        return false
    Games[hwnd] := name
    info := GlazeWindowInfo(hwnd)          ; also used below, so read it just once
    if home := HomeWorkspace(hwnd, info)   ; also when GlazeWM never managed it (apply rules)
        GameHome[hwnd] := home
    admin := IsElevated(pid)
    WmLog("game: " name " (GlazeWM leaves it alone; the bar hides behind it)"
        . (admin ? "; runs as administrator" (GameHelper() ? "" : ": run 'winarchy game-setup' once so Super+W and the bar can close it") : ""))
    if info
        try Run('"' GlazeCli '" command --id ' info.id ' ignore', , "Hide")
    WriteIndicatorsSoon(10)                     ; the game icon in the bar
    return true
}

; Common game library folders (Steam, Epic, Xbox, GOG, EA, Ubisoft) + config "gameDirs":
; catches a game Windows' Game Bar never learned about (it only sees ones it detected
; being played fullscreen at least once), by where it's installed rather than its name.
InGameLibrary(path) {
    if !path
        return false
    if path ~= "i)\\(steamapps\\common|Epic Games|XboxGames|GOG Galaxy\\Games|EA Games|Ubisoft Game Launcher\\games)\\"
        return true
    for dir in StrSplit(Env("gameDirs"), "|") {
        dir := Trim(RegExReplace(dir, "\\+$", ""))
        if dir && StrLen(path) > StrLen(dir) && SubStr(path, 1, StrLen(dir)) = dir && SubStr(path, StrLen(dir) + 1, 1) = "\"
            return true
    }
    return false
}

; A launcher (Playnite) started this process, however many hops back: its games are
; children of Playnite.FullscreenApp.exe / Playnite.DesktopApp.exe. One WMI hop per
; ancestor, but only the first time a pid is seen (IsGame caches the result per pid).
HasPlayniteAncestor(pid) {
    loop 6 {
        pid := ParentPid(pid)
        if !pid
            return false
        if ProcessNameByPid(pid) ~= "i)^Playnite\.(Fullscreen|Desktop)App\.exe$"
            return true
    }
    return false
}

ParentPid(pid) {
    try {
        for p in ComObjGet("winmgmts:").ExecQuery("SELECT ParentProcessId FROM Win32_Process WHERE ProcessId=" pid)
            return p.ParentProcessId
    }
    return 0
}

ProcessNameByPid(pid) {
    try {
        for p in ComObjGet("winmgmts:").ExecQuery("SELECT Name FROM Win32_Process WHERE ProcessId=" pid)
            return p.Name
    }
    return ""
}

; Drops closed games (and their remembered home workspace), logging each.
PruneGames() {
    global Games, GameHome, GameParked
    for hwnd, name in Games.Clone() {
        if !DllCall("IsWindow", "ptr", hwnd) {
            Games.Delete(hwnd)
            if GameHome.Has(hwnd)                     ; not set while its workspace was unknown
                GameHome.Delete(hwnd)
            if GameParked.Has(hwnd)
                GameParked.Delete(hwnd)
            WmLog("game closed: " name)
            WriteIndicatorsSoon(10)
        }
    }
}

; A game window is open and not minimized (screensaver suppression, the bar icon).
GameRunning() {
    global Games
    PruneGames()
    for hwnd in Games
        if DllCall("IsWindowVisible", "ptr", hwnd) && !DllCall("IsIconic", "ptr", hwnd)
            return true
    return false
}

; A game window is open at all: still on some workspace, even minimized or cloaked
; behind another one. Held-back display/bar/workspace work waits for this (not just
; GameRunning, which drops the moment an exclusive-fullscreen game auto-minimizes on
; losing focus - long before the game process itself is done needing to be left alone).
GameOpen() {
    global Games
    PruneGames()
    return Games.Count > 0
}

; The game window the bar's game icon stands for: the focused one, else any open one.
GameWindow() {
    global Games
    if Games.Has(fg := WinExist("A"))
        return fg
    for hwnd in Games
        if DllCall("IsWindow", "ptr", hwnd)
            return hwnd
    return 0
}

GameTitle(hwnd) {
    global Games
    title := ""
    DetectHiddenWindows true                          ; a game may hide its window
    try title := Trim(WinGetTitle(hwnd))
    return title != "" ? title : Games.Has(hwnd) ? Games[hwnd] : ""
}

; Bar game icon, click: back to the game (the taskbar is hidden, and GlazeWM ignores it).
; A game parked on a workspace you left: go to that workspace, which brings it back.
FocusGame() {
    global GameHome, GameParked
    if !(hwnd := GameWindow())
        return
    if GameParked.Has(hwnd) && GameHome.Has(hwnd) {
        Glaze("focus --workspace " GameHome[hwnd])
        SetTimer GameWorkspaceSync, -400
    } else
        GameShow(hwnd, true)
}

; Un-minimize (if needed) and activate a game window (GameShow, GiveFocusBack).
RestoreAndActivate(hwnd) {
    DetectHiddenWindows true
    try {
        if WinGetMinMax(hwnd) = -1
            WinRestore hwnd
        WinActivate hwnd
    }
}

; --- Games stay on their workspace -------------------------------------------------
; GlazeWM ignores games (tiling one knocks it out of fullscreen), and so it never hides
; one when you switch away from its workspace: the game stayed in front and kept the
; focus. So this does what GlazeWM would have: a game whose workspace is no longer shown
; is minimized ("parked"), and GlazeWM's focused window gets the foreground; showing that
; workspace again brings the game back in front. Admin games go through the game helper.
; A parked game you bring back yourself (Alt+Tab) takes you to its workspace instead.

; The name of the workspace a game belongs to: the one GlazeWM had it in (info from
; GlazeWindowInfo), else the one shown where the window is (games the apply-time rules
; ignore were never managed at all). "" when neither can be told (window minimized).
HomeWorkspace(hwnd, info := 0) {
    list := WorkspaceList(GlazeQuery("workspaces"))
    if info
        for w in list
            if w.id = info.workspace
                return w.name
    try {
        PerMonitorDpi()
        if WinGetMinMax(hwnd) = -1
            return ""
        WinGetPos &x, &y, &ww, &hh, hwnd
        cx := x + ww // 2, cy := y + hh // 2
        for w in list
            if w.displayed && cx >= w.x && cx < w.x + w.w && cy >= w.y && cy < w.y + w.h
                return w.name
    }
    return ""
}

; [{id, name, displayed, x, y, w, h}] from `glazewm query workspaces`. A workspace's own
; fields follow its children: "isDisplayed" is workspace-only (a window has
; "displayState"), so the first one after a workspace's id is that workspace's.
WorkspaceList(json) {
    list := [], p := 1
    while p := RegExMatch(json, '"type":"workspace","id":"([^"]+)","name":"([^"]+)"[\s\S]*?"isDisplayed":(true|false),"width":(-?\d+),"height":(-?\d+),"x":(-?\d+),"y":(-?\d+)', &m, p) {
        list.Push({id: m[1], name: m[2], displayed: m[3] = "true"
            , w: Integer(m[4]), h: Integer(m[5]), x: Integer(m[6]), y: Integer(m[7])})
        p += m.Len
    }
    return list
}

UnhookWorkspace(*) {
    global WorkspaceHooks
    for h in WorkspaceHooks
        if h
            DllCall("UnhookWinEvent", "ptr", h)
    WorkspaceHooks := []
}

; Focus changed or GlazeWM (un)cloaked a window: maybe a workspace switch. Nothing to do
; unless a game is open; a burst of events (a switch cloaks every window) is one check.
OnWorkspaceEvent(hWinEventHook, event, hwnd, idObject, idChild, *) {
    global Games
    if idObject = 0 && Games.Count
        SetTimer GameWorkspaceSync, -150
}

GameWorkspaceSync() {
    global Games, GameHome, GameParked
    static running := false
    if running {                                  ; a query is in flight: look again after
        SetTimer GameWorkspaceSync, -300
        return
    }
    PruneGames()
    if !Games.Count
        return
    running := true
    try {
        list := WorkspaceList(GlazeQuery("workspaces"))
        shown := Map()
        for w in list
            shown[w.name] := w.displayed
        fg := WinExist("A"), fgCls := ""
        try fgCls := WinGetClass("A")
        desktop := fgCls = "" || fgCls ~= "^(Progman|WorkerW)$"
        parked := false
        DetectHiddenWindows true
        for hwnd, name in (list.Length ? Games.Clone() : Map()) {
            if !DllCall("IsWindow", "ptr", hwnd)
                continue
            minimized := DllCall("IsIconic", "ptr", hwnd)
            if !GameHome.Has(hwnd) {                  ; not known yet (it was minimized)
                if !minimized && (home := HomeWorkspace(hwnd))
                    GameHome[hwnd] := home
                continue
            }
            ws := GameHome[hwnd]
            if !shown.Has(ws)                         ; that workspace is gone (config changed)
                continue
            if !shown[ws] {
                if !GameParked.Has(hwnd) {
                    ; Left its workspace. Also when it minimized itself on losing the focus:
                    ; it is still parked, so it comes back with its workspace.
                    GameParked[hwnd] := A_TickCount
                    if !minimized {
                        GameShow(hwnd, false)
                        parked := true
                    }
                    WmLog("game parked: " name " (left workspace " ws ")")
                } else if !minimized && A_TickCount - GameParked[hwnd] > 1500 {
                    ; Brought back by hand (Alt+Tab, a click): follow it to its workspace.
                    GameParked.Delete(hwnd)
                    WmLog("game brought back: " name " -> workspace " ws)
                    Glaze("focus --workspace " ws)
                    SetTimer GameShow.Bind(hwnd, true), -300
                }
            } else if GameParked.Has(hwnd) {
                GameParked.Delete(hwnd)
                GameShow(hwnd, true)
                WmLog("game restored: " name " (workspace " ws " shown again)")
            } else if desktop && fg != hwnd {
                ; Its workspace is shown and nothing else is in front there: GlazeWM has
                ; nothing of its own to focus on it, so the game gets it.
                GameShow(hwnd, true)
                desktop := false
            }
        }
        if parked
            SetTimer FocusGlazeWindow, -250
    }
    running := false
}

; After a game is parked, Windows hands the foreground to whatever is next in z-order
; (maybe a cloaked window on another workspace): give it to GlazeWM's focused window, or
; the desktop when the workspace is empty.
FocusGlazeWindow() {
    json := GlazeQuery("focused")
    if RegExMatch(json, '"handle":(\d+)', &m) && DllCall("IsWindow", "ptr", Integer(m[1])) {
        try WinActivate Integer(m[1])
    } else
        try WinActivate "ahk_class Progman"
}

; Minimize (show = false) or restore and activate a game - through the admin game helper
; when the game runs as administrator (this script can't touch its windows then).
GameShow(hwnd, show) {
    static warned := false
    if !DllCall("IsWindow", "ptr", hwnd)
        return
    try pid := WinGetPID(hwnd)
    catch
        return
    if IsElevated(pid) {
        if helper := GameHelper()
            PostMessage 0x5556, show ? 5 : 4, hwnd, , helper
        else if !warned {
            warned := true
            WmLog("game workspaces: " GameTitle(hwnd) " runs as administrator: run 'winarchy game-setup' once so it can be hidden and brought back")
        }
        return
    }
    if show
        RestoreAndActivate(hwnd)
    else
        try WinMinimize hwnd
}

; Super + Ctrl + G: the focused window's process wasn't caught by IsGame's checks (not
; in a game library folder, no Playnite ancestor, unknown to Windows' Game Bar). Register
; it right away, and add it to config "games" so `winarchy apply` writes the matching
; GlazeWM ignore rule and it's caught automatically from then on (also after a restart).
MarkAsGame() {
    global Games, GameMode, GameHome
    if !(hwnd := WinExist("A")) {
        Osd("No window focused")
        return
    }
    if !GameMode {
        Osd("gameMode is off (config.json)")
        return
    }
    name := RegExReplace(WindowProcessName(hwnd), "i)\.exe$")
    if name = "" {
        Osd("Couldn't read that window's process")
        return
    }
    if !Games.Has(hwnd) {
        Games[hwnd] := name
        info := GlazeWindowInfo(hwnd)
        if home := HomeWorkspace(hwnd, info)
            GameHome[hwnd] := home
        if info
            try Run('"' GlazeCli '" command --id ' info.id ' ignore', , "Hide")
        WmLog("game: " name " (marked by hand, Super+Ctrl+G)")
        WriteIndicatorsSoon(10)
    }
    OmarchyCmd("game-add", name)
    Osd("Marked " name " as a game")
}

; Bar game icon right-click / Super+W / Super+Q on a game: close it like its own
; window's X (it may ask to save); again within 15 s: force-quit it.
; A game running as administrator is out of this script's reach (Windows blocks
; messages and force-quit from normal programs): the admin game helper does it.
CloseGame(hwnd := 0) {
    static asked := 0, askedPid := 0
    if !hwnd && !(hwnd := GameWindow()) {
        Osd("No game running")
        return
    }
    try pid := WinGetPID(hwnd), title := GameTitle(hwnd)
    catch
        return
    force := pid = askedPid && A_TickCount - asked < 15000
    asked := force ? 0 : A_TickCount, askedPid := force ? 0 : pid
    if IsElevated(pid) {
        if !(helper := GameHelper()) {
            WmLog("game close: " title " runs as administrator; no game helper")
            Osd(title " runs as administrator: run 'winarchy game-setup' once so Winarchy can close it", 6000)
            return
        }
        PostMessage 0x5556, force ? 2 : 1, hwnd, , helper
    } else if force {
        ProcessClose pid
    } else {
        PostMessage 0x10, 0, 0, , hwnd                ; WM_CLOSE
    }
    WmLog("game " (force ? "force-quit: " : "close: ") title)
    Osd(force ? title ": force-quit" : "Closing " title "  (again: force-quit)", 3000)
}

; The admin game helper's window (winarchy game-setup), or 0.
GameHelper() {
    DetectHiddenWindows true
    SetTitleMatchMode 2
    return WinExist("\game-helper.ahk ahk_class AutoHotkey")
}

; The process runs as administrator (elevated), so this script can't reach its windows.
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

; A window's program name, also for programs running as administrator (this asks
; Windows for no more access than it gives normal programs over admin ones).
WindowProcessName(hwnd) {
    path := WindowProcessPath(hwnd)
    if path {
        SplitPath path, &name
        return name
    }
    return WinGetProcessName(hwnd)
}

; Same, but the full path (so a game can be told apart by where it's installed).
WindowProcessPath(hwnd) {
    pid := WinGetPID(hwnd)
    if h := DllCall("OpenProcess", "uint", 0x1000, "int", 0, "uint", pid, "ptr") {
        buf := Buffer(2048), size := 1024
        ok := DllCall("QueryFullProcessImageNameW", "ptr", h, "uint", 0, "ptr", buf, "uint*", &size)
        DllCall("CloseHandle", "ptr", h)
        if ok
            return StrGet(buf, size, "UTF-16")
    }
    return ""
}

; Process names (no .exe) of games: Windows' Game Bar list + config "games".
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
            if stem && !(stem ~= "i)^(explorer|WindowsTerminal|pwsh|powershell|cmd|Code|chrome|msedge|firefox|zebar|glazewm)$")
                names[stem] := true
        }
    }
    for g in StrSplit(Env("games"), "|")
        if g := Trim(RegExReplace(g, "i)\.exe$"))
            names[g] := true
    return names
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
        case 6: Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" audio-panel')
        case 7: Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" bluetooth-panel')
        case 8: SetTimer ScreensaverStart, -400
        case 9: ToggleScreensaver()
        case 10: SetTimer CaptureText, -300
        case 11: ToggleNightlight()
        case 12: ToggleDnd()
        case 13: ShowWeather()
        case 14: Activity()
        case 15: SetTimer ShowUacPrompt, -10
        case 16: FocusGame()
        case 17: CloseGame()
        case 18: ToggleBar("on")
        case 19: ToggleBar("off")
        case 20: RestoreAll()
    }
}

; --- Keys -------------------------------------------------------------------
; Tapping or holding Super alone (or a quick Super+N handled by GlazeWM) must not
; open the Start menu. The unassigned vkE8 key masks the lone Win press: on press,
; and again on release, right before the Win key-up this hotkey sends (held down,
; Win auto-repeats after the first mask, and Windows then opened Start on release).
; Start menu is still on Ctrl+Esc.
~LWin::Send "{Blind}{vkE8}"
LWin up::Send "{Blind}{vkE8}{LWin up}"

; GlazeWM's close (Super+W / Super+Q) can't reach a game (GlazeWM ignores games):
; close it here. (Games is filled by FullscreenWatch, so this check stays instant.)
#HotIf Games.Has(WinExist("A"))
#w::
#q::CloseGame(WinExist("A"))
#HotIf

; Win+Space and its Ctrl/Shift variants are Windows' keyboard-layout switch.
; Omarchy uses them, so they are only taken over when config allows it
; (the installer asks when more than one layout / an IME is installed).
; Winarchy swaps Omarchy's pair: Super+Space is the menu, Super+Alt+Space the launcher.
; Left to Windows, Super+Space keeps switching layouts and the menu stays on
; Super+Alt+Space, so it is always one key away (the launcher is still Alt+Space).
if Env("takeOverWinSpace", "1") = "1" {
    Hotkey "#Space", (*) => OpenMenu("root")                       ; Omarchy menu
    Hotkey "#!Space", (*) => Send(Env("flowHotkey", "!{Space}"))   ; app launcher (Flow Launcher)
    Hotkey "#^Space", (*) => OpenMenu("background")                ; background picker
    Hotkey "#^+Space", (*) => OpenMenu("theme")                    ; theme picker
    Hotkey "#+Space", (*) => ToggleBar()                           ; top bar
} else
    Hotkey "#!Space", (*) => OpenMenu("root")                      ; Omarchy menu

; Herdr (Omarchy's terminal workspace). Windows keeps Super+Ctrl+Return for Narrator,
; so winarchy apply switches that shortcut off (Set-NarratorShortcut) for this to win.
#^Enter::Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" herdr')

; Nothing minimizes (blockMinimize): Windows' own minimize-everything keys are retaken
; too, or a window minimized before the hook could catch it (or one of the exceptions)
; would have no way back with the taskbar hidden. Win+M/Win+Home restore instead;
; Win+D (show desktop) would just minimize every tile, so it does nothing.
if BlockMinimize {
    Hotkey "#m", RestoreAll
    Hotkey "#Home", RestoreAll
    Hotkey "#d", (*) => 0
}

; Omarchy menus (Zebar menu widget)
#Escape::OpenMenu("system")           ; lock / suspend / restart / shutdown
#k::OpenMenu("keys")                  ; keybindings
#^c::OpenMenu("capture")              ; capture (also the way in without a PrtScn key)
#^o::OpenMenu("toggle")
#^h::OpenMenu("setup")

; Toggles
#Backspace::ToggleTransparency()      ; active window transparency
#+Backspace::ToggleGaps()             ; window gaps
#^i::ToggleAwake()                    ; stay awake

; Capture. Print is Windows' own region snip, Alt+Print records (both layouts).
;   "captureKeys": "omarchy" (new installs, Omarchy's keys): Super+Print picks a color,
;     Super+Ctrl+Print copies the text in a region, Shift+Print is Windows' full screenshot
;     saved to Pictures\Screenshots (what Super+Print does on Windows).
;   "winarchy" (installs from before): Super+Print stays Windows' save-to-Screenshots,
;     Super+Ctrl+Print picks a color, Super+Shift+Print copies text.
!PrintScreen::Send "#+r"              ; screen recording (Snipping Tool)
if Env("captureKeys", "winarchy") = "omarchy" {
    BindUnlessUser("#PrintScreen", (*) => SetTimer(ColorPicker, -10))
    BindUnlessUser("#^PrintScreen", (*) => SetTimer(CaptureText, -10))
    BindUnlessUser("+PrintScreen", (*) => Send("#{PrintScreen}"))
} else {
    BindUnlessUser("#^PrintScreen", (*) => SetTimer(ColorPicker, -10))
    BindUnlessUser("#+PrintScreen", (*) => SetTimer(CaptureText, -10))   ; text capture (OCR) -> clipboard
}

; CapsLock compose (lib\compose.ahk): emoji, em dash, name and email. Never over a game
; or a fullscreen app, where CapsLock stays CapsLock; both Shifts toggle Caps Lock.
if Env("compose", "0") = "1" {
    HotIf (*) => !Busy()
    BindUnlessUser("CapsLock", Compose)
    HotIf
    Hotkey "~LShift", ComposeShift
    Hotkey "~RShift", ComposeShift
}

; Super + left drag: move the window from anywhere inside it.
; The window follows the mouse; on release drop.ps1 re-tiles a tiled window
; where it was dropped (Hyprland-style), or re-homes it on the other monitor.
;
; This hands the actual move to Windows' own SC_MOVE (the same modal loop a real
; titlebar drag uses) instead of polling WinMove in a loop. WinMove-per-tick doesn't
; know about per-monitor DPI: dragging across two monitors with different scaling made
; the window appear stuck at the source monitor's edge (Windows clipping/virtualizing
; its rect against the wrong DPI) and then snap to fill the whole destination monitor
; once it crossed over. SC_MOVE is DPI-aware frame by frame, so the window tracks the
; cursor smoothly across the boundary with no clipping or resize surprise.
#LButton::
{
    PerMonitorDpi()
    hwnd := WindowUnderCursor()
    if !hwnd
        return
    info := GlazeWindowInfo(hwnd)
    if info && info.state != "tiling" && info.state != "floating"
        return  ; fullscreen / minimized
    WinActivate hwnd
    ; SC_MOVE (0xF012) starts Windows' native interactive move loop, tracking the
    ; still-held physical LButton; KeyWait blocks here until it's released and the loop ends.
    PostMessage 0x0112, 0xF012, , , hwnd   ; WM_SYSCOMMAND, SC_MOVE
    ; "P": #LButton suppresses the button-down message, so the logical (message-based)
    ; state never registers "down" - without P this would return immediately.
    KeyWait "LButton", "P"
    CoordMode "Mouse", "Screen"
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
#^q::RunPortOr("omacalc", "calc.exe")             ; calculator: Omacalc once installed (Install > Omarchy Apps)
#^g::MarkAsGame()                                 ; manual fallback: none of IsGame's checks caught it
#^t::Activity()                                   ; activity (btop; Task Manager if missing)
#^n::ToggleNightlight()                           ; nightlight
#^SC033::ToggleDnd()                              ; Super+Ctrl+Comma: do not disturb
#^!t::ShowTime()                                  ; time popup
#^!b::ShowBattery()                               ; battery popup
#^!w::ShowWeather()                               ; weather popup
#^a::Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" audio-panel')       ; audio panel (again: close)
#^b::Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" bluetooth-panel')   ; bluetooth panel (again: close)
#^w::Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" network-panel')     ; network panel (again: close)
#^d::Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" display-panel')     ; display panel (again: close)
#^p::OpenMenu("power")                            ; power mode (Omarchy's power profiles)
#^!d::Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" calendar')   ; calendar (the clock's)
#^!e::Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" worldclock')   ; world clock (Omarchy's Elsewhen)
#+!SC033::Send "#n"                               ; Super+Shift+Alt+Comma: notification history
#^z::Send "#{NumpadAdd}"                          ; zoom in (Magnifier)
#^!z::Send "#{Esc}"                               ; reset zoom

; Super + Shift + Return: browser (Omarchy v4); + Alt + B: private window
#+Enter::OpenBrowser()
#+!b::OpenBrowser(true)

; More of Omarchy's keys (default/hypr/bindings/utilities.lua, media.lua). Keys a script of
; your own in the Startup folder has stay yours (BindUnlessUser).
BindUnlessUser("#^r", (*) => MenuCmd("reminder"))                 ; set a reminder
BindUnlessUser("#^!r", (*) => MenuCmd("reminder", "show"))        ; show reminders
BindUnlessUser("#^+r", (*) => MenuCmd("reminder", "clear"))       ; clear reminders
BindUnlessUser("#^s", (*) => MenuCmd("share"))                    ; share (LocalSend)
BindUnlessUser("#^SC034", (*) => MenuCmd("transcode"))            ; Super+Ctrl+Period: transcode
BindUnlessUser("#^+a", (*) => MenuCmd("agent"))                   ; coding agent (asks which, if none is set)
BindUnlessUser("#^k", (*) => OpenMenu("herdr-keys"))              ; Herdr keybindings
BindUnlessUser("#^!f", (*) => ToggleFullscreenDesktop())          ; bar and gaps off together
BindUnlessUser("#^Delete", (*) => MenuCmd("display", "internal")) ; laptop screen off / on
BindUnlessUser("#^!Delete", (*) => MenuCmd("display", "mirror"))  ; mirror the screens / extend
; Media: Alt + volume keys step 1%, Alt + Play skips ahead, Alt + Shift + Play goes back,
; Shift + Mute switches the playback device. Over a game they still work, just without an OSD.
BindUnlessUser("!Volume_Up", (*) => StepVolume(1))
BindUnlessUser("!Volume_Down", (*) => StepVolume(-1))
BindUnlessUser("!Media_Play_Pause", (*) => Send("{Media_Next}"))
BindUnlessUser("!+Media_Play_Pause", (*) => Send("{Media_Prev}"))
BindUnlessUser("+Volume_Mute", (*) => SetTimer(NextAudioOutput, -10))

; One of Omarchy's own apps, built for Windows (lib/ports.ps1), else Windows' own.
RunPortOr(name, fallback) {
    exe := EnvGet("LOCALAPPDATA") "\Programs\Winarchy\oma\" name "\" name ".exe"
    try Run(FileExist(exe) ? '"' exe '"' : fallback)
}

MenuCmd(verb, arg := "") {
    Run('"' A_AhkPath '" "' A_ScriptDir '\menu.ahk" ' verb (arg != "" ? " " arg : ""))
}

StepVolume(delta) {
    SoundSetVolume (delta > 0 ? "+" : "") delta
    if !Busy()
        Osd("Volume " Round(SoundGetVolume()) "%")
}

NextAudioOutput() {
    out := Env("data") "\generated\audio-output.txt"
    try FileDelete out
    OmarchyCmdWait("audio", "next-output")
    name := ""
    try name := Trim(FileRead(out, "UTF-8"))
    if !Busy()
        Osd(name != "" ? "Sound: " name : "No other playback device")
}

; Omarchy's full screen desktop: no bar and no gaps, and back to both.
ToggleFullscreenDesktop() {
    global BarEnabled
    full := !BarEnabled && !GapsOn()
    ToggleBar(full ? "on" : "off")
    ApplyGaps(full, full)
    Osd("Full screen desktop " (full ? "off" : "on"))
}

OpenBrowser(private := false) {
    exe := Env("browser")
    args := private ? " " Env("browserPrivate", "--incognito") : ""
    try Run(exe ? '"' exe '"' args : "https://")
    catch
        Run "msedge.exe" (private ? " --inprivate" : "")
}

; --- Toggles ----------------------------------------------------------------
; Omarchy's Super+Shift+Space: the top bar on/off. Off stays off (flag file, across
; restarts and applies) until it's turned on again. state: "" toggles, "on", "off".
ToggleBar(state := "") {
    global BarEnabled, Zebar, BarFlag
    want := state = "" ? !BarEnabled : state = "on"
    if want != BarEnabled {
        BarEnabled := want
        if BarEnabled {
            try FileDelete BarFlag
            try Run('"' Zebar '" startup', , "Hide")
        } else {
            try FileAppend "", BarFlag
            CloseBar()
        }
    }
    ApplyGaps(GapsOn(), BarEnabled)
    Osd("Top bar " (BarEnabled ? "on" : "off"))
}

ToggleGaps() {
    global BarEnabled
    on := !GapsOn()
    ApplyGaps(on, BarEnabled)
    Osd("Window gaps " (on ? "on" : "off"))
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

; A GlazeWM key the admin game helper caught on our behalf. Windows stops GlazeWM's
; keyboard hook from seeing anything while an elevated window is in front, and the winarchy
; animations build has no uiAccess manifest to lift that (an unsigned build outside Program
; Files cannot have one), so while an admin game was up nothing switched workspaces at all.
; The helper is elevated, so it must not run the CLI - that lives under %USERPROFILE%,
; which the user can write to - and sends just an action code for this normal process to
; carry out. Any process here could post 0x5557, and the most that buys is a workspace
; switch it could have had by running the CLI itself, so the code need only be a known one.
OnRescuedKey(wParam, *) {
    static dirs := ["left", "right", "up", "down"]
        , cycles := ["--next-active-workspace", "--prev-active-workspace", "--recent-workspace"]
    kind := wParam // 100, arg := Mod(wParam, 100)
    name := arg                           ; the workspaces are named 1..10 (Super+0 = "10")
    ws := arg >= 1 && arg <= 10, dir := arg >= 1 && arg <= 4
    cmds := []
    if kind = 1 && ws
        cmds.Push("focus --workspace " name)
    else if kind = 2 && ws                ; take the window along and follow it
        cmds.Push("move --workspace " name, "focus --workspace " name)
    else if kind = 3 && ws                ; send the window over, stay put
        cmds.Push("move --workspace " name)
    else if kind = 4 && dir
        cmds.Push("focus --direction " dirs[arg])
    else if kind = 5 && dir
        cmds.Push("move --direction " dirs[arg])
    else if kind = 6 && dir
        cmds.Push("move-workspace --direction " dirs[arg])
    else if kind = 7 && arg >= 1 && arg <= 3
        cmds.Push("focus " cycles[arg])
    else if kind = 8 && arg = 1
        cmds.Push("focus --workspace scratch")
    else if kind = 8 && arg = 2
        cmds.Push("move --workspace scratch")
    else if kind = 8 && arg = 3
        cmds.Push("toggle-fullscreen --maximized=false")
    else if kind = 8 && arg = 4
        cmds.Push("toggle-fullscreen --maximized")
    else
        return 1                          ; not one of ours: ignore it quietly
    for c in cmds
        Glaze(c)
    WmLog("admin window in front: " cmds[1] " (relayed by the game helper)")
    SetTimer GameWorkspaceSync, -300      ; an admin game on the workspace just left
    return 1
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

; Snipping Tool screen recording in progress (Alt+PrtSc / Win+Shift+R): its
; recording toolbar is a SnippingTool.exe window titled "...Recording...".
ScreenRecording() {
    for hwnd in WinGetList("ahk_exe SnippingTool.exe")
        if InStr(WinGetTitle(hwnd), "Recording")
            return true
    return false
}

; indicators.json feeds the bar's indicator icons (this script is its only writer).
WriteIndicators() {
    global Pack, Awake, UacPending
    static last := ""
    b := v => v ? "true" : "false"
    game := (g := GameWindow()) ? GameTitle(g) : ""
    json := '{"awake":' b(Awake) ',"nightlight":' b(NightlightOn()) ',"dnd":' b(DndProfile() > 0)
        . ',"recording":' b(ScreenRecording())
        . ',"uac":"' JsonEscape(UacPending) '","game":"' JsonEscape(game) '"}'
    if json = last
        return
    try {
        f := FileOpen(Pack "\indicators.json", "w", "UTF-8-RAW")
        f.Write(json)
        f.Close()
        last := json
    }
}

; DWM hides a UWP window (suspended, on another virtual desktop, or a leftover
; ApplicationFrameHost shell) without unmapping it, so IsRestorableWindow alone still sees
; it - this is why Settings shows up twice (ApplicationFrameHost.exe + SystemSettings.exe).
IsCloaked(hwnd) {
    if !DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "int", 14, "int*", &cloaked := 0, "int", 4)
        return !!cloaked
    return false
}

; windows.json feeds the bar's chevron flyout: one entry per running app (its most
; recently active window), collapsed from every restorable top-level window. Icons are
; extracted lazily by a one-shot PowerShell verb (winicon), cached forever under
; Pack\icons\<key>.png, so this loop only ever asks for a given exe's icon once.
WriteWindows() {
    global Pack, BarTitle, MenuTitle, CalendarTitle
    static last := "", requested := 0
    if !requested
        requested := Map()
    apps := Map()          ; exe (lower) -> {exe, icon, title, minimized, focused, hwnd}
    order := []
    fg := WinExist("A")
    for hwnd in WinGetList() {
        try {
            if !IsRestorableWindow(hwnd) || IsCloaked(hwnd)
                continue
            title := WinGetTitle(hwnd)
            if !title || title = BarTitle || title = MenuTitle || title = CalendarTitle
                continue
            exe := WinGetProcessName(hwnd)
            if !exe || exe ~= "i)^(glazewm|zebar)\.exe$"
                continue
            key := StrLower(exe)
            focused := (hwnd = fg)
            ; WinGetList is z-order (topmost first): keep the first window of an exe seen,
            ; unless a later one turns out to be the focused one.
            if apps.Has(key) {
                if focused
                    apps[key].title := title, apps[key].hwnd := hwnd, apps[key].focused := true
                continue
            }
            iconKey := RegExReplace(RegExReplace(exe, "i)\.exe$"), "[^\w.-]", "_")
            entry := { exe: exe, icon: iconKey, title: title, hwnd: hwnd,
                focused: focused, minimized: !!DllCall("IsIconic", "ptr", hwnd) }
            apps[key] := entry
            order.Push(entry)
            iconPath := Pack "\icons\" iconKey ".png"
            ; (not while a game is in front: see Quiet - asked again on a later tick)
            if !requested.Has(iconKey) && !FileExist(iconPath) && !Busy() {
                requested[iconKey] := true
                try OmarchyCmd("winicon", WinGetProcessPath(hwnd), iconKey)
            }
        }
    }
    parts := []
    for entry in order
        parts.Push('{"exe":"' JsonEscape(entry.exe) '","icon":"' JsonEscape(entry.icon)
            . '","title":"' JsonEscape(entry.title) '","minimized":' (entry.minimized ? "true" : "false")
            . ',"focused":' (entry.focused ? "true" : "false") ',"hwnd":' entry.hwnd '}')
    json := '{"windows":[' Join(parts, ",") ']}'
    if json = last
        return
    try {
        f := FileOpen(Pack "\windows.json", "w", "UTF-8-RAW")
        f.Write(json)
        f.Close()
        last := json
    }
}

Join(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i = 1 ? "" : sep) v
    return out
}

JsonEscape(s) {
    s := StrReplace(StrReplace(s, "\", "\\"), '"', '\"')
    return RegExReplace(s, "[\x00-\x1F]", " ")
}

; --- Admin (UAC) prompts ---------------------------------------------------------
; When a program that isn't in front asks for admin (an installer started from a
; terminal, winget, ...), Windows doesn't show the UAC prompt: it parks it as a
; flashing taskbar button that opens the prompt when clicked. The taskbar is
; hidden here, so the bar shows a shield instead (plus an OSD), and clicking the
; shield opens the prompt. The parked prompt is a visible window of consent.exe
; with this class, titled e.g. "Go Installer is requesting your permission".
; (UacClass / UacPending are set at the top, before the first WriteIndicators.)
UacWatch() {
    global UacPending
    hwnd := UacWindow()
    title := hwnd ? WinGetTitle(hwnd) : ""
    if title = UacPending
        return
    if title != ""
        Osd(title "  (click the shield in the bar)", 5000)
    UacPending := title
    WriteIndicators()
}

UacWindow() {
    DetectHiddenWindows false   ; while the prompt is open the placeholder is hidden
    try return WinExist(UacClass)
    return 0
}

; Same as clicking the taskbar button: activate the placeholder, then restore it
; (WinActivate alone only focuses it; SwitchToThisWindow opens the prompt).
ShowUacPrompt() {
    if !(hwnd := UacWindow())
        return Osd("No admin prompt waiting")
    try WinActivate("ahk_id " hwnd)
    Sleep 200
    if UacWindow() = hwnd
        DllCall("SwitchToThisWindow", "Ptr", hwnd, "Int", 1)
    SetTimer UacWatchOnce, -1500
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

; --- New windows open on the hovered monitor ---------------------------------------
; Hyprland opens a window on the monitor you are working on. Windows has no such
; notion (CW_USEDEFAULT and apps' saved positions both land on the primary display),
; and GlazeWM then tiles the window into whatever workspace is bound to *that*
; monitor. So catch the window as it is created and re-home it to the workspace
; displayed on the monitor under the mouse.
;
; The catch: cursor_jump (off by default now; trigger window_focus if re-enabled) warps the cursor
; onto every newly focused window, so by the time this runs the cursor has already
; been teleported to the wrong monitor and reading it would always answer "here".
; HoverSample therefore keeps the last cursor position from *before* the window
; appeared: it stops sampling while a placement is in flight (HoverHold), and the
; move itself re-triggers focus -> cursor_jump, which is why the hold outlives it.

HoverSample() {
    global HoverPoint, HoverHold, HoverHoldUntil
    if HoverHold > 0 {
        if A_TickCount < HoverHoldUntil      ; backstop: a leaked hold can't freeze this for good
            return
        HoverHold := 0
    }
    PerMonitorDpi()
    CoordMode "Mouse", "Screen"
    MouseGetPos &x, &y
    HoverPoint := {x: x, y: y}
}

; --- The monitor you are working on --------------------------------------------
; Hyprland opens things on the focused monitor, and its follow_mouse keeps that the one
; under the pointer. Here the pointer stays put when keyboard focus changes monitor (a
; workspace key, Super+arrows: GlazeWM's cursor_jump is off, so the cursor never jerks),
; so "under the mouse" alone would put a new window, the menu or an OSD on the screen you
; just left. Whichever moved last wins: the pointer (PointerWatch) or keyboard focus
; (KeyFocusCheck, only counted while the pointer was still, so a click or focus following
; the mouse never counts as the keyboard).

PointerWatch() {
    global PointerMovedAt
    static lastX := "", lastY := ""
    CoordMode "Mouse", "Screen"
    MouseGetPos &x, &y
    if x != lastX || y != lastY
        PointerMovedAt := A_TickCount
    lastX := x, lastY := y
}

OnFocusMoved(hWinEventHook, event, hwnd, idObject, idChild, *) {
    if idObject = 0
        SetTimer KeyFocusCheck, -200
}

KeyFocusCheck() {
    global PointerMovedAt, KeyMonitor, KeyMonitorAt, HoverHold
    ; The pointer moved just now (a click, focus following it), or a new window is
    ; taking focus where it appeared - that one is being placed, not chosen.
    if A_TickCount - PointerMovedAt < 600 || HoverHold > 0
        return
    PerMonitorDpi()
    mon := 0
    try {
        fg := WinExist("A")
        if WinGetClass(fg) ~= "^(Progman|WorkerW)$"
            mon := GlazeFocusedMonitor()     ; an empty workspace: GlazeWM focuses the desktop
        else if FocusFollowEligible(fg)
            mon := MonitorOfWindow(fg)
    }
    if mon
        KeyMonitor := mon, KeyMonitorAt := A_TickCount
}

; Monitor of GlazeWM's focused window or (empty) workspace, 0 if unknown.
GlazeFocusedMonitor() {
    if RegExMatch(GlazeQuery("focused"), '"focused":\{[\s\S]*?"width":(-?\d+),"height":(-?\d+),"x":(-?\d+),"y":(-?\d+)', &m)
        return MonitorFromPoint(Integer(m[3]) + Integer(m[1]) // 2, Integer(m[4]) + Integer(m[2]) // 2)
    return 0
}

WorkMonitor() {
    global PointerMovedAt, KeyMonitor, KeyMonitorAt
    if KeyMonitorAt > PointerMovedAt && KeyMonitor >= 1 && KeyMonitor <= MonitorGetCount()
        return KeyMonitor
    PerMonitorDpi()
    return MonitorUnderMouse()
}

UnhookFocusMove(*) {
    global FocusMoveHook
    if FocusMoveHook
        DllCall("UnhookWinEvent", "ptr", FocusMoveHook)
    FocusMoveHook := 0
}

; --- Focus follows cursor (fallback for GlazeWM's own) --------------------------
; GlazeWM has focus_follows_cursor, but it stops following once the pointer touches a
; window it doesn't manage (glzr-io/glazewm#1326) - and winarchy tells it to ignore the
; bar, Flow Launcher and the pickers, so the strip along the top of every screen is
; exactly that; its cursor_jump warps can re-steal focus too (#760). Measured on this
; PC: the pointer crossed five windows over 5.5 s without focus moving once. Clicking a
; managed window is what unsticks GlazeWM, so that is what this does - the moment the
; pointer moves onto another ordinary window (its edge, not its middle), focus it, like
; Hyprland's follow_mouse = 1. It used to wait for the pointer to settle, and stopping
; cancelled the wait, so focus only moved after travelling well into the window.
; Runs every 30 ms: the per-tick path is just MouseGetPos; the costlier checks (Busy,
; eligibility) only run when there is a window to hand focus to.
FocusFollowWatch() {
    static lastX := -1, lastY := -1, tried := 0, triedAt := 0
    PerMonitorDpi()
    CoordMode "Mouse", "Screen"
    MouseGetPos &x, &y, &hwnd
    moved := (x != lastX || y != lastY)
    lastX := x, lastY := y
    ; Focus may only follow real movement: never take focus off the window being typed
    ; in because the pointer happens to be resting somewhere else.
    if !moved || !hwnd
        return
    hwnd := DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr")      ; GA_ROOT
    if !hwnd || hwnd = WinExist("A")
        return
    ; Activation can fail to take (foreground lock, GlazeWM re-asserting its focus):
    ; retry, but not on every tick.
    if hwnd = tried && A_TickCount - triedAt < 250
        return
    ; A game or fullscreen window owns its own focus; Super is held while dragging or
    ; resizing, where the pointer is carrying a window rather than choosing one.
    if GetKeyState("LWin", "P") || !FocusFollowEligible(hwnd) || Busy()
        return
    tried := hwnd, triedAt := A_TickCount
    try WinActivate "ahk_id " hwnd
}

; --- Auto-tiling watcher guard -------------------------------------------------
; lib/autotile-watch.ps1 (Hyprland-style dwindle) is started by GlazeWM's
; startup_commands, but it has been seen to vanish while GlazeWM itself kept running -
; and a dead watcher means new windows quietly pile up side by side again, with nothing
; on screen to say so. Watched like the bar is. The watcher takes a named mutex, so
; racing GlazeWM's own start can't leave two of them running.
AutoTileGuard() {
    static gone := 0, starts := []
    if !GlazeWmRunning()                     ; nothing to subscribe to yet
        return
    if AutoTileRunning() {
        gone := 0
        return
    }
    if !gone {                               ; confirm on a second look before restarting
        gone := A_TickCount
        return
    }
    now := A_TickCount
    recent := []
    for s in starts
        if now - s < 300000
            recent.Push(s)
    starts := recent
    gone := 0
    if starts.Length >= 5                    ; dying in a loop: stop fighting it
        return
    starts.Push(now)
    Run('"' Env("pwsh", "pwsh.exe") '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' Env("code") '\lib\autotile-watch.ps1" -Cli "' GlazeCli '"', , "Hide")
}

AutoTileRunning() {
    try {
        for proc in ComObjGet("winmgmts:").ExecQuery("SELECT CommandLine FROM Win32_Process WHERE Name='pwsh.exe'")
            if InStr(proc.CommandLine, "autotile-watch.ps1")
                return true
    }
    return false
}

; Windows the pointer may hand focus to: ordinary, restorable, not cloaked or minimized,
; and not one GlazeWM ignores (hovering the bar or a picker must not move focus - and
; touching them is what breaks GlazeWM's own following in the first place).
FocusFollowEligible(hwnd) {
    try {
        if !IsRestorableWindow(hwnd) || IsCloaked(hwnd) || WinGetMinMax(hwnd) = -1
            return false
        exe := WinGetProcessName(hwnd)
        if !exe || exe ~= "i)^(zebar|glazewm|Flow\.Launcher|PickerHost|consent)\.exe$"
            return false
        if WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$"
            return false
        if IsGame(hwnd) || IsFullscreenWindow(hwnd)
            return false
        return true
    }
    return false
}

HoverRelease() {
    global HoverHold
    if HoverHold > 0
        HoverHold--
}

OnShellHook(wParam, lParam, *) {
    global HoverHold, HoverHoldUntil, PrePlaceTarget
    if (wParam & 0x7FFF) != 1                ; HSHELL_WINDOWCREATED
        return
    HoverHold++
    HoverHoldUntil := A_TickCount + 2500
    PrePlaceTarget[lParam] := HoverTarget()   ; fixed now, before the window can move the pointer
    SetTimer HoverPlaceWindow.Bind(lParam, 1, HoverTarget()), -120
}

; A new window is created wherever Windows likes (usually the primary monitor) and only
; then moved by HoverPlaceWindow, once GlazeWM manages it - a visible flash on the wrong
; screen. Moving it here, from EVENT_OBJECT_SHOW (before its first paint), keeps the same
; relative position on the target monitor; GlazeWM then manages it where it already is,
; and HoverPlaceWindow finds it "already there". Only windows created since the shell hook
; noted a target are touched (PrePlaceTarget).
PrePlaceOnShow(hWinEventHook, event, hwnd, idObject, idChild, *) {
    global PrePlaceTarget
    if idObject != 0 || idChild != 0 || !hwnd || !PrePlaceTarget.Has(hwnd)
        return
    pt := PrePlaceTarget[hwnd]
    PrePlaceTarget.Delete(hwnd)
    if PrePlaceTarget.Count > 32               ; windows that never showed
        PrePlaceTarget.Clear()
    try {
        if MonitorGetCount() < 2
            return
        PerMonitorDpi()
        if DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") != hwnd
            return
        if !IsRestorableWindow(hwnd) || !FocusFollowEligible(hwnd) || WinGetMinMax(hwnd) != 0
            return
        dst := MonitorFromPoint(pt.x, pt.y)
        src := MonitorOfWindow(hwnd)
        if !dst || dst = src
            return
        WinGetPos &x, &y, &w, &h, hwnd
        MonitorGetWorkArea src, &sl, &st
        MonitorGetWorkArea dst, &dl, &dt, &dr, &db
        nx := Max(dl, Min(dl + (x - sl), dr - w))
        ny := Max(dt, Min(dt + (y - st), db - h))
        DllCall("SetWindowPos", "ptr", hwnd, "ptr", 0, "int", nx, "int", ny, "int", 0, "int", 0
            , "uint", 0x0015)                  ; SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE
    }
}

UnhookPrePlace(*) {
    global PrePlaceHook
    if PrePlaceHook
        DllCall("UnhookWinEvent", "ptr", PrePlaceHook)
    PrePlaceHook := 0
}

; Where a new window belongs, fixed as it appears: the hovered point, or - when keyboard
; focus moved to another monitor since the pointer last moved - the middle of that one.
HoverTarget() {
    global HoverPoint, KeyMonitor, KeyMonitorAt, PointerMovedAt
    if KeyMonitorAt > PointerMovedAt && KeyMonitor >= 1 && KeyMonitor <= MonitorGetCount() {
        MonitorGet KeyMonitor, &l, &t, &r, &b
        return {x: (l + r) // 2, y: (t + b) // 2}
    }
    return {x: HoverPoint.x, y: HoverPoint.y}
}

; Moves a just-created window to the workspace on the monitor at `pt` (HoverTarget). Runs
; off a timer (not the hook) so nothing blocks the shell, and retries while GlazeWM has
; yet to take the window under management - the shell hook fires before it does, so the
; first GlazeWindowInfo always misses.
HoverPlaceWindow(hwnd, attempt, pt) {
    global HoverPlace, GlazeCli
    if !HoverPlace || MonitorGetCount() < 2 {
        HoverRelease()
        return
    }
    PerMonitorDpi()
    again := false                           ; too early to tell: look again in a moment
    try {
        if !DllCall("IsWindow", "ptr", hwnd)
            throw Error("gone")
        if !(WinGetStyle(hwnd) & 0x10000000) {   ; WS_VISIBLE: the hook can beat the first paint
            again := true
            throw Error("not shown yet")
        }
        ; Owned windows and tool windows keep their parent's monitor: a Save/Print
        ; dialog belongs next to the window that opened it, not under the mouse.
        if !IsRestorableWindow(hwnd) || IsGame(hwnd) || IsFullscreenWindow(hwnd)
            throw Error("skip")
        target := MonitorFromPoint(pt.x, pt.y)
        if !target || target = MonitorOfWindow(hwnd)
            throw Error("already there")     ; no pointless move (and no move animation)
        ; GlazeWM takes the window under management a moment after it appears, so the
        ; first look always misses; one that it ignores never turns up at all.
        if !(info := GlazeWindowInfo(hwnd)) {
            again := true
            throw Error("not managed yet")
        }
    } catch {
        if again && attempt < 8              ; ~1.3 s, then give up
            SetTimer HoverPlaceWindow.Bind(hwnd, attempt + 1, pt), -150
        else
            HoverRelease()
        return
    }
    try Run('"' Env("pwsh", "pwsh.exe") '" -NoProfile -NonInteractive -ExecutionPolicy Bypass'
        . ' -WindowStyle Hidden -File "' Env("code") '\lib\drop.ps1" -Id ' info.id
        . ' -X ' pt.x ' -Y ' pt.y ' -Cli "' GlazeCli '" -WorkspaceOnly', , "Hide")
    try WmLog("opened on the working monitor: " WindowProcessName(hwnd))
    HoverRelease()
}
