# Starship

[Starship](https://starship.rs) is the **prompt** — the line(s) before your
cursor that show where you are and what's going on (current directory, git
branch/status, language versions, how long the last command took). It's a single
binary, configured with one TOML file, and works the same across any shell.

zsh hands the prompt to Starship via `eval "$(starship init zsh)"` (see
[zsh.md](zsh.md)).

> **Linux/zsh only.** On Windows, pwsh uses a small native `prompt` function
> instead of Starship — Starship shells out to `starship.exe` on every prompt
> draw (~200ms of lag per command there), so it's dropped from the Windows install
> for speed. This page applies to the zsh side; see [windows.md](windows.md) for
> the native prompt.

- Docs / full config reference: <https://starship.rs/config/>
- All modules: <https://starship.rs/config/#prompt>
- Your config: `starship/starship.toml` → symlinked to `~/.config/starship.toml`

> Starship uses **Nerd Font glyphs** for its icons. They render because WezTerm
> uses JetBrainsMono Nerd Font — without a Nerd Font you'd see boxes.

---

## How Starship works

A prompt is built from **modules** (directory, git_branch, python, …). Each
module:
1. **only shows when relevant** — e.g. `python` appears only in a directory with
   a `.py` file or `pyproject.toml`. This keeps the prompt clean.
2. is laid out by the top-level **`format`** string.
3. can be styled/tweaked in its own `[module]` table.

So configuring Starship is two jobs: **arrange** modules in `format`, and
**customize** individual modules in their tables.

---

## Your config, explained

### Top level

```toml
"$schema" = 'https://starship.rs/config-schema.json'
add_newline = true
command_timeout = 1000
```

- `$schema` — enables autocomplete/validation in editors that understand it.
- `add_newline` — blank line before each prompt, so commands are visually
  separated.
- `command_timeout` — max ms Starship waits for a module's external command
  (e.g. `git`) before giving up. Raised to 1000 so slower git repos still show
  status.

### The format string

```toml
format = """
$directory\
$git_branch\
$git_status\
$git_state\
$python\
$jobs\
$line_break\
$status$character"""
```

This is the **order** modules render in. Reading it top to bottom:

1. `$directory` — current path.
2. `$git_branch` `$git_status` `$git_state` — branch name, dirty/ahead/behind
   markers, and in-progress states (rebase/merge).
3. `$python` — the Python icon, plus the active virtualenv name when one
   is set (only while a venv is active).
4. `$jobs` — count of background jobs, if any.
5. `$line_break` — drop to a new line…
6. `$status$character` — the last command's exit code (only on failure),
   then the `❯` you actually type at, both on their own line.

> The trailing `\` on each line is a **line continuation** — it joins the lines
> so they render on one prompt line, *except* where `$line_break` forces a break.
> The two-line result: info on top, a clean `❯` to type at below.

### The right prompt

```toml
right_format = """$cmd_duration$time"""
```

Starship can also render a **right-aligned** prompt, pinned to the right edge of
the same line as `$directory`. We use it for *transient/ambient* info that
shouldn't crowd what you type:

- `$cmd_duration` — how long the last command took (only if slow).
- `$time` — a dim clock.

Pushing these right keeps the left side tight and scannable. `right_format`
works identically in zsh and PowerShell.

### Directory

```toml
[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true
truncation_symbol = "…/"
read_only = " "
```

- `truncation_length = 3` — show at most the last 3 path components.
- `truncate_to_repo` — inside a git repo, show the path **relative to the repo
  root** instead of the full filesystem path.
- `truncation_symbol = "…/"` — prefix shown when the path was shortened, so a
  truncated path is visibly truncated (e.g. `…/src/app`).
- `read_only` — glyph shown when the directory isn't writable.

### Git

```toml
[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold red"

[git_state]
style = "bold yellow"
```

- `git_branch` — the branch name, with a branch glyph.
- `git_status` — symbols for uncommitted changes, staged files, ahead/behind,
  stashes, etc. (red).
- `git_state` — shows when a rebase/merge/cherry-pick is in progress (yellow).

### Character (the prompt symbol)

```toml
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

- Green `❯` after a command **succeeds**, red `❯` after one **fails** (instant
  visual feedback on exit codes).
- There's **no `vimcmd_symbol`**: both shells use emacs-style editing (`bindkey -e`
  in zsh, `EditMode = 'Emacs'` in PSReadLine), so there's no vi normal mode for it
  to signal. If you ever switch a shell back to vi editing, add
  `vimcmd_symbol = "[❮](bold yellow)"` here — the color change (not just the flipped
  arrow) is what makes the insert→normal switch obvious at a glance.

> Note the `[text](style)` syntax — that's Starship's inline styling format used
> throughout config strings.

### Exit status

```toml
[status]
disabled = false
format = "[$symbol$status]($style) "
symbol = "✘"
style = "bold red"
```

Shows the **exit code** of the last command, but **only when it failed**, just
before the `❯`. The red `❯` already tells you *something* failed; this adds the
actual number — e.g. `✘130` (Ctrl-C), `✘127` (command not found). Off by
default, hence `disabled = false`.

### Background jobs

```toml
[jobs]
symbol = " "
style = "bold blue"
number_threshold = 1
```

Shows a count of **background jobs** (e.g. after `sleep 5 &`). Hidden when there
are none (`number_threshold = 1`).

### Command duration

```toml
[cmd_duration]
min_time = 500
format = "[ $duration]($style)"
style = "yellow"
```

- Only shows if the last command took **≥ 500 ms**, so quick commands don't clutter.
- Renders like ` 1.2s` in yellow — on the **right** edge (it's in `right_format`).

### Clock

```toml
[time]
disabled = false
format = "[ $time]($style)"
time_format = "%H:%M"
style = "dimmed white"
```

A dim 24-hour `HH:MM` clock on the **right** edge. Off by default, so we flip
`disabled = false`. Change `time_format` (a [strftime] string) for seconds,
12-hour, a date, etc.

[strftime]: https://docs.rs/chrono/latest/chrono/format/strftime/index.html

### Python (the one language module kept)

```toml
[python]
symbol = " "
format = "[$symbol($virtualenv )]($style)"
```

Python earns its place because it shows something you'd actually **act on**:
the active **virtualenv**. The name comes from `$VIRTUAL_ENV` — just an
environment variable, so there's **no subprocess** (unlike `$version`) — and it
stops you from `pip install`-ing into the wrong environment. The icon shows in
any Python project; the venv name is added only while a venv is active.

The other language modules (node / rust / go / c / java / dotnet) were
**removed**. With the version dropped they were just decorative icons, and in a
Node or Java repo the icon tells you nothing you don't already know. To bring
one back as a project-type cue (free now — no version lookup), re-add its table
and put its `$name` in `format`:

```toml
[rust]
symbol = "…"                  # a Nerd Font glyph — see `starship preset nerd-font-symbols`
format = "[$symbol]($style)"  # icon only — no $version, so no per-prompt subprocess
```

---

## Day-to-day usage

You don't "run" Starship — it just renders every prompt. Useful commands:

- **Explain what's slow:** `starship timings` — shows how long each module took
  (handy if your prompt ever feels laggy).
- **Print modules / see what's available:** `starship module --list`.
- **Check the binary/version:** `starship --version`.
- After editing `starship.toml`, the **next prompt** picks it up — no reload
  needed (press `Enter` to redraw).

---

## Common tweaks

**Add a module to the prompt** — put its `$name` in `format` (left prompt) or
`right_format` (right edge) where you want it. E.g. add an AWS-profile badge to
the left info line:
```toml
format = """
$directory\
$git_branch$git_status$git_state\
$aws\
$python\
$line_break\
$character"""
```
Most modules only render when relevant, so adding one is safe — it stays hidden
until it has something to show. (Some, like `time`/`status`, are
disabled by default and need `disabled = false` in their table — see above.)

**Move something between the left and right prompt** — cut its `$name` from one
of `format` / `right_format` and paste it into the other. E.g. to put the clock
back on the left, move `$time` out of `right_format` and into `format`.

**Change a color** — edit the module's `style` (e.g. `style = "bold green"`).
Styles accept colors, `bold`/`italic`/`underline`/`dimmed`, and `bg:` backgrounds.

**Show the full path instead of truncating:**
```toml
[directory]
truncation_length = 0
```

**Single-line prompt** — remove `$line_break` from `format` so `$character` sits
right after the info.

**Add a language not in the list** (e.g. Ruby, PHP) — just add its module name to
`format`; Starship has [modules](https://starship.rs/config/#nodejs) for dozens
of languages and tools (docker, kubernetes, aws, …).

**Use a ready-made preset** as a starting point:
```sh
starship preset nerd-font-symbols -o ~/.config/starship.toml   # careful: overwrites
```
See `starship preset --list` for all presets.

---

## Mental model recap

| To change…                  | Edit…                                  |
| --------------------------- | -------------------------------------- |
| What appears & in what order| the `format` string                    |
| A module's icon/color/text  | that `[module]` table                  |
| When a module appears       | usually automatic; some have `detect_*` and `disabled` keys |
| The typed-at symbol         | `[character]`                          |
