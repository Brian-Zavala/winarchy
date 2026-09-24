#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Off
#Include lib\env.ahk
; Action dispatcher for the Zebar bar + Omarchy menu widget (whitelisted in zpack.json),
; and for omarchy-wm.ahk hotkeys that open the menu.
;   menu.ahk open <route>        open/toggle the Omarchy menu (root, system, keys, background, theme, ...)
;   menu.ahk launcher | start | terminal | calendar
;   menu.ahk send <keys> | run <target> [args] | url <url> | settings <ms-settings:...>
;   menu.ahk edit <file | glaze-config | bar-css | config | launchers | keybindings>
;   menu.ahk bg-set <path> | bg-next | theme-set <name> | sync | apply | doctor   (-> omarchy-win CLI)
;   menu.ahk wm <bar|gaps|awake|transparency|colorpicker>        (-> running omarchy-wm.ahk)
;   menu.ahk panel <audio|bluetooth>                             (toggle Windows' quick panel)
;   menu.ahk lock | sleep | restart | shutdown | logout | upgrade | uninstall

MenuTitle := "Zebar - omarchy / menu ahk_exe zebar.exe"

verb := A_Args.Length ? A_Args[1] : "launcher"
arg := A_Args.Length > 1 ? A_Args[2] : ""

; Keystrokes and window commands must land on the window the menu covered,
; so wait for the menu to finish closing first.
if verb != "open" && verb != "log"
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
    case "bg-set", "theme-set", "bg-next", "sync", "apply":
        OmarchyCmd(verb, arg)
    case "doctor": RunInTerminal("omarchy-win doctor", '"' Env("pwsh", "pwsh") '" -NoExit -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1" doctor')
    case "wm": SignalWm(arg)
    case "panel": SignalWm("panel-" arg)
    case "log": FileAppend FormatTime(, "HH:mm:ss") " [menu] " arg "`n", Env("log", A_Temp "\omarchy-win.log"), "UTF-8"
    case "lock": DllCall("LockWorkStation")
    case "sleep": DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
    case "restart": Run "shutdown.exe /r /t 0", , "Hide"
    case "shutdown": Run "shutdown.exe /s /t 0", , "Hide"
    case "logout": Run "shutdown.exe /l", , "Hide"
    case "upgrade": RunInTerminal("Update", '"' Env("pwsh", "pwsh") '" -NoExit -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1" update')
    case "uninstall", "revert": RunInTerminal("Uninstall omarchy-win", '"' Env("pwsh", "pwsh") '" -NoExit -NoProfile -ExecutionPolicy Bypass -File "' Env("code") '\bin\omarchy-win.ps1" uninstall')
}

; Named targets keep menu.json free of machine paths.
EditFile(target) {
    data := Env("data")
    startup := A_Startup "\launchers.ahk"
    switch target {
        case "glaze-config": file := Env("glazeConfig")
        case "bar-css": file := Env("pack") "\user.css"
        case "config": file := data "\config.json"
        case "keybindings": file := Env("code") "\ahk\omarchy-wm.ahk"
        case "launchers": file := Env("launchers", "1") = "1" ? Env("code") "\ahk\launchers.ahk" : startup
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

; Commands that need state held by the running omarchy-wm.ahk (bar/awake toggles...).
SignalWm(name) {
    static ids := Map("bar", 1, "gaps", 2, "awake", 3, "transparency", 4, "colorpicker", 5,
        "panel-audio", 6, "panel-bluetooth", 7)
    DetectHiddenWindows true
    if ids.Has(name) && (hwnd := WinExist("omarchy-wm.ahk ahk_class AutoHotkey"))
        PostMessage 0x5555, ids[name], 0, , hwnd
}

; Open the menu widget on the monitor under the cursor. Pressing the key again closes it.
OpenMenu(route) {
    global MenuTitle
    pack := Env("pack")
    if WinExist(MenuTitle) {
        WinClose MenuTitle
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
