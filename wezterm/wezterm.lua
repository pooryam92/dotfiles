-- WezTerm configuration — shared across Linux and Windows.
-- Docs: https://wezfurlong.org/wezterm/config/files.html
-- WezTerm auto-reloads this file on save; ctrl+shift+r forces a reload.
--
-- WezTerm is both the terminal AND the multiplexer here (panes/tabs/splits) —
-- there is no separate Zellij layer. The only thing that differs between
-- platforms is the shell launched (`default_prog`), branched on `is_windows`
-- below — everything else (theme, font, keybinds…) is identical everywhere.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find 'windows' ~= nil

-- ---- Font (Nerd Font for Starship glyphs) ----
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

-- ---- Tabs (now WezTerm's own — no external multiplexer) ----
-- Show the tab bar only when there's more than one tab, so a single-tab window
-- reclaims that row. The retro/compact bar is lighter than the fancy one.
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- ---- Panes ----
-- Two cues make the focused pane obvious — the closest WezTerm gets to Zellij's
-- framed panes (it has no native per-pane title bar, see issue #297):
--   1. Dim inactive panes. Lower brightness = stronger contrast.
--   2. Colour the split line so pane boundaries read as visible borders.
-- `colors` overlays just the `split` key on top of the Tokyo Night color_scheme.
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.65 }
config.colors = { split = '#7aa2f7' } -- Tokyo Night blue

-- ---- Cursor ----
config.default_cursor_style = 'BlinkingBar' -- == Ghostty cursor-style = bar + blink
config.hide_mouse_cursor_when_typing = true

-- ---- Behavior ----
config.scrollback_lines = 100000
-- WezTerm copies the selection to the clipboard on mouse-up by default, which
-- matches Ghostty's copy-on-select = clipboard. No extra config needed.

-- Force the shell regardless of the login shell. On Windows this is pwsh 7;
-- on Linux it is zsh (mirrors Ghostty's `command = /usr/bin/zsh` pin).
config.default_prog = is_windows and { 'pwsh', '-NoLogo' } or { '/usr/bin/zsh' }

-- ---- Keybinds ----
-- Two layers, side by side:
--   1. DIRECT chords (Alt+…)  — the fast path for the things you do constantly.
--   2. Zellij-style MODES      — Ctrl+p/t/n/s enter a "mode" (a WezTerm key table)
--      exactly like Zellij's Ctrl+p pane / Ctrl+t tab / Ctrl+n resize / Ctrl+s
--      scroll. Discoverable: the active mode shows in the tab bar, and you press a
--      letter then Esc. Use whichever you prefer — they drive the same actions.
-- There is no `Ctrl+a` leader anymore; the modes replace it.
config.keys = {
  -- Reload + font size (direct Ctrl chords) ---------------------------------
  { key = 'r', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  -- DIRECT splits — no prefix, no Shift. `\` ≈ vertical divider → pane to the
  -- RIGHT; `-` ≈ horizontal divider → pane BELOW. Inherits the current cwd.
  { key = '\\', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-',  mods = 'ALT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- ALT+x — close the focused pane. `x` matches the close key in Ctrl+p mode.
  -- No confirm prompt, to keep it a fast chord (window_close_confirmation is off too).
  { key = 'x', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },

  -- ALT+g — build a 3-pane layout in one keystroke: one tall pane on the LEFT,
  -- two stacked on the RIGHT (pane 1 | pane 2 / pane 3). Splits right, then splits
  -- that right pane down, then returns focus to the big left pane.
  { key = 'g', mods = 'ALT', action = wezterm.action_callback(function(_, pane)
      local right = pane:split { direction = 'Right',  size = 0.5 }
      right:split        { direction = 'Bottom', size = 0.5 }
      pane:activate()
  end) },

  -- DIRECT focus move — vim `hjkl` AND arrows. ALT (not CTRL) so Ctrl+h
  -- backspace / Ctrl+l clear-screen stay intact.
  { key = 'h',          mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j',          mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k',          mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l',          mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

  -- Zellij-style MODE entries (mirror Zellij's Ctrl-key modes). Each activates a
  -- key table that stays up (one_shot=false) until Esc; the tab bar shows which.
  { key = 'p', mods = 'CTRL', action = act.ActivateKeyTable { name = 'pane',   one_shot = false } },
  { key = 't', mods = 'CTRL', action = act.ActivateKeyTable { name = 'tab',    one_shot = false } },
  { key = 'n', mods = 'CTRL', action = act.ActivateKeyTable { name = 'resize', one_shot = false } },
  -- Ctrl+s = scroll/search: WezTerm's copy mode (vim motions, `/` to search,
  -- `y` to yank, Esc to leave) is the direct analogue of Zellij's scroll mode.
  { key = 's', mods = 'CTRL', action = act.ActivateCopyMode },
}

-- ---- Key tables = Zellij modes ----
-- Inside a mode: actions that *create* something (split / new tab / close) pop
-- the mode so you can start typing immediately; *movement* stays so you can keep
-- going. Esc/Enter always exits. This is Zellij's modal feel, minus the footgun
-- of staying in "pane mode" after you split.
local function split_and_exit(action)
  return act.Multiple { action, act.PopKeyTable }
end

config.key_tables = {
  -- Ctrl+p — PANE mode (Zellij: Ctrl+p)
  pane = {
    { key = 'n', action = split_and_exit(act.SplitHorizontal { domain = 'CurrentPaneDomain' }) }, -- new pane (right)
    { key = 'd', action = split_and_exit(act.SplitVertical   { domain = 'CurrentPaneDomain' }) }, -- split down
    { key = 'x', action = split_and_exit(act.CloseCurrentPane { confirm = false }) },             -- close
    { key = 'f', action = split_and_exit(act.TogglePaneZoomState) },                              -- fullscreen/zoom
    { key = 'h', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', action = act.ActivatePaneDirection 'Right' },
    { key = 'LeftArrow',  action = act.ActivatePaneDirection 'Left' },
    { key = 'DownArrow',  action = act.ActivatePaneDirection 'Down' },
    { key = 'UpArrow',    action = act.ActivatePaneDirection 'Up' },
    { key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter',  action = 'PopKeyTable' },
  },

  -- Ctrl+t — TAB mode (Zellij: Ctrl+t). 1..9 added in the loop below.
  tab = {
    { key = 'n', action = split_and_exit(act.SpawnTab 'CurrentPaneDomain') },        -- new
    { key = 'x', action = split_and_exit(act.CloseCurrentTab { confirm = false }) }, -- close
    { key = 'h', action = act.ActivateTabRelative(-1) },
    { key = 'l', action = act.ActivateTabRelative(1) },
    { key = 'LeftArrow',  action = act.ActivateTabRelative(-1) },
    { key = 'RightArrow', action = act.ActivateTabRelative(1) },
    { key = 'r', action = act.Multiple { act.PopKeyTable, act.PromptInputLine {
        description = 'Rename tab:',
        action = wezterm.action_callback(function(window, _, line)
          if line and #line > 0 then window:active_tab():set_title(line) end
        end),
    } } },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter',  action = 'PopKeyTable' },
  },

  -- Ctrl+n — RESIZE mode (Zellij: Ctrl+n). Stays up so you can nudge repeatedly.
  resize = {
    { key = 'h',          action = act.AdjustPaneSize { 'Left', 3 } },
    { key = 'j',          action = act.AdjustPaneSize { 'Down', 3 } },
    { key = 'k',          action = act.AdjustPaneSize { 'Up', 3 } },
    { key = 'l',          action = act.AdjustPaneSize { 'Right', 3 } },
    { key = 'LeftArrow',  action = act.AdjustPaneSize { 'Left', 3 } },
    { key = 'DownArrow',  action = act.AdjustPaneSize { 'Down', 3 } },
    { key = 'UpArrow',    action = act.AdjustPaneSize { 'Up', 3 } },
    { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 3 } },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'q',      action = 'PopKeyTable' },
    { key = 'Enter',  action = 'PopKeyTable' },
  },
}

-- TAB mode: 1..9 jump straight to that tab, then exit the mode.
for i = 1, 9 do
  table.insert(config.key_tables.tab, {
    key = tostring(i), action = split_and_exit(act.ActivateTab(i - 1)),
  })
end

-- Show the active mode in the tab bar with its key hints — Zellij's mode line.
-- copy_mode/search_mode aren't in config.key_tables above: they're WezTerm's
-- built-in key tables (entered via Ctrl+s / search), so these two hints just
-- describe their inherited default keys.
local mode_hints = {
  pane   = ' PANE  n new·d down·x close·f full·hjkl move·Esc ',
  tab    = ' TAB  n new·1-9 go·h/l move·r rename·x close·Esc ',
  resize = ' RESIZE  hjkl/arrows·q/Esc ',
  copy_mode    = ' SCROLL/COPY  vim keys·/ search·y yank·Esc ',
  search_mode  = ' SEARCH  type·Enter·Esc ',
}
wezterm.on('update-right-status', function(window, _)
  local name = window:active_key_table()
  window:set_right_status(name and (mode_hints[name] or (' ' .. name .. ' ')) or '')
  -- The hint lives in the tab bar, but `hide_tab_bar_if_only_one_tab` hides that
  -- bar in the common single-tab case — which would swallow the hint exactly when
  -- you need it. So force the bar visible while a mode is active, and reclaim the
  -- row again when it isn't. (Overrides only re-apply when the value changes, so
  -- this doesn't thrash.)
  window:set_config_overrides { hide_tab_bar_if_only_one_tab = (name == nil) }
end)

return config
