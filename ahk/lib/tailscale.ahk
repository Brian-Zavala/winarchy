; Omarchy Quattro's Tailscale widget (omarchy.tailscale) on Windows: what the bar icon and
; the panel read, and what they run. Shared by winarchy.ahk (the 30 s refresh, as Quattro's
; refreshIntervalSec) and menu.ahk (the panel's actions). Files in the pack:
;   tailscale.json           {"installed": bool} - the bar hides the icon without Tailscale
;   tailscale-status.json    `tailscale status --json`, as is (the panel parses it like
;                            Quattro's Model.js)
;   tailscale-exits.txt      `tailscale exit-node list` (Mullvad locations)
;   tailscale-accounts.json  `tailscale switch --list --json`

TailscaleExe() {
    return EnvGet("ProgramFiles") "\Tailscale\tailscale.exe"
}

; Refresh the files. wait = block until done (menu.ahk, after an action); otherwise the
; commands run in the background (winarchy.ahk's timer must never stall on them).
TailscaleRefresh(wait := false) {
    static last := ""
    pack := Env("pack")
    exe := TailscaleExe()
    installed := FileExist(exe) ? "true" : "false"
    if installed != last || wait {
        f := FileOpen(pack "\tailscale.json.tmp", "w", "UTF-8-RAW")
        f.Write('{"installed":' installed '}')
        f.Close()
        FileMove pack "\tailscale.json.tmp", pack "\tailscale.json", true
        last := installed
    }
    if installed = "false" {
        for name in ["tailscale-status.json", "tailscale-exits.txt", "tailscale-accounts.json"]
            try FileDelete pack "\" name
        return
    }
    ; One hidden cmd for all three, each written to a .tmp and moved into place, so a
    ; reader never sees half a file. A command that fails leaves an empty file (the panel
    ; reads that as "Unavailable", as Quattro does).
    step(args, file) => '"' exe '" ' args ' > "' pack '\' file '.tmp" 2>nul & move /y "' pack '\' file '.tmp" "' pack '\' file '" >nul'
    cmd := A_ComSpec ' /c "' step("status --json", "tailscale-status.json")
        . ' & ' step("exit-node list", "tailscale-exits.txt")
        . ' & ' step("switch --list --json", "tailscale-accounts.json") '"'
    try {
        if wait
            RunWait cmd, , "Hide"
        else
            Run cmd, , "Hide"
    }
}

; BackendState from the last status ("Running", "Stopped", "NeedsLogin", ...), or "".
TailscaleState() {
    try if RegExMatch(FileRead(Env("pack") "\tailscale-status.json", "UTF-8"), '"BackendState":\s*"([^"]*)"', &m)
        return m[1]
    return ""
}

; Run tailscale.exe hidden and wait for it, but never longer than `secs`: `tailscale up`
; waits for a sign-in that may never come. Returns the exit code, or -1.
TailscaleRun(args, secs := 20) {
    exe := TailscaleExe()
    if !FileExist(exe)
        return -1
    try {
        Run '"' exe '" ' args, , "Hide", &pid
        if ProcessWaitClose(pid, secs)
            ProcessClose pid
        return 0
    }
    return -1
}

; The panel's and the bar icon's actions (menu.ahk tailscale <what> [arg]).
TailscaleAction(what, arg := "") {
    if !FileExist(TailscaleExe()) {
        Osd("Tailscale is not installed (Omarchy menu > Install > Service > Tailscale)")
        Sleep 1300
        return
    }
    switch what {
        ; Right click on the icon (Quattro's toggleTailscale): off when on, else on or sign in.
        case "toggle":
            state := TailscaleState()
            if state = "Running"
                TailscaleRun("down")
            else if state = "NeedsLogin"
                return TailscaleAction("login")
            else
                TailscaleRun("up")
        case "up": TailscaleRun("up")
        case "down": TailscaleRun("down")
        ; Quattro opens the pending AuthURL in the browser, else runs `tailscale up`: here the
        ; login runs in a terminal, which prints the link to open.
        case "login":
            url := ""
            try if RegExMatch(FileRead(Env("pack") "\tailscale-status.json", "UTF-8"), '"AuthURL":\s*"(https?://[^"]+)"', &m)
                url := m[1]
            if url
                Run url
            else
                RunInTerminal("Tailscale sign-in", '"' TailscaleExe() '" login')
        case "exit-node": TailscaleRun("set --exit-node=" (arg = "none" ? "" : arg))
        case "switch":
            if arg != ""
                TailscaleRun("switch " arg)
        ; Taildrop (Quattro's omarchy-tailscale-send): pick files, send them to the machine.
        case "send":
            files := FileSelect("M3", EnvGet("USERPROFILE"), "Send to " arg " with Taildrop")
            if !files.Length
                return
            list := ""
            for f in files
                list .= ' "' f '"'
            Osd("Sending " files.Length " file" (files.Length = 1 ? "" : "s") " to " arg "…", 0)
            code := -1
            try code := RunWait('"' TailscaleExe() '" file cp' list ' "' arg ':"', , "Hide")
            Osd(code = 0 ? "Sent to " arg : "Taildrop to " arg " failed (is file sharing on for your tailnet?)", 2500)
            Sleep 2600
    }
    TailscaleRefresh(true)
}
