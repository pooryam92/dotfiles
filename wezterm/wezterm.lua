-- WezTerm config — one file for Linux and Windows; the only fork is the shell
-- (`default_prog`). Also the multiplexer, so no Zellij/tmux. Auto-reloads on save.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find 'windows' ~= nil

-- ---- Font ----
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 11.0

-- ---- Theme ----
config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 1.0

-- ---- Window ----
config.window_padding = { left = 20, right = 20, top = 20, bottom = 20 }
config.window_close_confirmation = 'NeverPrompt'
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = 'TITLE | RESIZE'

-- ---- Tabs ----
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- ---- Panes ----
-- No per-pane title bar, so dim the inactive panes and colour the split line instead.
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.65 }
config.colors = { split = '#7aa2f7' }

-- ---- Cursor & behavior ----
config.default_cursor_style = 'BlinkingBar'
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 100000

-- Force the shell, ignoring the login shell.
config.default_prog = is_windows and { 'pwsh', '-NoLogo' } or { '/usr/bin/zsh' }

-- ---- Keybinds ----
-- One layer of direct chords, no leader. Alt carries almost everything: it is free,
-- whereas Ctrl+h (backspace) and Ctrl+l (clear) belong to the shell.
config.keys = {
  { key = 'r', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  { key = '\\', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-',  mods = 'ALT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },
  -- `Nop` swallows the slip: Alt+x does nothing rather than falling through to the shell.
  { key = 'x', mods = 'ALT', action = act.Nop },

  { key = 'h',          mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j',          mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k',          mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l',          mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

  { key = 'H', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'J', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'K', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'L', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 3 } },

  -- Rotate panes. Physical keycodes, not `[`/`]`: Alt+Shift+[ emits `{`, so a `[`+SHIFT
  -- binding never fires. `phys:` matches the key by position, independent of glyph/layout.
  { key = 'phys:LeftBracket',  mods = 'ALT|SHIFT', action = act.RotatePanes 'CounterClockwise' },
  { key = 'phys:RightBracket', mods = 'ALT|SHIFT', action = act.RotatePanes 'Clockwise' },

  -- Tabs (Alt+1..9 added below).
  { key = 't', mods = 'ALT', action = act.SpawnTab 'CurrentPaneDomain' },
  -- One close key: closes the pane, and the tab goes with its last pane.
  { key = 'w', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },
  { key = '[', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'ALT', action = act.ActivateTabRelative(1) },

  -- Copy mode. WezTerm grabs Ctrl+s before the shell, so no flow-control freeze.
  { key = 's', mods = 'CTRL', action = act.ActivateCopyMode },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'ALT', action = act.ActivateTab(i - 1),
  })
end

return config
