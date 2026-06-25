--[[
=====================================================================
Neovim configuration — lean starter
=====================================================================
A small, single-file config focused on the basics: sensible defaults,
a few keymaps, syntax highlighting (treesitter) and a fuzzy finder
(telescope). Heavier features — LSP, autocompletion, formatting,
snippets — were intentionally left out. Add them back as you grow into
them; the previous full config lives in git history if you want it.

Organized into numbered `do ... end` blocks so locals stay scoped to
the section that uses them:
  Section 1 — Options:      core editor settings + leader keys
  Section 2 — Keymaps:      global mappings + autocmds
  Section 3 — Plugins:      vim.pack intro + build hook
  Section 4 — Colorscheme:  tokyonight (matches WezTerm / Zellij)
  Section 5 — Treesitter:   syntax highlighting
  Section 6 — Telescope:    fuzzy find files / grep / buffers

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

--- Build a full GitHub URL from an `owner/repo` string, to keep specs short.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: PLUGIN MANAGER
-- ============================================================
do
  -- `vim.pack` is Neovim's built-in plugin manager (0.12+). The sections
  -- below install plugins with `vim.pack.add`.
  --   :lua vim.pack.update()    update all plugins
  --   :lua vim.pack.update(nil, { offline = true })   inspect state
  -- See `:help vim.pack`.

  -- Some plugins need a build step after install/update. This runs it.
  -- See `:help vim.pack-events`.
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      if ev.data.kind ~= 'install' and ev.data.kind ~= 'update' then return end

      -- telescope-fzf-native: a faster sorter, compiled with `make`.
      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        vim.system({ 'make' }, { cwd = ev.data.path }):wait()
      -- nvim-treesitter (main): compile/update language parsers.
      elseif name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
      end
    end,
  })
end

-- ============================================================
-- SECTION 4: COLORSCHEME
-- ============================================================
do
  -- folke/tokyonight.nvim — Night style, matching WezTerm / Zellij / Starship.
  -- Variants: tokyonight-storm, tokyonight-moon, tokyonight-day (light).
  vim.pack.add { gh 'folke/tokyonight.nvim' }
  require('tokyonight').setup {
    style = 'night',
    styles = { comments = { italic = false } }, -- non-italic comments
  }
  vim.cmd.colorscheme 'tokyonight-night'
end

-- ============================================================
-- SECTION 5: TREESITTER (syntax highlighting)
-- ============================================================
do
  -- nvim-treesitter parses files into a syntax tree, giving much better
  -- highlighting (and indentation) than regex. See `:help nvim-treesitter`.
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Install a baseline set of parsers up front.
  require('nvim-treesitter').install {
    'bash', 'c', 'diff', 'html', 'lua', 'luadoc',
    'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
  }

  -- On opening a file, start treesitter for its language if a parser is
  -- installed (auto-installing it when one is available).
  local available = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local language = vim.treesitter.language.get_lang(args.match)
      if not language then return end

      local installed = require('nvim-treesitter').get_installed 'parsers'
      if vim.tbl_contains(installed, language) then
        vim.treesitter.start(args.buf, language)
      elseif vim.tbl_contains(available, language) then
        require('nvim-treesitter').install(language):await(function()
          if vim.api.nvim_buf_is_valid(args.buf) then vim.treesitter.start(args.buf, language) end
        end)
      end
    end,
  })
end

-- ============================================================
-- SECTION 6: TELESCOPE (fuzzy finder)
-- ============================================================
do
  -- Telescope is a fuzzy finder for files, grep results, buffers, help
  -- tags, and more. Inside a picker, press `?` (normal) or <c-/> (insert)
  -- to see its mappings. See `:help telescope`.
  ---@type (string|vim.pack.Spec)[]
  local plugins = {
    gh 'nvim-lua/plenary.nvim', -- shared Lua utilities Telescope depends on
    gh 'nvim-telescope/telescope.nvim',
  }
  -- The native fzf sorter needs `make` to build it.
  if vim.fn.executable 'make' == 1 then table.insert(plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end
  vim.pack.add(plugins)

  require('telescope').setup {}
  pcall(require('telescope').load_extension, 'fzf')

  -- Picker keymaps. See `:help telescope.builtin`.
  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- Fuzzy search within the current buffer.
  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { previewer = false })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- Find files inside the Neovim config directory.
  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })
end

-- The line below is a modeline. See `:help modeline`.
-- vim: ts=2 sts=2 sw=2 et
