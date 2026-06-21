-- Custom plugins, loaded from init.lua via `require 'custom.plugins'`.
-- Add more files under lua/custom/plugins/ and require them here, or put
-- everything in this file. Uses Neovim's built-in `vim.pack` (0.12+).

-- render-markdown.nvim — pretty in-buffer rendering of Markdown.
-- Renders headings, code blocks, lists, tables, checkboxes, callouts, etc.
-- directly in the buffer (no browser), and degrades to plain text while editing
-- the line your cursor is on. Uses the markdown / markdown_inline treesitter
-- parsers (already installed by kickstart) and mini.icons (from mini.nvim).
vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }
require('render-markdown').setup {
  file_types = { 'markdown' },
}

-- Toggle rendering on/off (handy when you want raw markdown).
vim.keymap.set('n', '<leader>tm', '<cmd>RenderMarkdown toggle<CR>', { desc = '[T]oggle [M]arkdown render' })
