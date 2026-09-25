#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Off
#Include lib\env.ahk
#Include lib\osd.ahk
; Action dispatcher for the Zebar bar + Omarchy menu widget (whitelisted in zpack.json),
; and for omarchy-wm.ahk hotkeys that open the menu.
;   menu.ahk open <route>        open/toggle the Omarchy menu (root, system, keys, background, theme, ...)
;   menu.ahk launcher | start | terminal | calendar
;   menu.ahk send <keys> | run <target> [args] | url <url> | settings <ms-settings:...>
;   menu.ahk edit <file | glaze-config | bar-css | config | launchers | keybindings>
;   menu.ahk bg-set <path> [landing name] | bg-next | theme-set <name> | sync | apply | doctor   (-> omarchy-win CLI)
;   menu.ahk apply-glaze | update-check | animations <toggle> | glaze <glazewm command>
;   menu.ahk wm <bar|gaps|awake|transparency|colorpicker>        (-> running omarchy-wm.ahk)
;   menu.ahk panel <audio|bluetooth>                             (toggle Windows' quick panel)
;   menu.ahk lock | sleep | restart | shutdown | logout | upgrade | uninstall
;   menu.ahk bar-start                                           (start Zebar with no console: see Restart-Bar)

MenuTitle := "Zebar - omarchy / menu ahk_exe zebar.exe"

verb := A_Args.Length ? A_Args[1] : "launcher"
arg := A_Args.Length > 1 ? A_Args[2] : ""

; Keystrokes and window commands must land on the window the menu covered,
; so wait for the menu to finish closing first. The picker verbs send no keys: they start
; right away while the menu plays its apply animation (and waits for the new background).
if !(verb ~= "^(open|log|bar-start|bg-set|theme-set|font-set)$")
    WinWaitClose MenuTitle, , 1

switch verb {
    case "open": OpenMenu(arg || "root")
    case "launcher": Send Env("flowHotkey", "!{Space}")
    case "start": Send "^{Esc}"
    case "terminal": Run Env("terminal", "wt.exe")
    case "calendar": Send "#n"
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
    case "apply-glaze":
        Notify(OmarchyCmdWait("apply", "-MonitorsOnly") ? "GlazeWM config failed (Update > Doctor shows why)" : "GlazeWM config reloaded")
    case "update-check":
        Osd("Checking for updates…", 0)
        Notify(OmarchyCmdWait("update-check") ? "Update check failed (no connection?)" : UpdatesText())
    case "weather": OmarchyCmd(verb)
    ; Long downloads get a terminal with progress.
    case "sync": RunInTerminal("Themes & backgrounds", CliInTerminal("sync"))
    case "font-install": RunInTerminal("Install " arg " Nerd Font", CliInTerminal("font-install", arg))
    case "animations": ToggleAnimations()
    case "glaze": try Run('"' Env("glazewmCli") '" command ' arg, , "Hide")
    case "activity": SignalWm("activity")
    case "browser-setup": RunInTerminal("Browser toolbar color", CliInTerminal("browser-setup"))
    case "doctor": RunInTerminal("omarchy-win doctor", '"' Env("pwsh", "pwsh") '" -NoExit -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1" doctor')
    case "wm": SignalWm(arg)
    case "panel": SignalWm("panel-" arg)
    case "about": RunWt('-w new --size 112,38 -p "Omarchy About"', '"' Env("pwsh", "pwsh") '" -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\lib\about.ps1"')
    case "branding-reset": ResetBranding(arg)
    case "log": FileAppend FormatTime(, "HH:mm:ss") " [menu] " arg "`n", Env("log", A_Temp "\omarchy-win.log"), "UTF-8"
    case "lock": DllCall("LockWorkStation")
    case "sleep":
        ; Modern Standby laptops refuse SetSuspendState: turning the screens off is how they sleep.
        if !DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
            DllCall("PostMessage", "ptr", 0xFFFF, "uint", 0x112, "ptr", 0xF170, "ptr", 2)
    case "restart": Run "shutdown.exe /r /t 0", , "Hide"
    case "shutdown": Run "shutdown.exe /s /t 0", , "Hide"
    case "logout": Run "shutdown.exe /l", , "Hide"
    case "upgrade": RunInTerminal("Update", '"' Env("pwsh", "pwsh") '" -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1" update')
    case "bar-start": try Run('"' Env("zebar") '" startup', , "Hide")
    case "uninstall", "revert": RunInTerminal("Uninstall omarchy-win", '"' Env("pwsh", "pwsh") '" -NoExit -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1" uninstall')
}

; Named targets keep menu.json free of machine paths.
EditFile(target) {
    data := Env("data")
    startup := A_Startup "\launchers.ahk"
    switch target {
        case "glaze-config": file := GlazeTemplate()
        case "bar-css": file := Env("pack") "\user.css"
        case "config": file := data "\config.json"
        case "keybindings", "launchers": file := Env("launchers", "1") = "1" ? UserLaunchers() : startup
        case "screensaver-text": file := data "\branding\screensaver.txt"
        case "about-text": file := data "\branding\about.txt"
        default: file := target
    }
    if !FileExist(file) && target = "config" {
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write('{`n  "_help": "Only the settings you change. See docs/config.md, then run: omarchy-win apply"`n}`n')
        f.Close()
    }
    editor := Env("editor", "notepad.exe")
    if editor ~= "i)nvim(\.exe)?$"      ; terminal editor
        RunInTerminal("nvim", '"' editor '" "' file '"')
    else
        Run '"' editor '" "' file '"'
}

; Your GlazeWM template (omarchy-win uses it instead of its own; saving applies it).
GlazeTemplate() {
    file := Env("data") "\glazewm.yaml.tpl"
    if !FileExist(file) {
        tpl := FileRead(Env("code") "\templates\glazewm.yaml.tpl", "UTF-8")
        f := FileOpen(file, "w", "UTF-8-RAW")
        f.Write("# YOUR copy of omarchy-win's GlazeWM template: saving it rewrites GlazeWM's config and reloads it.`n"
            . "# {{ ... }} are filled in by omarchy-win. Delete this file to go back to the default.`n" tpl)
        f.Close()
    }
    return file
}

; Your copy of omarchy-win's app keys (made on first edit; saving reloads it). It gets
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

; An omarchy-win verb for a terminal tab: shows its output and waits for a key.
CliInTerminal(args*) {
    cmd := '"' Env("pwsh", "pwsh") '" -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1"'
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

; Commands that need state held by the running omarchy-wm.ahk (bar/awake toggles...).
SignalWm(name) {
    static ids := Map("bar", 1, "gaps", 2, "awake", 3, "transparency", 4, "colorpicker", 5,
        "panel-audio", 6, "panel-bluetooth", 7, "screensaver", 8, "screensaver-toggle", 9,
        "ocr", 10, "nightlight", 11, "dnd", 12, "weather", 13, "activity", 14, "uac", 15)
    DetectHiddenWindows true
    if ids.Has(name) && (hwnd := WinExist("omarchy-wm.ahk ahk_class AutoHotkey"))
        PostMessage 0x5555, ids[name], 0, , hwnd
}

; Open the menu widget on the monitor under the cursor. Pressing the key again closes it.
OpenMenu(route) {
    global MenuTitle
    pack := Env("pack")
    if hwnd := WinExist(MenuTitle) {
        PostMessage 0x10, 0, 0, , hwnd      ; WinClose can stall on Zebar's webview windows
        return
    }
    PerMonitorDpi()
    ; Zebar's presets m0..m7 follow its monitor order (left to right, top to bottom).
    preset := "m" MonitorPosition(MonitorUnderMouse())
    f := FileOpen(pack "\route.json", "w", "UTF-8-RAW")
    f.Write('{"route":"' route '"}')
    f.Close()
    Run '"' Env("zebar") '" start-widget-preset --pack omarchy --widget-name menu --preset ' preset, , "Hide"
    ; Windows won't hand focus to a window opened by a background process, and the
    ; transparent webview doesn't paint until it is activated, so activate it here.
    if hwnd := WinWait(MenuTitle, , 3) {
        try WinActivate hwnd
    }
}
