# zsh

[zsh](https://www.zsh.org) is the **shell** — the program that reads what you
type, runs commands, and manages history/completion/aliases. It's the glue of
this setup: it loads the plugins and draws the prompt. (Panes/tabs are WezTerm's
job — see [wezterm/README.md](../wezterm/README.md) — not the shell's.)

The config is **plugin-manager-free**: it sources the two plugins packaged by
apt (autosuggestions, syntax-highlighting) directly, so there's nothing extra to
update. The prompt is native zsh — no Starship, no subprocess per draw — and
renders identically to the pwsh prompt on Windows (goal #3): same layout, same
colors, same read-`.git/HEAD`-directly trick.

- Docs: <https://zsh.sourceforge.io/Doc/> · a gentler guide:
  <https://thevaluable.dev/zsh-install-configure-mouseless/>
- Your config: `zsh/.zshrc` → symlinked to `~/.zshrc`

> **The config is the documentation.** `.zshrc` is ~125 commented lines — read
> it top to bottom. It runs once per **interactive** shell: edit it, then
> `exec zsh` (or open a new shell) to apply.

## Where the guides live

- **Editing keys** — emacs mode, accepting autosuggestions, `Ctrl+X Ctrl+E`
  (edit in nvim), `Alt+.` (last arg): one canonical cheatsheet for both shells
  in [shell-editing.md](../docs/shell-editing.md)
- **Fuzzy keys** — `Ctrl+R` history · `Ctrl+T` files · `Alt+C` cd, plus the
  fd/rg/bat toolkit: [fzf.md](../docs/fzf.md)
- **Directory jumping** — `z` / `zi`: [zoxide.md](../docs/zoxide.md)

## Common tweaks

**Alias, env var, or function** — add to the Aliases section:

```sh
alias gs='git status'
mkcd() { mkdir -p "$1" && cd "$1"; }
```

**A tool that needs shell init** (nvm, direnv, …) — mirror the zoxide line near
the end of the file:

```sh
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
```
