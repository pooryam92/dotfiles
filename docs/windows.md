# Windows

This setup runs **natively on Windows** — no WSL. The stack is the same as Linux,
with two substitutions:

| Layer        | Linux            | Windows                          |
| ------------ | ---------------- | -------------------------------- |
| Terminal     | WezTerm          | WezTerm *(same config)*          |
| Multiplexer  | WezTerm built-in | WezTerm built-in *(same config)* |
| Shell        | zsh              | **PowerShell 7 (pwsh)**          |
| Prompt       | Starship         | **native pwsh prompt** *(see below)* |
| Editor       | Neovim           | Neovim *(same config)*           |
| IDE editing  | IdeaVim          | IdeaVim *(same `.ideavimrc`)*    |

The **shell is the only real difference** — `pwsh/profile.ps1` is the Windows
counterpart of `zsh/.zshrc`. Everything else is the identical config file linked
to a Windows path.

> **Windows prompt is native, not Starship.** Starship shells out to `starship.exe`
> on *every* prompt draw (~200ms of lag after each command on Windows) plus ~180ms
> at launch. To keep pwsh fast, the profile uses a small native `prompt` function
> instead — path + git branch (read from `.git/HEAD`, no `git` subprocess) + a `>`
> that turns red on failure. zsh on Pop!_OS still uses Starship; mirror the native
> prompt into `.zshrc` if you want the two shells identical again.

---

## Install

`install.ps1` uses [scoop](https://scoop.sh) (user-scope, no admin needed).

**First run** — pwsh 7 doesn't exist yet, so start from the always-present
Windows PowerShell 5.1:

```powershell
git clone https://github.com/pooryam92/dotfiles $HOME\dotfiles
cd $HOME\dotfiles
powershell -ExecutionPolicy Bypass -File install.ps1
```

It is **idempotent** — safe to re-run. Existing files are backed up to
`<file>.bak.<timestamp>` before linking.

### Enable Developer Mode (recommended, one-time)

File symlinks on Windows require **Developer Mode** or admin. Turn it on once:
**Settings → System → For developers → Developer Mode**. Then `install.ps1`
creates live symlinks (edit a repo file, the change is live). Without it, the
installer **copies** the files instead and warns you — re-run after enabling
Developer Mode to upgrade copies to links. (The `nvim/` directory uses a
*junction*, which never needs privilege.)

---

## What `install.ps1` does

1. Sets `ExecutionPolicy` for the current user to `RemoteSigned` (so the profile
   loads on future launches).
2. Bootstraps **scoop** if missing; adds the `extras` and `nerd-fonts` buckets.
3. Installs: `pwsh`, `neovim`, `wezterm`, `fzf` (fuzzy finder — powers `zi`),
   `win32yank` (nvim clipboard), `zoxide` (smarter `cd`), and the
   **JetBrainsMono Nerd Font**. (No `starship` on Windows — the profile uses a
   native prompt — and no `PSFzf`.)
4. Links the configs to their Windows paths (see below).

### Config paths on Windows

```
wezterm/wezterm.lua    ->  %USERPROFILE%\.config\wezterm\wezterm.lua
intellij/.ideavimrc    ->  %USERPROFILE%\.ideavimrc
nvim/                  ->  %LOCALAPPDATA%\nvim                  (junction)
pwsh/profile.ps1       ->  $PROFILE.CurrentUserAllHosts         (resolved from pwsh)
```

> The pwsh profile path is resolved by asking pwsh itself
> (`pwsh -NoProfile -Command '$PROFILE.CurrentUserAllHosts'`) so it's correct
> even when **Documents is redirected to OneDrive** (common on Windows 11).

---

## The PowerShell profile (vs `.zshrc`)

`pwsh/profile.ps1` reproduces the zsh experience with built-in
[PSReadLine](https://learn.microsoft.com/powershell/module/psreadline/):

| zsh feature              | PowerShell                                            |
| ------------------------ | ---------------------------------------------------- |
| autosuggestions          | `Set-PSReadLineOption -PredictionSource History` (inline ghost text) |
| accept suggestion        | `Ctrl+E` (whole) / `Alt+F` (next word); `End` also works — matches zsh |
| syntax highlighting      | PSReadLine inline command coloring (built in)        |
| history dedup            | `-HistoryNoDuplicates -MaximumHistoryCount 50000`    |
| Up/Down history search   | `HistorySearchBackward/Forward` key handlers         |
| emacs keybindings        | `-EditMode Emacs` (matches zsh `bindkey -e`); `Ctrl+X Ctrl+E` edits the line in `$EDITOR`, `Alt+.` yanks the last arg |
| `menu select` completion | `Tab` → `MenuComplete`                               |
| aliases (`ll`,`..`)      | `Set-Alias` + functions                              |
| starship prompt          | **native `prompt` function** (no subprocess — path + git branch from `.git/HEAD` + red-on-error `>`) |
| zoxide (`z`/`zi`)        | cached `zoxide init` — see [zoxide.md](zoxide.md)    |

**No multiplexer auto-start.** Panes and tabs are WezTerm's job (direct Alt
chords — see [wezterm.md](wezterm.md)), so the profile doesn't
launch Zellij or anything else; opening a WezTerm window drops you straight at the
pwsh prompt. The
pane/tab keybinds are identical to Linux because they live in the shared
`wezterm.lua`.

---

## Neovim on Windows

The Neovim config (`nvim/init.lua`) is a minimal base — just options, keymaps,
and a colorscheme — so it has no build steps. The only dependency it actually
needs on Windows is clipboard support:

- **win32yank** — Neovim auto-detects it for `clipboard=unnamedplus`.

After install, run `:checkhealth` and confirm the **Clipboard** section is green.

> The bare config is colorscheme-only, so it needs no parser toolchain — `zig`,
> the `tree-sitter` CLI, `ripgrep` and `fd` are deliberately **not** installed.
> If you grow the nvim config back (treesitter + Telescope), add them then; see
> [nvim.md](nvim.md).

---

## Troubleshooting

- **`install.ps1` won't run** — you skipped `-ExecutionPolicy Bypass`, or you're
  not in a real console. Use the exact first-run command above.
- **Profile didn't load / no prompt** — confirm the link target with
  `pwsh -NoProfile -Command '$PROFILE.CurrentUserAllHosts'` and check a file is
  linked there. OneDrive redirection is the usual culprit.
- **Tofu boxes (□)** — set WezTerm's font to `JetBrainsMono Nerd Font` and
  confirm the font installed (`scoop list` should show `JetBrainsMono-NF`).
- **Pane keys do nothing** (`Alt+\`, `Alt+h/j/k/l`, …) — WezTerm didn't pick up the
  config. Reload with `ctrl+shift+r`, or check `wezterm.lua` is actually linked
  (not a stale copy).
- **Configs were copied, not linked** — enable Developer Mode and re-run.
