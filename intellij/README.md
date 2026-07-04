# IdeaVim

[IdeaVim](https://github.com/JetBrains/ideavim) is the **Vim emulation plugin
for JetBrains IDEs** (IntelliJ, PyCharm, WebStorm, Rider, …). It gives you Vim
motions, modes, and mappings inside the IDE editor, while letting you bind keys
to the IDE's own *actions* (refactor, goto, run, git, tool windows). The config
file is `~/.ideavimrc` and uses Vimscript syntax.

The key idea is `<Action>(...)` — that's how a Vim mapping triggers a native
JetBrains command. You find an action's ID with the **IdeaVim: track action
Ids** toggle (or `:action VimFindActionIdAction`): enable it, run any IDE
command, and IdeaVim shows the ID to use.

- Docs: <https://github.com/JetBrains/ideavim/blob/master/README.md>
- Your config: `intellij/.ideavimrc` → symlinked to `~/.ideavimrc`

This config is **minimal & focused**: a small, curated set of maps per area, one
consistent namespace, and `<Action>(...)` used everywhere for IDE commands.

---

## The leader namespace

`<leader>` is **Space**; `<localleader>` is `\`. Every custom map lives under a
themed prefix:

| Prefix | Theme                     |
| ------ | ------------------------- |
| `e`    | Explorer / Project        |
| `f`    | Files                     |
| `g`    | Goto (bare `g`) / Git     |
| `c`    | Code / Refactor           |
| `m`    | Make / Run / Debug        |
| `t`    | Tests / Terminal          |
| `s`    | Settings / Search / Symbols |
| `a`    | AI                        |
| `v`    | Vim Coach                 |

---

## Options

```vim
set scrolloff=4        " keep 4 lines of context around the cursor
set nowrap             " don't wrap long lines
set number             " absolute line numbers (matches Neovim and Zed)
set ignorecase         " }
set smartcase          " } case-insensitive search unless you type a capital
set shiftround         " round indent to a multiple of shiftwidth
set incsearch          " jump to matches as you type the search
set hlsearch           " highlight all matches (clear with <leader>nh)
set backspace=indent,eol,start
set timeoutlen=1000    " ms to wait for the next key in a mapping
set clipboard+=unnamedplus   " yank/paste use the system clipboard
```

---

## Emulated plugins

```vim
set NERDTree           " Vim-style file tree (toggle: <leader>e)
set surround           " cs"'  ds(  ysiw)  — change/delete/add surroundings
set commentary         " gcc to comment a line, gc in visual mode
set highlightedyank    " briefly flash the text you yanked
" set easymotion       " (optional) <leader><leader> jump motions — needs AceJump
" set multiple-cursors " (optional) <A-n> to select next occurrence
```

- **surround** — `ysiw"` wraps a word in quotes, `cs"'` changes `"` to `'`,
  `ds(` deletes surrounding parens.
- **commentary** — `gcc` toggles a line comment, `gc` in visual mode comments
  the selection. (This replaces having a dedicated comment keybind.)
- **highlightedyank** — visual confirmation of what got yanked.
- The two commented lines are opt-in; uncomment if you want them (easymotion
  needs the AceJump plugin installed).

---

## Bindings, by area

### Navigation & windows

```vim
nmap <C-h/j/k/l> <C-w>h/j/k/l   " move focus between editor splits
nmap <A-k> <Action>(MoveLineUp)
nmap <A-j> <Action>(MoveLineDown)
nmap <leader>-       <C-w>s      " horizontal split
nmap <leader>\|      <C-w>v      " vertical split
nmap <leader><space> <Action>(GotoFile)    " fuzzy go-to-file
nmap <leader>/       <Action>(FindInPath)  " search the project
nnoremap <leader>nh  :nohlsearch<CR>       " clear search highlight
```

### `e` — Explorer / Project

```vim
nnoremap <leader>e  :NERDTreeToggle<CR>                 " toggle file tree
nmap     <leader>ep <Action>(ActivateProjectToolWindow) " focus Project window
```

### `f` — Files

```vim
nmap     <leader>fr <Action>(RecentFiles)
nmap     <leader>fn <Action>(NewElementSamePlace)   " new file/element here
nnoremap <leader>fc :e ~/.ideavimrc<CR>             " edit this config
```

### `g` — Goto (bare `g`) + Git (`<leader>g`)

```vim
" Goto
nmap gd <Action>(GotoDeclaration)
nmap gD <Action>(GotoSuperMethod)
nmap gi <Action>(GotoImplementation)
nmap gy <Action>(GotoTypeDeclaration)
nmap gr <Action>(FindUsages)

" Git
nmap <leader>gs <Action>(ActivateVersionControlToolWindow)  " status/VCS window
nmap <leader>gb <Action>(Git.Branches)                      " branches popup
nmap <leader>gc <Action>(CheckinProject)                    " commit
nmap <leader>gB <Action>(Annotate)                          " blame / annotate
nmap <leader>gh <Action>(Vcs.ShowTabbedFileHistory)         " file history
nmap <leader>gp <Action>(Vcs.UpdateProject)                 " update / pull
nmap <leader>gP <Action>(Vcs.Push)                          " push
```

### `c` — Code / Refactor

```vim
nmap <leader>cr <Action>(RenameElement)
nmap <leader>ca <Action>(ShowIntentionActions)   " lightbulb / quick-fix
nmap <leader>cf <Action>(ReformatCode)
nmap <leader>co <Action>(OptimizeImports)
```
> Commenting now lives in `commentary` (`gcc` / `gc`), not a `<leader>c` map.

### `m` — Make / Run / Debug

```vim
nmap <leader>mr <Action>(Run)
nmap <leader>md <Action>(Debug)
nmap <leader>ms <Action>(Stop)
nmap <leader>mb <Action>(ToggleLineBreakpoint)
nmap <leader>mc <Action>(ChooseRunConfiguration)
```

### `t` — Tests + Terminal

```vim
nmap <leader>tr <Action>(RunClass)          " run tests in current class
nmap <leader>tf <Action>(RerunFailedTests)
nmap <leader>tl <Action>(Rerun)             " rerun last
nmap <leader>tt <Action>(ActivateTerminalToolWindow)   " terminal
```

### `s` — Settings / Search / Symbols

```vim
nmap <leader>so <Action>(ShowSettings)
nmap <leader>sa <Action>(GotoAction)        " find any IDE action
nmap <leader>ss <Action>(GotoSymbol)
nmap <leader>sc <Action>(GotoClass)
nmap <leader>sr <Action>(IdeaVim.ReloadVimRc.reload)   " reload this config
```

### `a` — AI / `v` — Vim Coach

```vim
nmap <leader>a  <Action>(AIAssistant.Editor.AskAiAssistantInEditor)
nmap <leader>vt <Action>(com.github.pooryam92.vimcoach.actions.ShowVimTipAction)
```
> **Vim Coach** is a JetBrains Marketplace plugin that surfaces Vim tips. Install
> it for `<leader>vt` ("Vim Tip") to work; the mapping fires its *Show Tip*
> action.

---

## Day-to-day usage

- **Edit then reload:** open with `<leader>fc`, change something, save, then
  `<leader>sr` to apply without restarting the IDE.
- **Discover a binding target:** enable **IdeaVim: track action Ids**, run the
  IDE command via menu/shortcut, note the ID, then map it with `<Action>(ID)`.
- **Verify an action exists:** if a map "does nothing," the action ID is wrong —
  most failures are typos in the ID (this is exactly what bit the old reload
  map: `deaVim.…` instead of `IdeaVim.…`).
- **Resolve a key clash** (IdeaVim vs IDE shortcut): the IDE pops a handler
  picker; set the default in **Settings → Editor → Vim**.
- **Turn Vim off temporarily:** the **IdeaVim** entry in Tools (or the status-bar
  widget).

---

## Common tweaks

**Add an emulated plugin** — `set <name>` near the others (e.g. uncomment
`easymotion`/`multiple-cursors`, or add `set ReplaceWithRegister`, `set argtextobj`).

**Map a new IDE action** (find the ID first via tracking):
```vim
nmap <leader>gl <Action>(Git.Log)
nmap <leader>mt <Action>(RunConfiguration)
```

**Syntax notes:**
- Escape a literal `|` in a mapping as `\|` (see `<leader>\|`).
- Use `<Action>(ID)` for IDE actions; use `:cmd<CR>` only for real ex-commands
  (`:e`, `:nohlsearch`, `:NERDTreeToggle`).
- `nmap` is recursive; `nnoremap`/`noremap` aren't — prefer the `noremap` forms
  unless you need recursion. (Most `<Action>(...)` maps are written `nmap` here
  because there's nothing to recurse into.)

---

## Cheatsheet

| Keys              | Action                          |
| ----------------- | ------------------------------- |
| `<Space>`         | leader                          |
| `<leader><space>` | Go to file                      |
| `<leader>/`       | Find in path · `<leader>nh` clear hl |
| `<leader>e`       | Toggle file tree                |
| `Ctrl+h/j/k/l`    | Move between splits             |
| `<leader>-` / `\|`| Split horizontal / vertical     |
| `Alt+j` / `Alt+k` | Move line down / up             |
| `gd gi gy` / `gr` | Goto decl/impl/type · usages    |
| `gcc` / `cs"'`    | Comment line · change surround  |
| `<leader>cr/ca`   | Rename · quick-fix              |
| `<leader>cf/co`   | Reformat · optimize imports     |
| `<leader>mr/md`   | Run · Debug                     |
| `<leader>mb/ms`   | Breakpoint · Stop               |
| `<leader>tr/tf`   | Run tests · rerun failed        |
| `<leader>tt`      | Terminal                        |
| `<leader>g…`      | Git (s/b/c/B/h/p/P)             |
| `<leader>s…`      | Settings/action/symbol/class    |
| `<leader>sr`      | Reload `.ideavimrc`             |
| `<leader>a`       | Ask AI Assistant                |
| `<leader>vt`      | Vim Coach — show tip            |
