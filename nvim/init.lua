--[[
Neovim config — single file, minimal base for quick edits, git commit messages
and Ctrl+X Ctrl+E from the shell. Project editing lives in Zed / JetBrains.

  :help lua-guide
  :help vim.pack
  :checkhealth
--]]

-- ==== Options ====
do
  vim.loader.enable()

  -- Leader must be set before plugins load.
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  vim.g.have_nerd_font = true

  vim.o.number = true
  vim.o.mouse = 'a'
  vim.o.showmode = false

  -- Clipboard is scheduled after startup so it doesn't slow launch.
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- listchars needs a table, hence vim.opt.
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  vim.o.inccommand = 'split'
  vim.o.cursorline = true
  vim.o.scrolloff = 10
  vim.o.confirm = true
end

-- ==== Keymaps ====
do
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  vim.keymap.set('n', '<leader>-', '<C-w>s', { desc = 'Split window below' })
  vim.keymap.set('n', '<leader>|', '<C-w>v', { desc = 'Split window right' })

  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ==== Colorscheme ====
do
  -- vim.pack is Neovim's built-in plugin manager; tokyonight is the only plugin.
  --   :lua vim.pack.update()    update installed plugins
  vim.pack.add { 'https://github.com/folke/tokyonight.nvim' }
  require('tokyonight').setup {
    style = 'night',
    styles = { comments = { italic = false } },
  }
  vim.cmd.colorscheme 'tokyonight-night'
end

-- vim: ts=2 sts=2 sw=2 et
