-- WezTerm configuration — shared across Linux and Windows.
-- Docs: https://wezfurlong.org/wezterm/config/files.html
-- WezTerm auto-reloads this file on save; ctrl+shift+r forces a reload.
--
-- This replaces the old Ghostty config. The only thing that differs between
-- platforms is the shell launched (`default_prog`), branched on `is_windows`
-- below — everything else (theme, font, padding…) is identical everywhere.

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find 'windows' ~= nil

-- ---- Font (Nerd Font for Starship / Zellij glyphs) ----
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0

-- ---- Theme (Tokyo Night ships built-in with WezTerm) ----
config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 1.0

-- ---- Window ----
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.window_close_confirmation = 'NeverPrompt' -- == Ghostty confirm-close-surface = false
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = 'TITLE | RESIZE'

-- Zellij manages tabs/panes, so WezTerm's own tab bar is redundant. Hide it
-- when only one WezTerm tab is open (the normal case), reclaiming that row.
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true

-- ---- Cursor ----
config.default_cursor_style = 'BlinkingBar' -- == Ghostty cursor-style = bar + blink
config.hide_mouse_cursor_when_typing = true

-- ---- Behavior ----
config.scrollback_lines = 100000
-- WezTerm copies the selection to the clipboard on mouse-up by default,
-- which matches Ghostty's copy-on-select = clipboard. Zellij handles its own
-- copy via OSC52 when running inside.

-- Force the shell regardless of the login shell. On Windows this is pwsh 7;
-- on Linux it is zsh (mirrors Ghostty's `command = /usr/bin/zsh` pin).
config.default_prog = is_windows and { 'pwsh', '-NoLogo' } or { '/usr/bin/zsh' }

-- ---- Keybinds (parity with the old Ghostty binds) ----
config.keys = {
  { key = 'r', mods = 'CTRL|SHIFT', action = wezterm.action.ReloadConfiguration },
  { key = '=', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },
}

return config
