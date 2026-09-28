#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Off
#Include lib\env.ahk
#Include lib\osd.ahk
OnError ScriptLogError
; Action dispatcher for the Zebar bar + Omarchy menu widget (whitelisted in zpack.json),
; and for winarchy.ahk hotkeys that open the menu.
;   menu.ahk open <route>        open/toggle the Omarchy menu (root, system, keys, background, theme, ...)
;   menu.ahk launcher | start | terminal | calendar
;   menu.ahk run-app <AppsFolder AppID> | apps-refresh    (Apps route; refresh -> winarchy CLI)
;   menu.ahk focus-window <hwnd>                          (bar chevron flyout: raise a running window)
;   menu.ahk install-app <key> | remove-app <key> | catalog-refresh   (Install/Remove routes)
;   menu.ahk herdr | agent | default-agent <name>                     (Herdr + coding agents)
;   menu.ahk usage | usage-refresh                                    (bar agent icon: usage panel)
;   menu.ahk send <keys> | run <target> [args] | url <url> | settings <ms-settings:...>
;   menu.ahk edit <file | glaze-config | bar-css | config | launchers | keybindings>
;   menu.ahk bg-set <path> [landing name] | bg-next | theme-set <name> | sync | apply | doctor   (-> winarchy CLI)
;   menu.ahk apply-glaze | update-check | animations <toggle> | glaze <glazewm command>
;   menu.ahk wm <bar|gaps|awake|transparency|colorpicker>        (-> running winarchy.ahk)
;   menu.ahk panel <audio|bluetooth>                             (toggle Windows' quick panel)
;   menu.ahk lock | sleep | hibernate | reboot | shutdown | logout | upgrade | uninstall
;   menu.ahk restart <bar|glazewm|herdr> | config-reset <glazewm|herdr> | display <laptop|mirror>
;   menu.ahk bar-start                                           (start Zebar with no console: see Restart-Bar)

MenuTitle := "Zebar - omarchy / menu ahk_exe zebar.exe"

verb := A_Args.Length ? A_Args[1] : "launcher"
arg := A_Args.Length > 1 ? A_Args[2] : ""

; Keystrokes and window commands must land on the window the menu covered,
; so wait for the menu to finish closing first. The picker verbs send no keys: they start
; right away while the menu plays its apply animation (and waits for the new background).
if !(verb ~= "^(open|log|bar-start|bg-set|theme-set|font-set|apps-refresh|catalog-refresh)$")
    WinWaitClose MenuTitle, , 1

switch verb {
    case "open": OpenMenu(arg || "root")
    case "launcher": Send Env("flowHotkey", "!{Space}")
    ; Apps route: one AppsFolder AppID launches a desktop program or a Store app alike.
    case "run-app": try Run 'explorer.exe "shell:AppsFolder\' arg '"'
    case "apps-refresh": OmarchyCmd("apps")
    ; Bar chevron flyout: arg is the target window's hwnd (windows.json).
    case "focus-window": try WinActivate("ahk_id " arg)
    case "catalog-refresh": OmarchyCmd("catalog")
    case "start": Send "^{Esc}"
    case "terminal": Run Env("terminal", "wt.exe")
    case "calendar": OpenCalendar()
    ; The bar's agent icon: the usage panel, and its refresh key (r / Enter).
    case "usage": OpenUsage()
    case "usage-refresh": OmarchyCmd("agent-usage", "-Force")
    case "send": Send arg
    case "run": Run(arg (A_Args.Length > 2 ? " " A_Args[3] : ""))
    case "url", "settings": Run arg
    case "edit": EditFile(arg)
    ; Quick CLI verbs run hidden; a failure (or a result worth knowing) shows an OSD.
    case "bg-set", "theme-set", "bg-next", "font-set":
        covered := verb = "bg-set" && A_Args.Length > 2 ? Landing(arg, A_Args[3]) : ""
        if OmarchyCmdWait(verb, arg, covered ? "-Covered" : "", covered)
            Notify(verb = "theme-set" ? "Theme change failed (Update > Doctor shows why)" : verb = "font-set" ? "Font change failed (Update > Doctor shows why)" : "Background change failed (Update > Doctor shows why)")
    case "apply":
        Osd("Applying settings…", 0)
        Notify(OmarchyCmdWait("apply") ? "Applying settings failed (Update > Doctor shows why)" : "Settings applied")
    ; Your herdr.toml.tpl was saved: re-render Herdr's config and reload a running Herdr.
    case "apply-herdr":
        Notify(OmarchyCmdWait("herdr", "config") ? "Herdr config failed (Update > Doctor shows why)" : "Herdr config reloaded")
    case "apply-glaze":
        Notify(OmarchyCmdWait("apply", "-MonitorsOnly") ? "GlazeWM config failed (Update > Doctor shows why)" : "GlazeWM config reloaded")
    case "update-check":
        Osd("Checking for updates…", 0)
        Notify(OmarchyCmdWait("update-check") ? "Update check failed (no connection?)" : UpdatesText())
    case "weather": OmarchyCmd(verb)
    ; Long downloads get a terminal with progress.
    case "sync": RunInTerminal("Themes & backgrounds", CliInTerminal("sync"))
    case "font-install": RunInTerminal("Install " arg " Nerd Font", CliInTerminal("font-install", arg))
    ; Install/Remove: winget in a terminal, so the download and any prompts are visible.
    ; Herdr is a full-screen terminal app: it gets a terminal, and takes it over.
    case "herdr": RunHerdr()
    ; The coding agent opens in its own window (winarchy agent picks the flags); with no
    ; default agent yet, -Pick opens the chooser instead of failing into the log.
    case "agent": OmarchyCmd("agent", "-Pick")
    ; Setup > Default Agent: sets it, then starts it, like Omarchy's menu does.
    case "default-agent": RunInTerminal("Default agent", CliInTerminal("default-agent", arg))
    case "install-app": RunInTerminal("Install " arg, CliInTerminal("install-app", arg))
    case "remove-app": RunInTerminal("Remove " arg, CliInTerminal("remove-app", arg))
    case "animations": ToggleAnimations()
    case "glaze": try Run('"' Env("glazewmCli") '" command ' arg, , "Hide")
    case "activity": SignalWm("activity")
    case "browser-setup": RunInTerminal("Browser toolbar color", CliInTerminal("browser-setup"))
    case "game-setup": RunInTerminal("Admin game helper", CliInTerminal("game-setup"))
    case "doctor": RunInTerminal("winarchy doctor", '"' Env("pwsh", "pwsh") '" -NoExit -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\winarchy.ps1" doctor')
    case "wm": SignalWm(arg)
    case "panel": SignalWm("panel-" arg)
    case "about": RunWt('-w new --size 112,38 -p "Omarchy About"', '"' Env("pwsh", "pwsh") '" -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\lib\about.ps1"')
    case "branding-reset": ResetBranding(arg)
    case "log": FileAppend FormatTime(, "HH:mm:ss") " [menu] " arg "`n", Env("log", A_Temp "\winarchy.log"), "UTF-8"
    case "lock": DllCall("LockWorkStation")
    case "sleep":
        ; Modern Standby laptops refuse SetSuspendState: turning the screens off is how they sleep.
        if !DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
            DllCall("PostMessage", "ptr", 0xFFFF, "uint", 0x112, "ptr", 0xF170, "ptr", 2)
    case "hibernate": DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)
    case "reboot": Run "shutdown.exe /r /t 0", , "Hide"
    ; Update > Process: start one part again (Omarchy's omarchy-restart-*).
    case "restart": RestartPart(arg)
    ; Update > Config: back to winarchy's own template (yours is kept as .bak).
    case "config-reset": ResetConfig(arg)
    ; Trigger > Hardware (Omarchy's omarchy-hyprland-monitor-internal[-mirror]).
    case "display": ToggleDisplay(arg)
    case "shutdown": Run "shutdown.exe /s /t 0", , "Hide"
    case "logout": Run "shutdown.exe /l", , "Hide"
    case "upgrade": RunInTerminal("Update", '"' Env("pwsh", "pwsh") '" -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\winarchy.ps1" update')
    case "bar-start": try Run('"' Env("zebar") '" startup', , "Hide")
    case "uninstall", "revert": RunInTerminal("Uninstall winarchy", '"' Env("pwsh", "pwsh") '" -NoExit -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\winarchy.ps1" uninstall')
}

; Named targets keep menu.json free of machine paths.
EditFile(target) {
    data := Env("data")
    startup := A_Startup "\launchers.ahk"
    switch target {
        case "glaze-config": file := GlazeTemplate()
        case "herdr-config": file := HerdrTemplate()
        case "bar-css": file := Env("pack") "\user.css"
        case "config": file := data "\config.json"
        case "keybindings", "launchers": file := Env("launchers", "1") = "1" ? UserLaunchers() : startup
        case "screensaver-text": file := data "\branding\screensaver.txt"
        case "about-text": file := data "\branding\about.txt"
        default: file := target
    }
    if !FileExist(file) && target = "config" {
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write('{`n  "_help": "Only the settings you change. See manual/31-dotfiles.md; saving applies them"`n}`n')
        f.Close()
    }
    editor := Env("editor", "notepad.exe")
    if editor ~= "i)nvim(\.exe)?$"      ; terminal editor
        RunInTerminal("nvim", '"' editor '" "' file '"')
    else
        Run '"' editor '" "' file '"'
}

; Your Herdr config template (winarchy renders it; saving re-renders and reloads Herdr).
HerdrTemplate() {
    file := Env("data") "\herdr.toml.tpl"
    if !FileExist(file) {
        tpl := FileRead(Env("code") "\templates\herdr.toml.tpl", "UTF-8")
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write("# YOUR copy of winarchy's Herdr template: saving it rewrites Herdr's config.toml`n"
            . "# and reloads a running Herdr. Delete this file to go back to the default.`n" tpl)
        f.Close()
    }
    return file
}

RestartPart(part) {
    switch part {
        case "bar":
            ; Closed, then started again here: winarchy.ahk would only notice after 5 s.
            while ProcessExist("zebar.exe")
                ProcessClose "zebar.exe"
            try Run('"' Env("zebar") '" startup', , "Hide")
        case "glazewm":
            try RunWait('"' Env("glazewmCli") '" command wm-reload-config', , "Hide")
            Osd("GlazeWM reloaded")
        case "herdr":
            Notify(OmarchyCmdWait("herdr", "config") ? "Herdr reload failed (Update > Doctor shows why)" : "Herdr reloaded")
    }
}

; Your copy of a template goes aside as .bak, and apply renders winarchy's own again.
ResetConfig(which) {
    file := Env("data") (which = "herdr" ? "\herdr.toml.tpl" : "\glazewm.yaml.tpl")
    if !FileExist(file)
        return Osd("Already on the default " (which = "herdr" ? "Herdr" : "GlazeWM") " config")
    FileMove file, file ".bak", true
    if which = "herdr"
        Notify(OmarchyCmdWait("herdr", "config") ? "Herdr config failed (Update > Doctor shows why)" : "Herdr config reset (yours: herdr.toml.tpl.bak)")
    else
        Notify(OmarchyCmdWait("apply", "-MonitorsOnly") ? "GlazeWM config failed (Update > Doctor shows why)" : "GlazeWM config reset (yours: glazewm.yaml.tpl.bak)")
}

; Laptop Display: off while another monitor is on, back on otherwise. Mirror Display:
; duplicate the laptop screen on the other one, and back to extended the next time.
ToggleDisplay(what) {
    flag := Env("data") "\generated\display-mirror"
    if what = "mirror" {
        mirrored := FileExist(flag)
        try Run("DisplaySwitch.exe " (mirrored ? "/extend" : "/clone"), , "Hide")
        if mirrored {
            try FileDelete flag
        } else {
            try FileAppend "", flag
        }
        return
    }
    try Run("DisplaySwitch.exe " (MonitorGetCount() > 1 ? "/external" : "/extend"), , "Hide")
}

; Launch or attach to the persistent Herdr session (omarchy-launch-terminal-herdr).
RunHerdr() {
    herdr := Env("herdr")
    if !herdr {
        Notify("Herdr is not installed (Omarchy menu > Install > Terminal)")
        return
    }
    ; Link any agent installed since last time, in the background: it only writes a hook
    ; into the agent's own config, so Herdr need not wait for it.
    OmarchyCmd("herdr", "link")
    RunInTerminal("Herdr", '"' herdr '"')
}

; Your GlazeWM template (winarchy uses it instead of its own; saving applies it).
GlazeTemplate() {
    file := Env("data") "\glazewm.yaml.tpl"
    if !FileExist(file) {
        tpl := FileRead(Env("code") "\templates\glazewm.yaml.tpl", "UTF-8")
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write("# YOUR copy of winarchy's GlazeWM template: saving it rewrites GlazeWM's config and reloads it.`n"
            . "# {{ ... }} are filled in by winarchy. Delete this file to go back to the default.`n" tpl)
        f.Close()
    }
    return file
}

; Your copy of winarchy's app keys (made on first edit; saving reloads it). It gets
; env.ahk through AutoHotkey's /include switch, so it has no #Include of the code folder.
UserLaunchers() {
    file := Env("data") "\launchers.ahk"
    if !FileExist(file) {
        src := Env("code") "\ahk\launchers.ahk"
        text := RegExReplace(FileRead(src, "UTF-8"), "m)^#Include lib\env\.ahk\R")
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write(text)
        f.Close()
        ; Swap the running project copy for yours.
        DetectHiddenWindows true
        SetTitleMatchMode 2
        if hwnd := WinExist(src " ahk_class AutoHotkey")
            PostMessage 0x10, 0, 0, , hwnd
        Run '"' A_AhkPath '" /include "' A_ScriptDir '\lib\env.ahk" "' file '"'
    }
    return file
}

; A winarchy verb for a terminal tab: shows its output and waits for a key.
CliInTerminal(args*) {
    cmd := '"' Env("pwsh", "pwsh") '" -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\winarchy.ps1"'
    for a in args
        cmd .= ' "' a '"'
    return cmd ' -Pause'
}

; The background picker plays the wallpaper reveal on its own monitor with the full-size
; picture: copy it into the pack under the name the picker asked for (whole, then renamed,
; so the picker never reads half a file). Returns the picker's centre, for the CLI to skip.
Landing(src, name) {
    global MenuTitle
    if !(name ~= "^\d+\.\w+$")
        return ""
    dir := Env("pack") "\thumbs\_land"
    try {
        DirCreate dir
        loop files dir "\*"
            try FileDelete A_LoopFileFullPath
        FileCopy src, dir "\part.tmp", true
        FileMove dir "\part.tmp", dir "\" name, true
    }
    PerMonitorDpi()
    try {
        WinGetPos &x, &y, &w, &h, MenuTitle
        return (x + w // 2) "," (y + h // 2)
    }
    return ""
}

; Show an OSD from this short-lived script, then let it finish.
Notify(text) {
    Osd(text, 2000)
    Sleep 2100
}

UpdatesText() {
    try {
        json := FileRead(Env("pack") "\updates.json", "UTF-8")
        n := 0, p := 1
        while p := RegExMatch(json, '"name":', , p)
            n++, p++
        if n
            return n " update" (n = 1 ? "" : "s") " available: click the arrow icon in the bar"
    }
    return "Everything is up to date"
}

; Toggle > Window Animations: switch GlazeWM builds (the first time, build it in a terminal).
ToggleAnimations() {
    if !FileExist(Env("data") "\glazewm-animations\glazewm.exe") {
        RunInTerminal("Window animations", CliInTerminal("animations", "setup"))
        return
    }
    Osd("Switching window animations…", 0)
    if OmarchyCmdWait("animations", "toggle") {
        Notify("Switching window animations failed (Update > Doctor shows why)")
        return
    }
    global OW
    OW := LoadOmarchyEnv()
    Notify("Window animations " (Env("animations", "0") = "1" ? "on" : "off"))
}

; Style > Screensaver/About > Restore default (Omarchy's logo.txt / icon.txt).
ResetBranding(which) {
    src := Env("data") "\themes\_templates\" (which = "about" ? "icon.txt" : "logo.txt")
    try FileCopy src, Env("data") "\branding\" which ".txt", true
}

; Commands that need state held by the running winarchy.ahk (bar/awake toggles...).
SignalWm(name) {
    static ids := Map("bar", 1, "gaps", 2, "awake", 3, "transparency", 4, "colorpicker", 5,
        "panel-audio", 6, "panel-bluetooth", 7, "screensaver", 8, "screensaver-toggle", 9,
        "ocr", 10, "nightlight", 11, "dnd", 12, "weather", 13, "activity", 14, "uac", 15,
        "game", 16, "game-close", 17, "bar-on", 18, "bar-off", 19, "restore-all", 20)
    DetectHiddenWindows true
    if ids.Has(name) && (hwnd := WinExist("winarchy.ahk ahk_class AutoHotkey"))
        PostMessage 0x5555, ids[name], 0, , hwnd
}

; Open the menu widget on the monitor you're working on (see WorkingMonitor). Pressing the
; key again closes it.
OpenMenu(route) {
    global MenuTitle
    pack := Env("pack")
    if hwnd := WinExist(MenuTitle) {
        ; (menu.js turns this into its fade and hides the window for next time)
        PostMessage 0x10, 0, 0, , hwnd      ; WinClose can stall on Zebar's webview windows
        return
    }
    PerMonitorDpi()
    mon := WorkingMonitor()
    f := FileOpen(pack "\route.json", "w", "UTF-8-RAW")
    f.Write('{"route":"' route '"}')
    f.Close()
    ; A closed menu stays loaded, hidden (menu.js): show it again, and it starts over from
    ; route.json. Much faster than a new webview.
    if hwnd := HiddenMenu(mon) {
        WinShow hwnd
        try WinActivate hwnd
        return
    }
    ; Zebar's presets m0..m7 follow its monitor order (left to right, top to bottom).
    preset := "m" MonitorPosition(mon)
    Run '"' Env("zebar") '" start-widget-preset --pack omarchy --widget-name menu --preset ' preset, , "Hide"
    ; Windows won't hand focus to a window opened by a background process, and the
    ; transparent webview doesn't paint until it is activated, so activate it here.
    if hwnd := WinWait(MenuTitle, , 3) {
        try WinActivate hwnd
    }
}

; The hidden menu window on monitor `mon`, if a closed menu left one there.
HiddenMenu(mon) {
    global MenuTitle
    prev := A_DetectHiddenWindows
    DetectHiddenWindows true
    MonitorGet mon, &l, &t, &r, &b
    found := 0
    for hwnd in WinGetList(MenuTitle) {
        try {
            if WinGetStyle(hwnd) & 0x10000000           ; WS_VISIBLE: not one of ours
                continue
            WinGetPos &x, &y, &w, &h, hwnd
            if (cx := x + w // 2) >= l && cx < r && (cy := y + h // 2) >= t && cy < b {
                found := hwnd
                break
            }
        }
    }
    DetectHiddenWindows prev
    return found
}

; The clock's calendar (Omarchy Quattro), on the monitor you're working on; again closes it.
; The agent usage panel (Omarchy's agents widget), dropped under the bar icon it was
; opened from: the click's x, in the widget's CSS pixels, goes in usage-anchor.json.
; Opening it also refreshes the limits, which is what it is usually opened to check.
OpenUsage() {
    title := "Zebar - omarchy / usage ahk_exe zebar.exe"
    if hwnd := WinExist(title) {
        PostMessage 0x10, 0, 0, , hwnd
        return
    }
    PerMonitorDpi()
    n := MonitorUnderMouse()
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx
    MonitorGet n, &left
    f := FileOpen(Env("pack") "\usage-anchor.json", "w", "UTF-8-RAW")
    f.Write('{"x":' Round((mx - left) * 96 / MonitorDpi(n)) '}')
    f.Close()
    OmarchyCmd("agent-usage", "-LimitsOnly")
    Run '"' Env("zebar") '" start-widget-preset --pack omarchy --widget-name usage --preset u' MonitorPosition(n), , "Hide"
    if hwnd := WinWait(title, , 3)
        try WinActivate hwnd
}

OpenCalendar() {
    title := "Zebar - omarchy / calendar ahk_exe zebar.exe"
    if hwnd := WinExist(title) {
        PostMessage 0x10, 0, 0, , hwnd
        return
    }
    PerMonitorDpi()
    Run '"' Env("zebar") '" start-widget-preset --pack omarchy --widget-name calendar --preset c' MonitorPosition(WorkingMonitor()), , "Hide"
    if hwnd := WinWait(title, , 3)
        try WinActivate hwnd
}
