# Shell Functions

Winarchy adds Omarchy's Herdr layouts to your PowerShell profile. They build a layout around the Herdr pane you run them in, so start [Herdr](15-terminal.md) first (`Super + Ctrl + Return`).

| Command | Layout |
|---|---|
| `hdl <agent> [<agent2>]` | Your editor, the agent on the right (30%), and a terminal along the bottom (15%). A second agent splits the agent pane in half. The tab is named after the folder |
| `hds` | A 2x2 square: your editor, a live diff, a terminal, and OpenCode (or your default agent without it). The diff is `hunk diff --watch` when hunk is installed, and a git diff that refreshes otherwise |
| `hdlm <agent> [<agent2>]` | One `hdl` tab for every subfolder of the current folder, skipping dot-folders: a whole monorepo at once |
| `hsl <count> <command>` | A swarm: `count` panes in an even grid, all running the same command, e.g. `hsl 4 claude` |

`<agent>` is any agent name from [AI](17-ai.md), or Omarchy's shorthand: `c` for OpenCode, `cx` for Claude Code, `cy` for Codex, and `a` for your default agent. Anything else is run as typed, so `hdl lazygit` works too. Each agent starts with its own "don't stop to ask" flags.

The functions live in your PowerShell profile, `Documents\PowerShell\profile.ps1`, between `winarchy herdr shortcuts` markers, and call `winarchy herdr layout`, `square`, `multi` and `swarm`. Running them outside a Herdr pane says so instead of doing anything.
