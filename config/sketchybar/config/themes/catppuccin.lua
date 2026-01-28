------------------------------------
--- Catppuccin Mocha color palette
--- https://catppuccin.com/palette
--- rosewater #f5e0dc
--- flamingo  #f2cdcd
--- pink      #f5c2e7
--- mauve     #cba6f7
--- red       #f38ba8
--- maroon    #eba0ac
--- peach     #fab387
--- yellow    #f9e2af
--- green     #a6e3a1
--- teal      #94e2d5
--- sky       #89dceb
--- sapphire  #74c7ec
--- blue      #89b4fa
--- lavender  #b4befe
--- text      #cdd6f4
--- subtext1  #bac2de
--- subtext0  #a6adc8
--- overlay2  #9399b2
--- overlay1  #7f849c
--- overlay0  #6c7086
--- surface2  #585b70
--- surface1  #45475a
--- surface0  #313244
--- base      #1e1e2e
--- mantle    #181825
--- crust     #11111b
------------------------------------

---@class config.themes.catppuccin
local M = {
  rosewater = 0xfff5e0dc,
  flamingo = 0xfff2cdcd,
  pink = 0xfff5c2e7,
  mauve = 0xffcba6f7,
  red = 0xfff38ba8,
  maroon = 0xffeba0ac,
  peach = 0xfffab387,
  yellow = 0xfff9e2af,
  green = 0xffa6e3a1,
  teal = 0xff94e2d5,
  sky = 0xff89dceb,
  sapphire = 0xff74c7ec,
  blue = 0xff89b4fa,
  lavender = 0xffb4befe,
  text = 0xffcdd6f4,
  subtext1 = 0xffbac2de,
  subtext0 = 0xffa6adc8,
  overlay2 = 0xff9399b2,
  overlay1 = 0xff7f849c,
  overlay0 = 0xff6c7086,
  surface2 = 0xff585b70,
  surface1 = 0xff45475a,
  surface0 = 0xff313244,
  base = 0xff1e1e2e,
  mantle = 0xff181825,
  crust = 0xff11111b,
}

function M.toColors()
  ---@type config.colors
  return {
    background = M.base,
    foreground = M.text,
    card = { background = M.surface0, foreground = M.text },
    popup = { background = M.surface1, foreground = M.text },
    primary = { background = M.mauve, foreground = M.base },
    secondary = { background = M.blue, foreground = M.base },
    tertiary = { background = M.sapphire, foreground = M.base },
    accent = { background = M.lavender, foreground = M.base },
    muted = { background = M.overlay0, foreground = M.base },
    info = { background = M.sky, foreground = M.base },
    success = { background = M.green, foreground = M.base },
    warning = { background = M.yellow, foreground = M.base },
    destructive = { background = M.red, foreground = M.base },
    border = M.overlay1,
  }
end

return M
