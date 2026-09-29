#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
#Include lib\launch.ahk
OnError ScriptLogError

; Omarchy's app launchers (default/hypr/bindings/utilities.lua and applications.lua),
; mapped to what this PC has. Started by winarchy.ahk when config.json "launchers" is
; true; set it to false (then `winarchy apply`) to use your own launcher script instead.
; A key your own Startup script already has is left to it (BindUnlessUser, lib\env.ahk).

for hk, fn in Map(
    "#Enter",  (*) => Run(Env("terminal", "wt.exe")),                     ; terminal
    "#+b",     (*) => OpenBrowser(),                                      ; browser (also Super+Shift+Return)
    "#+f",     (*) => Run(Env("files", "explorer.exe")),                  ; file manager
    "#+n",     (*) => OpenEditor(),                                       ; editor
    "#+m",     (*) => RunIfInstalled(A_AppData "\Spotify\Spotify.exe", "https://open.spotify.com"),   ; music
    "#+SC035", (*) => RunIfInstalled(EnvGet("LOCALAPPDATA") "\1Password\app\8\1Password.exe", ""),  ; Super+Shift+/: passwords
    "#+o",     (*) => RunIfInstalled(EnvGet("LOCALAPPDATA") "\Programs\Obsidian\Obsidian.exe", ""),     ; notes
    "#+g",     (*) => RunIfInstalled(EnvGet("LOCALAPPDATA") "\Programs\signal-desktop\Signal.exe", ""), ; messenger
    "#+d",     (*) => RunTui("lazydocker", "lazydocker", "", "TUI > lazydocker"),   ; Docker
    "#+!m",    (*) => RunTui("Cliamp", "cliamp", "", "TUI > Cliamp"),              ; music in the terminal
    "#+w",     (*) => RunPort("omawrite", "Omawrite"))                            ; Omarchy's writing app
    BindUnlessUser(hk, fn)

; The web apps' keys: HEY (Super+Shift+E), its calendar (+C), ChatGPT (+A), YouTube (+Y),
; WhatsApp (+Alt+G), ... (default/webapps.json; Super+K lists them all).
BindWebAppKeys()

OpenBrowser() {
    exe := Env("browser")
    try Run(exe ? '"' exe '"' : "https://")
}

OpenEditor() {
    editor := Env("editor", "notepad.exe")
    if editor ~= "i)nvim(\.exe)?$"
        RunInTerminal("nvim", '"' editor '"')
    else
        Run '"' editor '"'
}

RunIfInstalled(exe, fallback) {
    if FileExist(exe)
        Run '"' exe '"'
    else if fallback
        Run fallback
}
