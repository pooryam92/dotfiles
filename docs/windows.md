# Windows

This setup runs **natively on Windows** — no WSL. The stack is the same as Linux,
with two substitutions:

| Layer        | Linux            | Windows                          |
| ------------ | ---------------- | -------------------------------- |
| Terminal     | WezTerm          | WezTerm *(same config)*          |
| Multiplexer  | Zellij           | Zellij *(native, v0.44+ ConPTY)* |
| Shell        | zsh              | **PowerShell 7 (pwsh)**          |
| Prompt       | Starship         | Starship *(same config)*         |
| Editor       | Neovim           | Neovim *(same config)*           |
| IDE editing  | IdeaVim          | IdeaVim *(same `.ideavimrc`)*    |

The **shell is the only real difference** — `pwsh/profile.ps1` is the Windows
counterpart of `zsh/.zshrc`. Everything else is the identical config file linked
to a Windows path.

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
3. Installs: `pwsh`, `neovim`, `starship`, `wezterm`, `zig` (treesitter
   compiler), `ripgrep`, `fd`, `fzf`, `win32yank` (nvim clipboard), `zellij`,
   `zoxide` (smarter `cd`), and the **JetBrainsMono Nerd Font**.
4. Links the configs to their Windows paths (see below).

### Config paths on Windows

```
wezterm/wezterm.lua    ->  %USERPROFILE%\.config\wezterm\wezterm.lua
starship/starship.toml ->  %USERPROFILE%\.config\starship.toml
zellij/config.kdl      ->  %APPDATA%\zellij\config.kdl          (Roaming, not ~/.config)
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
| accept suggestion        | `Ctrl+E` (whole) / `Ctrl+F` (next word); `End` also works — matches zsh |
| syntax highlighting      | PSReadLine inline command coloring (built in)        |
| history dedup            | `-HistoryNoDuplicates -MaximumHistoryCount 50000`    |
| Up/Down history search   | `HistorySearchBackward/Forward` key handlers         |
| vi keybindings           | `-EditMode Vi` (matches zsh `bindkey -v`)            |
| `menu select` completion | `Tab` → `MenuComplete`                               |
| aliases (`zj`,`ll`,`..`) | `Set-Alias` + functions                              |
| starship                 | `Initialize-Cached starship` (cached `init`)         |
| zoxide (`z`/`zi`)        | `Initialize-Cached zoxide` — see [zoxide.md](zoxide.md) |

**Zellij auto-start** is guarded the same way as on Linux — it only fires inside
WezTerm (`$env:WEZTERM_PANE`) and when not already inside Zellij. PowerShell
isn't a supported target for `zellij setup --generate-auto-start`, so the profile
attaches manually (`zellij attach --create main`) and exits pwsh **only on a
clean detach** — if Zellij fails to launch it falls through to a normal prompt
instead of trapping the window in an open-then-close loop.

---

## Neovim on Windows

The Neovim config (`nvim/init.lua`) is **unchanged** — it already guards
Windows-specific build steps. Windows just needs the dependencies the installer
provides:

- **zig** — the C compiler nvim-treesitter uses to build parsers.
- **ripgrep + fd** — power Telescope (`<leader>sf`, live grep).
- **win32yank** — Neovim auto-detects it for `clipboard=unnamedplus`.

After install, run `:checkhealth` and confirm the **Clipboard** and
**Treesitter** sections are green.

> If treesitter parser compilation hangs (a known zig-on-Windows issue), install
> Visual Studio Build Tools (or LLVM/clang) so nvim-treesitter uses MSVC/clang
> instead, or use prebuilt parsers.

---

## Troubleshooting

- **`install.ps1` won't run** — you skipped `-ExecutionPolicy Bypass`, or you're
  not in a real console. Use the exact first-run command above.
- **Profile didn't load / no Starship prompt** — confirm the link target with
  `pwsh -NoProfile -Command '$PROFILE.CurrentUserAllHosts'` and check a file is
  linked there. OneDrive redirection is the usual culprit.
- **Tofu boxes (□)** — set WezTerm's font to `JetBrainsMono Nerd Font` and
  confirm the font installed (`scoop list` should show `JetBrainsMono-NF`).
- **Zellij behaves oddly (mouse/flicker)** — ensure you're on Zellij ≥ 0.44.1
  (`zellij --version`); Windows ConPTY support is recent. `scoop update zellij`.
- **Configs were copied, not linked** — enable Developer Mode and re-run.
