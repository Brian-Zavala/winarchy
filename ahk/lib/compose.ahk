; Omarchy's compose key (default/xcompose, install/user/xcompose.sh): CapsLock, then a
; short sequence, types a character. CapsLock m s = 😄, CapsLock Space Space = an em
; dash, CapsLock Space n / Space e = your name / email (from git, written by apply).
; Esc or 2 seconds without a key cancels. Your own sequences go in
; %USERPROFILE%\.winarchy\compose.txt, in the same form as Omarchy's ~/.XCompose:
;   <m> <z> : "😴"
; Caps Lock itself: both Shift keys together.
; Off with "compose": false in config.json (new installs have it on; installs from
; before keep CapsLock as it was), and always off with an input method (Japanese,
; Chinese, Korean), where CapsLock switches modes.

ComposeTable() {
    static table := 0
    if table
        return table
    table := Map()
    for seq, text in Map(
        "ms", "😄", "mc", "😂", "ml", "😍", "mv", "✌️", "mh", "❤️", "my", "👍", "mn", "👎",
        "mf", "🖕", "mw", "🤞", "mr", "🤘", "mk", "😘", "me", "🙄", "md", "🤤", "mm", "💰",
        "mx", "🎉", "m1", "💯", "mt", "🥂", "mp", "🙏", "mi", "😉", "mo", "👌", "mg", "👋",
        "ma", "💪", "mb", "🤯", "  ", "—")
        table[seq] := text
    if name := Env("composeName")
        table[" n"] := name
    if email := Env("composeEmail")
        table[" e"] := email
    try {
        for line in StrSplit(FileRead(Env("data") "\compose.txt", "UTF-8"), "`n", "`r") {
            seq := ComposeParseLine(line, &text)
            if seq != ""
                table[seq] := text
        }
    }
    return table
}

; '<m> <z> : "😴"  # comment' -> "mz", with text := 😴. "" for anything else.
ComposeParseLine(line, &text) {
    text := ""
    if !RegExMatch(line, '^\s*(?:<Multi_key>\s*)?((?:<[^>]+>\s*)+):\s*"((?:[^"\\]|\\.)*)"', &m)
        return ""
    seq := ""
    pos := 1
    while RegExMatch(m[1], "<([^>]+)>", &k, pos) {
        key := k[1]
        seq .= key = "space" ? " " : key = "minus" ? "-" : key = "period" ? "." : key = "comma" ? "," : key
        pos := k.Pos + k.Len
    }
    text := StrReplace(StrReplace(m[2], '\"', '"'), "\\", "\")
    return seq
}

; The text for a finished sequence; "" for none. Any key of the sequence may be typed in
; either case: CapsLock can be on.
ComposeLookup(seq, table := ComposeTable()) {
    return table.Has(seq) ? table[seq] : table.Has(StrLower(seq)) ? table[StrLower(seq)] : ""
}

; Could more keys still finish a sequence that starts like this?
ComposePrefix(seq, table := ComposeTable()) {
    for k in table
        if StrLen(k) > StrLen(seq) && SubStr(k, 1, StrLen(seq)) = seq
            return true
    return false
}

Compose(*) {
    seq := ""
    loop 8 {
        ih := InputHook("L1 T2", "{Esc}")
        ih.Start()
        ih.Wait()
        if ih.EndReason != "Max"
            return                                  ; Esc, the timeout, or a non-text key
        seq .= ih.Input
        if (text := ComposeLookup(seq)) != "" && !ComposePrefix(seq) {
            SendText text
            return
        }
        if !ComposePrefix(seq) && !ComposePrefix(StrLower(seq)) {
            if (text := ComposeLookup(seq)) != ""
                SendText text
            return
        }
    }
}

; Caps Lock with CapsLock taken: both Shift keys. Each Shift still works as Shift (~).
ComposeShift(*) {
    if GetKeyState("LShift", "P") && GetKeyState("RShift", "P")
        SetCapsLockState !GetKeyState("CapsLock", "T")
}
