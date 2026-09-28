# Herdr, configured the way Omarchy configures it: a port of Omarchy's config/herdr/config.toml,
# which itself mirrors Omarchy's old tmux config, so the keys are the ones tmux users know.
#   herdr workspace = tmux session    herdr tab = tmux window    herdr pane = tmux pane
#
# winarchy writes this file on `winarchy apply` and whenever the theme changes.
# To own it: Omarchy menu > Setup > Herdr Config. That copies this template to
# %USERPROFILE%\.winarchy\herdr.toml.tpl and uses yours from then on; saving it
# re-renders and reloads Herdr. Delete that copy to go back to this default.
# Every {{ ... }} is filled in by winarchy.

# Herdr's first-run panel (notifications, then agent integrations) is not needed:
# winarchy links every agent it finds on PATH for you, and the first Herdr pane says
# which, once. Herdr would write this itself when the panel is closed, but this file is
# rewritten on apply, so without it here the panel came back every time.
onboarding = false

[theme]
# Herdr ships catppuccin, tokyo-night, dracula, nord, gruvbox, one-dark, solarized,
# kanagawa, rose-pine, vesper and terminal. winarchy picks the built-in whose name matches
# your Omarchy theme; for the other themes it picks "terminal", which draws Herdr in your
# terminal's own palette - and winarchy themes Windows Terminal, so Herdr follows along
# either way. Hard-code a name here if you would rather choose yourself.
name = "{{ herdr_theme }}"
{{ herdr_theme_custom }}
[terminal]
# PowerShell 7, not the Windows PowerShell 5.1 that Herdr would otherwise start.
# Two things depend on it: `winarchy` is a PowerShell 7 script (in any PowerShell,
# `winarchy` resolves to the .ps1 ahead of the .cmd shim, and 5.1 cannot even parse it),
# and hdl / hds / hdlm / hsl live in the PowerShell 7 profile, which 5.1 never loads.
default_shell = '{{ herdr_shell }}'

# Every split, tab and workspace opens in the current pane's directory,
# like tmux's -c "#{pane_current_path}".
new_cwd = "follow"

[keys]
prefix = "ctrl+space"

# Config and help
reload_config = "prefix+q"
help = "prefix+?"
detach = "prefix+d"

# Copy mode
copy_mode = "prefix+["

# Panes
split_horizontal = ["prefix+h", "alt+enter"]
split_vertical = ["prefix+v", "alt+shift+enter"]
close_pane = ["prefix+x", "alt+esc"]
zoom = "prefix+z"
last_pane = "prefix+;"

focus_pane_left = "ctrl+alt+left"
focus_pane_down = "ctrl+alt+down"
focus_pane_up = "ctrl+alt+up"
focus_pane_right = "ctrl+alt+right"

resize_mode = ["prefix+ctrl+left", "prefix+ctrl+down", "prefix+ctrl+up", "prefix+ctrl+right"]

# Like tmux resize-pane on C-M-S-arrows
resize_pane_left = "ctrl+alt+shift+left"
resize_pane_down = "ctrl+alt+shift+down"
resize_pane_up = "ctrl+alt+shift+up"
resize_pane_right = "ctrl+alt+shift+right"

# No tmux equivalent; Herdr's own prefix+shift+p is taken by previous workspace
rename_pane = "prefix+shift+o"

# tmux windows -> Herdr tabs
new_tab = "prefix+c"
rename_tab = "prefix+r"
close_tab = "prefix+k"
switch_tab = ["prefix+1..9", "alt+1..9"]
previous_tab = ["prefix+p", "alt+left"]
next_tab = ["prefix+n", "alt+right"]

# Like tmux swap-window -t -1/+1 on M-S-Left/Right
move_tab_previous = "alt+shift+left"
move_tab_next = "alt+shift+right"

# tmux sessions -> Herdr workspaces
new_workspace = "prefix+shift+c"
rename_workspace = "prefix+shift+r"
close_workspace = "prefix+shift+k"
previous_workspace = ["prefix+shift+p", "alt+up"]
next_workspace = ["prefix+shift+n", "alt+down"]

[ui]
{{ herdr_accent }}

# tmux drew single-line dividers between adjacent panes and no outer frame
pane_gaps = false
pane_outer_borders = false

# tmux had no scrollbar column beside its panes
pane_scrollbars = false

# tmux's kill-window and kill-session never asked
confirm_close = false

# tmux's automatic-rename gave windows a name without prompting
prompt_new_tab_name = false

# set -g mouse on
mouse_capture = true

# Left at "auto", which is what Windows wants: Herdr draws its own cursor on native
# Windows builds, because ConPTY makes the terminal's own cursor flicker and lands IME
# candidate windows in the wrong place. Set "native" if you would rather have your
# terminal's cursor and can live with that.
# host_cursor = "auto"

# tmux's status-right had the zoom flag followed by #h
tab_bar_right = [{ type = "zoom" }, { type = "hostname" }]

# set -g set-titles on / set-titles-string '#h:#W'. Resolved on the server, so a
# remote session names the remote host.
window_title = "{hostname}: {workspace}"
