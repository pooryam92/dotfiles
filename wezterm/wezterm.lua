-- WezTerm config — one file for Linux and Windows; the only fork is the shell
-- (`default_prog`). WezTerm is also the multiplexer (panes/tabs), so no Zellij/tmux.
-- Auto-reloads on save; ctrl+shift+r forces it.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find 'windows' ~= nil

-- ---- Font ----
config.font = wezterm.font 'JetBrainsMono Nerd Font' -- Nerd Font: renders Starship glyphs
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
-- WezTerm has no per-pane title bar, so two cues mark the focused pane instead:
-- dim the inactive ones, and colour the split line so boundaries read as borders.
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.65 }
config.colors = { split = '#7aa2f7' }

-- ---- Cursor & behavior ----
config.default_cursor_style = 'BlinkingBar'
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 100000

-- Force the shell, ignoring the login shell, so every machine gets the full setup.
config.default_prog = is_windows and { 'pwsh', '-NoLogo' } or { '/usr/bin/zsh' }

-- ---- Keybinds ----
-- One layer: direct chords, no leader, no modes. Almost everything is Alt+<key>,
-- because Alt is free whereas Ctrl+h (backspace) / Ctrl+l (clear) belong to the shell.
config.keys = {
  { key = 'r', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  -- Split: `\` ≈ vertical divider → pane right; `-` ≈ horizontal divider → pane below.
  { key = '\\', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-',  mods = 'ALT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

  { key = 'x', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },

  -- Move focus — hjkl and arrows.
  { key = 'h',          mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j',          mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k',          mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l',          mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

  -- Resize — move keys + Shift. Press repeatedly to nudge.
  { key = 'H', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'J', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'K', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'L', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 3 } },

  -- Rotate panes — WezTerm has no directional swap, so cycling is how you reorder.
  { key = '[', mods = 'ALT|SHIFT', action = act.RotatePanes 'CounterClockwise' },
  { key = ']', mods = 'ALT|SHIFT', action = act.RotatePanes 'Clockwise' },

  -- Tabs (Alt+1..9 added below).
  { key = 't', mods = 'ALT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'ALT', action = act.CloseCurrentTab { confirm = false } },
  { key = '[', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'ALT', action = act.ActivateTabRelative(1) },

  -- Copy mode (vim motions, `/` search, `y` yank). WezTerm grabs Ctrl+s before the
  -- shell, so it never triggers the terminal flow-control freeze.
  { key = 's', mods = 'CTRL', action = act.ActivateCopyMode },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i), mods = 'ALT', action = act.ActivateTab(i - 1),
  })
end

return config
