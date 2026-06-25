--[[
=====================================================================
Neovim configuration — minimal base
=====================================================================
A bare, single-file config: sensible defaults, a few keymaps, and a
colorscheme. Everything heavier — treesitter, fuzzy finder, LSP,
autocompletion, formatting — is intentionally left out. Add pieces
back as you grow into them; richer configs live in git history.

Organized into numbered `do ... end` blocks so locals stay scoped to
the section that uses them:
  Section 1 — Options:      core editor settings + leader keys
  Section 2 — Keymaps:      global mappings + autocmds
  Section 3 — Colorscheme:  tokyonight (matches WezTerm)

Reference docs:
  :help lua-guide     (Lua in Neovim)
  :help vim.pack      (the built-in plugin manager)
  :checkhealth        (diagnose problems)
--]]

-- ============================================================
-- SECTION 1: OPTIONS
-- ============================================================
do
  -- Cache compiled Lua modules to speed up startup.
  vim.loader.enable()

  -- Leader keys. Must be set before plugins load.
  -- See `:help mapleader`
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- A Nerd Font is installed by the dotfiles; enables icon glyphs.
  vim.g.have_nerd_font = true

  -- [[ Editor options ]] — see `:help vim.o` and `:help option-list`

  -- Line numbers in the gutter.
  vim.o.number = true
  -- Relative numbers (commented out): make vertical motions like 5j easy.
  -- vim.o.relativenumber = true

  -- Enable the mouse in all modes; handy for resizing splits.
  vim.o.mouse = 'a'

  -- Hide the mode indicator; the statusline shows it.
  vim.o.showmode = false

  -- Use the system clipboard for yank/paste. Scheduled after startup so
  -- it doesn't slow launch. Remove to keep Neovim's clipboard separate.
  -- See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Wrapped lines keep their indentation.
  vim.o.breakindent = true

  -- Persist undo history to disk so it survives closing a file.
  vim.o.undofile = true

  -- Case-insensitive search unless the pattern has an uppercase letter.
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Always show the sign column so text doesn't shift around.
  vim.o.signcolumn = 'yes'

  -- Decrease update / mapped-sequence wait times (ms).
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300

  -- Open vertical splits right and horizontal splits below.
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Show whitespace characters. `listchars` needs a table, so vim.opt.
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Live preview of :substitute results.
  vim.o.inccommand = 'split'

  -- Highlight the line the cursor is on.
  vim.o.cursorline = true

  -- Keep some context above/below the cursor while scrolling.
  vim.o.scrolloff = 10

  -- Prompt to save instead of failing on :q with unsaved changes.
  vim.o.confirm = true
end

-- ============================================================
-- SECTION 2: KEYMAPS
-- ============================================================
do
  -- See `:help vim.keymap.set()`

  -- <Esc> clears search highlighting.
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Exit terminal mode with a double <Esc> (easier than <C-\><C-n>).
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Move focus between split windows with CTRL+<hjkl>.
  -- See `:help wincmd`
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Briefly highlight text after yanking it.
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 3: COLORSCHEME
-- ============================================================
do
  -- `vim.pack` is Neovim's built-in plugin manager (0.12+). tokyonight is the
  -- only plugin for now — Night style, matching WezTerm / Starship.
  -- Variants: tokyonight-storm, tokyonight-moon, tokyonight-day (light).
  --   :lua vim.pack.update()    update installed plugins
  -- See `:help vim.pack`.
  vim.pack.add { 'https://github.com/folke/tokyonight.nvim' }
  require('tokyonight').setup {
    style = 'night',
    styles = { comments = { italic = false } }, -- non-italic comments
  }
  vim.cmd.colorscheme 'tokyonight-night'
end

-- The line below is a modeline. See `:help modeline`.
-- vim: ts=2 sts=2 sw=2 et
