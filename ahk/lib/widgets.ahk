; The bar's Zebar widgets that outlive a close: the Omarchy menu and the bar's panels hide
; instead of closing (menu.js, panel.js), and the next open shows the hidden window again -
; much faster than starting a new webview. Shared by menu.ahk and winarchy.ahk (which opens
; the menu from its own keys without starting menu.ahk at all). Functions only: both
; scripts have globals of their own.

WidgetTitle(name) => "Zebar - omarchy / " name " ahk_exe zebar.exe"

; The hidden window a close left on monitor `mon`, or 0. One whose size no longer fits
; that monitor (its resolution changed) is closed for real instead: hidden, those scripts
; let a close through.
HiddenWidget(title, mon) {
    prev := A_DetectHiddenWindows
    DetectHiddenWindows true
    MonitorGet mon, &l, &t, &r, &b
    found := 0, stale := []
    for hwnd in WinGetList(title) {
        try {
            if WinGetStyle(hwnd) & 0x10000000            ; WS_VISIBLE: open, not a spare
                continue
            WinGetPos &x, &y, &w, &h, hwnd
            if (cx := x + w // 2) < l || cx >= r || (cy := y + h // 2) < t || cy >= b
                continue
            if found || Abs(w - (r - l)) > 64 || Abs(h - (b - t)) > 64
                stale.Push(hwnd)
            else
                found := hwnd
        }
    }
    for hwnd in stale {
        try FileAppend FormatTime(, "HH:mm:ss") " [widgets] closed a hidden " title " that no longer fits its monitor`n"
            , Env("log", A_Temp "\winarchy.log"), "UTF-8"
        PostMessage 0x10, 0, 0, , hwnd
        WinWaitClose hwnd, , 1
    }
    DetectHiddenWindows prev
    return found
}

; Show the hidden spare on monitor `mon` (the page starts itself over when it gets focus).
ShowHiddenWidget(title, mon) {
    if !(hwnd := HiddenWidget(title, mon))
        return 0
    SetWinDelay -1                       ; no 100 ms nap between showing and activating it
    WinShow hwnd
    try WinActivate hwnd
    return hwnd
}

; Every hidden spare, closed for real (a display change: none of them fits any more).
CloseHiddenWidgets() {
    prev := A_DetectHiddenWindows
    DetectHiddenWindows true
    for hwnd in WinGetList("Zebar - omarchy / ahk_exe zebar.exe") {
        try {
            if WinGetTitle(hwnd) = "Zebar - omarchy / bar" || WinGetStyle(hwnd) & 0x10000000
                continue
            PostMessage 0x10, 0, 0, , hwnd
        }
    }
    DetectHiddenWindows prev
}

; The Omarchy menu's toggle and its instant path: close it when it is open, else write the
; route and show the hidden menu on the monitor you are working on. false = there is no
; hidden one there: start a widget (`mon` says where).
OpenMenuWarm(route, &mon := 0) {
    DetectHiddenWindows false            ; "open" means visible (winarchy.ahk's threads see hidden ones)
    title := WidgetTitle("menu")
    if hwnd := WinExist(title) {
        PostMessage 0x10, 0, 0, , hwnd   ; menu.js fades it and hides it for next time
        return true                      ; (WinClose can stall on Zebar's webview windows)
    }
    PerMonitorDpi()
    mon := WorkingMonitor()
    f := FileOpen(Env("pack") "\route.json", "w", "UTF-8-RAW")
    f.Write('{"route":"' route '"}')
    f.Close()
    return !!ShowHiddenWidget(title, mon)
}
