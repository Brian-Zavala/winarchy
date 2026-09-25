; Small Omarchy-style OSD at the bottom center of the monitor under the mouse, in the
; theme's colors and font. Shared by winarchy.ahk and menu.ahk.
;   Osd(text)        shows it for 1.2 s
;   Osd(text, 0)     keeps it until the next Osd / OsdHide

global OsdGui := 0

Osd(text, ms := 1200) {
    global OsdGui
    colors := ThemeColors()
    OsdHide()
    PerMonitorDpi()   ; size + place it in the monitor's real pixels (mixed-DPI setups)
    mon := MonitorUnderMouse()
    scale := MonitorDpi(mon) / 96
    OsdGui := g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +Border -DPIScale", "omarchy-osd")
    g.BackColor := colors.bg
    g.MarginX := Round(18 * scale), g.MarginY := Round(10 * scale)
    g.SetFont("s" Round(11 * scale * 96 / A_ScreenDPI) " c" colors.fg, colors.font)
    g.AddText(, text)
    g.Show("Hide AutoSize")
    g.GetPos(, , &w, &h)
    MonitorGetWorkArea(mon, &l, &t, &r, &b)
    g.Show("NoActivate x" (l + (r - l - w) // 2) " y" (b - h - Round(60 * scale)))
    SetTimer OsdHide, ms ? -ms : 0
}

OsdHide() {
    global OsdGui
    if OsdGui
        OsdGui.Destroy()
    OsdGui := 0
}

; Current theme colors (theme.css) and font (status.json); Tokyo Night if missing.
ThemeColors() {
    pack := Env("pack")
    c := {bg: "1a1b26", fg: "a9b1d6", font: "JetBrainsMono NF"}
    try {
        css := FileRead(pack "\theme.css")
        if RegExMatch(css, "--bg:\s*#([0-9a-fA-F]{6})", &m)
            c.bg := m[1]
        if RegExMatch(css, "--fg:\s*#([0-9a-fA-F]{6})", &m)
            c.fg := m[1]
    }
    try {
        if RegExMatch(FileRead(pack "\status.json"), '"font":\s*"([^"]+)"', &m)
            c.font := m[1]
    }
    ; GDI (this window) only knows Nerd Fonts by their short family names.
    c.font := RegExReplace(RegExReplace(c.font, "i) Nerd Font Mono$", " NFM"), "i) Nerd Font$", " NF")
    return c
}
