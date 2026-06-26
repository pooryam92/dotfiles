# zoxide

[zoxide](https://github.com/ajeetdsouza/zoxide) is a **smarter `cd`**. It
remembers the directories you visit and ranks them by *frecency* (frequency +
recency), so instead of typing a full path you type a fragment and jump:

```sh
z dot        # jumps to ~/dotfiles (the most "frecent" match for "dot")
z proj api   # match multiple fragments in order
zi dot       # interactive: pick from all matches with fzf
z -          # back to the previous directory
```

- Docs: <https://github.com/ajeetdsouza/zoxide>
- Installed as a user binary by both installers (scoop on Windows, the official
  install script into `~/.local/bin` on Linux).

It learns as you go — the database starts empty and fills in as you `cd`/`z`
around. The more you use a directory, the higher it ranks.

---

## How it's wired in this repo

zoxide needs a shell hook that records the current directory on each prompt.
Both shells initialise it **right after Starship**, so zoxide's prompt hook
wraps Starship's prompt instead of clobbering it:

- **zsh** (`zsh/.zshrc`):

  ```sh
  command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
  ```

- **PowerShell** (`pwsh/profile.ps1`): initialised through the shared
  `Initialize-Cached` helper (same disk-cache trick as Starship — the generated
  init script is cached and only regenerated when the `zoxide` binary is newer):

  ```powershell
  Initialize-Cached zoxide
  ```

This adds the `z` and `zi` commands. Your normal `cd` (and the `..`/`...`
helpers) keep working unchanged.

---

## Day-to-day usage

| Command       | Action                                              |
| ------------- | --------------------------------------------------- |
| `z foo`       | Jump to the highest-ranked dir matching `foo`       |
| `z foo bar`   | Match `foo` then `bar` in the path                  |
| `z foo/`      | Append `/` to cd into a literal subdir of a match   |
| `zi foo`      | Interactive pick from matches (uses fzf)            |
| `z -`         | Previous directory                                  |
| `z`           | Home (no argument)                                  |

`zi` needs **fzf** for the interactive list. Both installers install it (scoop
on Windows, `apt` on Linux), so the picker behaves the same on both machines.

---

## Common tweaks

**Replace `cd` entirely** — make `cd` use zoxide's database so muscle memory
just works. Change the init line to pass `--cmd cd`:

```sh
eval "$(zoxide init zsh --cmd cd)"          # zsh
```
```powershell
Initialize-Cached zoxide @('init', 'powershell', '--cmd', 'cd')   # pwsh
```

Then `cd dot` jumps the zoxide way and `cdi` is the interactive picker.

**Inspect / clean the database:**

```sh
zoxide query -l           # list all tracked dirs, ranked
zoxide remove /old/path   # forget a directory
```
