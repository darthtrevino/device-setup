local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font('Hack Nerd Font Mono')
config.font_size = 10.0

config.window_frame = {
  font_size = 10.0,
}

config.window_padding = {
  left = 4,
  right = 4,
  top = 4,
  bottom = 4,
}

-- Attach to the live GUI mux on the office machine (ghostwind).
-- Auto-detects the newest gui-sock-<pid> so it survives GUI restarts.
config.unix_domains = {
  {
    name = 'ghostwind',
    proxy_command = {
      'ssh', '-T', 'dax@ghostwind',
      'ss=$(ls -t /run/user/1000/wezterm/gui-sock-* 2>/dev/null | head -1); exec env WEZTERM_UNIX_SOCKET="$ss" wezterm cli proxy',
    },
  },
}

config.leader = { key = ';', mods = 'CTRL', timeout_milliseconds = 2000 }

local act = wezterm.action
config.keys = {
  -- Splits
  { key = 'v', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Pane navigation (jkli = left/down/up/right)
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'i', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Tabs
  { key = 't', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },

  -- Rename tab
  { key = 'r', mods = 'LEADER', action = act.PromptInputLine {
    description = 'Enter new tab name:',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  } },

  -- Close pane
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

  -- Attach to the office (ghostwind) mux session
  { key = 'g', mods = 'LEADER', action = act.AttachDomain 'ghostwind' },
}

return config
