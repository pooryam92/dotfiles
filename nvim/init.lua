--[[
=====================================================================
Neovim configuration — single-file init.lua
=====================================================================

This file is a complete Neovim configuration contained in one file.
It is organized into numbered sections, each wrapped in a `do ... end`
block so that local variables stay scoped to the section that uses them.

Layout:
  Section 1  — Options:        core editor settings, leaders, autocmds
  Section 2  — Keymaps:        global key mappings and diagnostics
  Section 3  — Plugin manager:  vim.pack intro and build hooks
  Section 4  — UI / UX:         indent detection, git signs, which-key,
                                colorscheme, todo-comments, mini.nvim
  Section 5  — Search:          Telescope pickers and LSP navigation
  Section 6  — LSP:             language servers, Mason, on-attach maps
  Section 7  — Formatting:      conform.nvim and format-on-save
  Section 8  — Completion:      blink.cmp and LuaSnip
  Section 9  — Treesitter:      parsers, highlighting, folds, indent
  Section 10 — Examples:        optional add-ons and extension points

Plugins are managed with `vim.pack`, the plugin manager built into
Neovim. Reference docs:
  - :help lua-guide          (Lua in Neovim)
  - :help vim.pack           (plugin manager)
  - :checkhealth             (diagnose installation/runtime problems)
--]]

-- ============================================================
-- SECTION 1: OPTIONS
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  -- Cache compiled Lua modules to speed up startup.
  vim.loader.enable()

  -- Leader keys. Must be set before plugins load so mappings resolve
  -- against the intended leader.
  -- See `:help mapleader`
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true when a Nerd Font is installed and selected in the
  -- terminal; enables icon glyphs in plugins that support them.
  -- The installers install JetBrainsMono Nerd Font and WezTerm uses it.
  vim.g.have_nerd_font = true

  -- [[ Editor options ]]
  -- See `:help vim.o` and `:help option-list`

  -- Absolute line numbers in the gutter.
  vim.o.number = true
  -- Relative line numbers (commented out): aid vertical motions.
  -- vim.o.relativenumber = true

  -- Enable the mouse in all modes; useful for resizing splits.
  vim.o.mouse = 'a'

  -- Hide the mode indicator; the statusline already shows it.
  vim.o.showmode = false

  -- Use the system clipboard for all yank/paste operations.
  -- Scheduled after UiEnter to avoid slowing startup.
  -- Remove to keep the OS clipboard independent of Neovim.
  -- See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Wrapped lines preserve their indentation.
  vim.o.breakindent = true

  -- Persist undo history to disk so it survives closing a file.
  vim.o.undofile = true

  -- Case-insensitive search, unless the pattern contains an uppercase
  -- letter or `\C`.
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Always show the sign column to prevent the text from shifting.
  vim.o.signcolumn = 'yes'

  -- Time (ms) of inactivity before CursorHold fires / swap is written.
  vim.o.updatetime = 250

  -- Time (ms) to wait for a mapped key sequence to complete.
  vim.o.timeoutlen = 300

  -- Open vertical splits to the right and horizontal splits below.
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Render selected whitespace characters.
  -- `listchars` is set via `vim.opt` because it accepts a table.
  -- See `:help 'list'`, `:help 'listchars'`, `:help lua-options`
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Show a live preview of :substitute results in a split.
  vim.o.inccommand = 'split'

  -- Highlight the line the cursor is on.
  vim.o.cursorline = true

  -- Keep at least this many lines above and below the cursor.
  vim.o.scrolloff = 10

  -- Prompt to save instead of failing on commands (such as `:q`) that
  -- would abandon unsaved changes.
  -- See `:help 'confirm'`
  vim.o.confirm = true
end

-- ============================================================
-- SECTION 2: KEYMAPS
-- basic keymaps
-- ============================================================
do
  -- [[ Basic keymaps ]]
  -- See `:help vim.keymap.set()`

  -- <Esc> in normal mode clears search highlighting.
  -- See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostic display configuration.
  -- See `:help vim.diagnostic.Opts`
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    virtual_text = true, -- inline message at the end of the line
    virtual_lines = false, -- message on its own line below the code

    -- When jumping between diagnostics with `[d` / `]d`, open a
    -- non-focusing float so the message is visible at the destination.
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Exit terminal mode with a double <Esc>, easier to reach than the
  -- default <C-\><C-n>.
  -- Note: some terminal emulators or multiplexers may intercept this;
  -- the default sequence remains available.
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Optional: disable arrow keys in normal mode to build hjkl habits.
  -- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
  -- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
  -- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
  -- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

  -- Window navigation: CTRL+<hjkl> moves focus between splits.
  -- See `:help wincmd`
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Optional: move windows between positions. Some terminals cannot
  -- send these distinct keycodes.
  -- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
  -- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
  -- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
  -- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

  -- [[ Basic autocommands ]]
  -- See `:help lua-guide-autocommands`

  -- Briefly highlight text after it is yanked.
  -- See `:help vim.hl.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 3: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  -- [[ `vim.pack` ]]
  -- `vim.pack` is the plugin manager built into Neovim. It provides a
  -- Lua interface for installing and managing plugins.
  --
  -- See `:help vim.pack` and `:help vim.pack-examples`.
  -- Reference write-up:
  --   https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  -- Inspect plugin state and pending updates:
  --   :lua vim.pack.update(nil, { offline = true })
  -- Update all plugins:
  --   :lua vim.pack.update()
  --
  -- The remaining sections install and configure plugins with
  -- `vim.pack.add`. This section registers build hooks that run after
  -- certain plugins are installed or updated.

  -- Run a build command for a plugin and report a failure via notify.
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- Run the matching build step after a plugin is installed or updated.
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

--- Build a full GitHub URL from an `owner/repo` string. Most plugins are
--- hosted on GitHub, so this keeps the specs below short.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 4: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  -- [[ Installing and configuring plugins ]]
  --
  -- `vim.pack.add` installs a plugin from its git URL (defaulting to the
  -- repository's default branch). Most plugins also require a `.setup()`
  -- call to activate them.

  -- guess-indent.nvim: detect and set indentation automatically.
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- gitsigns.nvim: git change signs in the gutter plus hunk utilities.
  -- See `:help gitsigns` for the meaning of each option.
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  -- which-key.nvim: displays available keybindings as they are typed.
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay (ms) between a key press and the which-key popup.
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- Names for existing key-chain prefixes.
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  -- [[ Colorscheme ]]
  -- folke/tokyonight.nvim — Night style, to match WezTerm / Zellij / Starship.
  -- To switch themes, change the plugin below and the `colorscheme` command.
  -- Installed colorschemes can be browsed with `:Telescope colorscheme`.
  vim.pack.add { gh 'folke/tokyonight.nvim' }
  require('tokyonight').setup {
    style = 'night',
    styles = {
      comments = { italic = false }, -- non-italic comments
    },
  }

  -- Load the colorscheme. Variants include 'tokyonight-storm',
  -- 'tokyonight-moon', and 'tokyonight-day'.
  vim.cmd.colorscheme 'tokyonight-night'

  -- todo-comments.nvim: highlight TODO/NOTE/FIX style comment keywords.
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  -- A collection of small, independent modules; the ones used below are
  -- configured individually.
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- mini.icons: glyph icons for other plugins, loaded only when a Nerd
  -- Font is available.
  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    -- Shim for plugins that expect `nvim-web-devicons` (e.g. telescope).
    MiniIcons.mock_nvim_web_devicons()
  end

  -- mini.ai: extended around/inside text objects.
  -- Examples:
  --   va)  - visually select around parentheses
  --   yiiq - yank inside the next quote
  --   ci'  - change inside quotes
  require('mini.ai').setup {
    -- Remap next/last variants off `an`/`in` to avoid conflicting with
    -- the built-in treesitter incremental selection on Neovim >= 0.12.
    -- See `:help treesitter-incremental-selection`
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- mini.surround: add, delete, or replace surrounding pairs.
  --   saiw) - surround add inner word with parentheses
  --   sd'   - surround delete quotes
  --   sr)'  - surround replace ) with '
  require('mini.surround').setup()

  -- mini.statusline: a minimal statusline.
  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }

  -- Override the cursor-location section to show LINE:COLUMN.
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end

  -- Further modules and options: https://github.com/nvim-mini/mini.nvim
end

-- ============================================================
-- SECTION 5: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  -- [[ Fuzzy finder (files, LSP, and more) ]]
  --
  -- Telescope is a general-purpose fuzzy finder. Beyond files it can
  -- search help tags, the workspace, LSP results, and more.
  --
  -- Example invocation:
  --   :Telescope help_tags
  --
  -- Inside a Telescope picker, the key that lists the picker's own
  -- mappings is <c-/> in insert mode and ? in normal mode.

  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  -- The native fzf sorter is only useful when `make` is available to build it.
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  vim.pack.add(telescope_plugins)

  -- See `:help telescope` and `:help telescope.setup()`
  require('telescope').setup {
    -- Default mappings, pickers, and overrides go here.
    -- defaults = {
    --   mappings = {
    --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
    --   },
    -- },
    -- pickers = {}
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  -- Load extensions if installed.
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  -- Picker keymaps. See `:help telescope.builtin`.
  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- Register Telescope-based LSP navigation when a server attaches to a
  -- buffer. Switching picker plugins only requires editing this block.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      -- References to the symbol under the cursor.
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

      -- Implementation of the symbol under the cursor; useful for
      -- languages that separate declaration from implementation.
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

      -- Definition of the symbol under the cursor. Return with <C-t>.
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

      -- Symbols (variables, functions, types) in the current document.
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

      -- Symbols across the whole workspace.
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

      -- The *type* definition of the symbol under the cursor (rather than
      -- where the symbol itself was defined).
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  -- Fuzzy search within the current buffer, using a dropdown theme.
  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- Live grep restricted to the set of open files.
  -- See `:help telescope.builtin.live_grep()`
  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )

  -- Find files within the Neovim configuration directory.
  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })
end

-- ============================================================
-- SECTION 6: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- [[ LSP configuration ]]
  --
  -- LSP (Language Server Protocol) is a protocol that lets editors and
  -- language tooling communicate in a standardized way. A language
  -- server (such as `gopls`, `lua_ls`, or `rust_analyzer`) is a
  -- standalone process that the editor (the client) talks to.
  --
  -- LSP provides features including go-to-definition, find-references,
  -- autocompletion, and symbol search.
  --
  -- Language servers are installed separately from Neovim; `mason` and
  -- the related plugins below handle that.
  --
  -- For the distinction between LSP and treesitter, see
  -- `:help lsp-vs-treesitter`.

  -- fidget.nvim: shows LSP progress notifications.
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  -- Runs whenever a language server attaches to a buffer; this is where
  -- per-buffer LSP keymaps and behaviors are configured (e.g. opening
  -- `main.rs` attaches `rust_analyzer`).
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
    callback = function(event)
      -- Helper to define a buffer-local LSP mapping with a consistent
      -- description prefix.
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Rename the symbol under the cursor (across files when supported).
      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- Run a code action; the cursor usually needs to be on an error or
      -- a server suggestion.
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

      -- Goto declaration (not definition). In C, for example, this leads
      -- to the header.
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- When the server supports document highlighting, highlight other
      -- references to the symbol under the cursor while it rests there,
      -- and clear those highlights on cursor movement or detach.
      -- See `:help CursorHold`
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- When the server supports inlay hints, map a toggle for them.
      -- Inlay hints add inline annotations that displace some text.
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- Language servers and tools to enable. Entries are installed
  -- automatically by Mason below.
  -- See `:help lsp-config` for the available keys.
  ---@type table<string, vim.lsp.Config>
  local servers = {
    -- clangd = {},
    -- gopls = {},
    -- pyright = {},
    -- rust_analyzer = {},
    --
    -- Some languages have dedicated plugins, e.g. for TypeScript:
    --   https://github.com/pmizio/typescript-tools.nvim
    -- Otherwise the `ts_ls` server works for most setups.
    -- ts_ls = {},

    stylua = {}, -- Lua formatter

    -- lua_ls with settings recommended by the Neovim help docs.
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- formatting handled by stylua

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- Loading the full runtime as a library is slower and can
            -- cause issues when editing this configuration.
            -- See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- formatting handled by stylua
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- mason.nvim: installs language servers and tools under Neovim's data path.
  require('mason').setup {}

  -- Ensure the servers and tools listed above are installed. The Mason
  -- UI (`:Mason`) shows current status and allows manual installs;
  -- press `g?` there for help.
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    -- Additional tools for Mason to install can be listed here.
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  -- Register and enable each configured server.
  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 7: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  -- [[ Formatting ]]
  -- conform.nvim: runs configured formatters.
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    -- Format on save only for the filetypes enabled below.
    format_on_save = function(bufnr)
      local enabled_filetypes = {
        -- lua = true,
        -- python = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      -- Use an external formatter when configured, otherwise fall back
      -- to LSP formatting. Set to `false` to disable LSP formatting.
      lsp_format = 'fallback',
    },
    -- External formatters per filetype.
    formatters_by_ft = {
      -- rust = { 'rustfmt' },
      -- Formatters can be chained; they run in sequence.
      -- python = { "isort", "black" },
      -- `stop_after_first` runs the first available formatter only.
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet engine ]]
  -- LuaSnip. A version range can be specified for a plugin's git tag.
  -- See `:help vim.version.range()`
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- friendly-snippets provides a collection of premade snippets.
  -- See https://github.com/rafamadriz/friendly-snippets
  -- vim.pack.add { gh 'rafamadriz/friendly-snippets' }
  -- require('luasnip.loaders.from_vscode').lazy_load()

  -- [[ Completion engine ]]
  -- blink.cmp.
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      -- Keymap preset. Options: 'default' (built-in-like; <c-y> accepts),
      -- 'super-tab' (tab accepts), 'enter' (enter accepts), 'none'.
      --
      -- Mappings shared by all presets:
      --   <tab>/<s-tab>: move within a snippet expansion
      --   <c-space>:     open the menu, or open docs if already open
      --   <c-n>/<c-p> or <up>/<down>: select next/previous item
      --   <c-e>:         hide the menu
      --   <c-k>:         toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` and `:help ins-completion`.
      preset = 'default',

      -- Advanced LuaSnip keymaps (choice nodes, expansion):
      --   https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- Icon spacing variant: 'mono' for 'Nerd Font Mono', 'normal' for
      -- 'Nerd Font'.
      nerd_font_variant = 'mono',
    },

    completion = {
      -- Documentation popup. `auto_show = true` shows it automatically
      -- after `auto_show_delay_ms`; otherwise <c-space> reveals it.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Fuzzy matcher implementation. 'lua' uses the built-in matcher;
    -- 'prefer_rust_with_warning' downloads a prebuilt Rust binary.
    -- See `:help blink-cmp-config-fuzzy`
    fuzzy = { implementation = 'lua' },

    -- Show a signature-help window while typing function arguments.
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 9: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  -- [[ Treesitter ]]
  -- nvim-treesitter provides syntax highlighting, navigation, and
  -- indentation based on parsed syntax trees.
  -- See `:help nvim-treesitter-intro`
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Install a baseline set of parsers up front.
  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  require('nvim-treesitter').install(parsers)

  -- Attach treesitter features to a buffer for a given language.
  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Skip if the parser cannot be loaded.
    if not vim.treesitter.language.add(language) then return end
    -- Start highlighting and other treesitter features.
    vim.treesitter.start(buf, language)

    -- Treesitter-based folding (disabled by default).
    -- See `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Enable treesitter-based indentation when an indent query exists;
    -- otherwise the built-in indentexpr is used as a fallback.
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  -- On opening a file, attach the matching parser: enable it if already
  -- installed, auto-install it if available, or try to attach anyway.
  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 10: OPTIONAL EXAMPLES / NEXT STEPS
-- Extension points
-- ============================================================
do
  -- Extension points for additional configuration.
  --
  -- Modular plugin specs placed under `lua/custom/plugins/*.lua` can be
  -- loaded by uncommenting the require below.
  require 'custom.plugins'
end

-- The line below is a modeline. See `:help modeline`.
-- vim: ts=2 sts=2 sw=2 et
