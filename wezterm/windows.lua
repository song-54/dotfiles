package.path = package.path .. ';' .. os.getenv("USERPROFILE") .. '/.config/dotfiles/wezterm/?.lua'
local config = require 'wezconf'
local wezterm = require 'wezterm'

config.default_prog = { 'wsl.exe', '~'} -- -d dist
config.launch_menu = {
  {
    label = 'WSL Ubuntu',
    args = config.default_prog
  },
  {
    label = 'PowerShell Core',
    args = { 'powershell.exe' },
  },
  {
    label = 'Command Prompt',
    args = { 'cmd.exe' },
  },
}

--local keys = {}
--config.keys = merge(config.keys, keys))

return config
