------------------------------------
--- Rose Pine Color Palette
--- https://rosepinetheme.com/palette/ingredients/
--- Base            #191724
--- Surface         #1f1d2e
--- Overlay         #26233a
--- Muted           #6e6a86
--- Subtle          #908caa
--- Text            #e0def4
--- Love            #eb6f92
--- Gold            #f6c177
--- Rose            #ebbcba
--- Pine            #31748f
--- Foam            #9ccfd8
--- Iris            #c4a7e7
--- Highlight Low   #21202e
--- Highlight Med   #403d52
--- Highlight High  #524f67
-------------------------------------

---@class config.themes.rose_pine
local M = {
  base = 0xff191724,
  surface = 0xff1f1d2e,
  overlay = 0xff26233a,
  muted = 0xff6e6a86,
  subtle = 0xff908caa,
  text = 0xffe0def4,
  love = 0xffeb6f92,
  gold = 0xfff6c177,
  rose = 0xffebbcba,
  pine = 0xff31748f,
  foam = 0xff9ccfd8,
  iris = 0xffc4a7e7,
  highlight_low = 0xff21202e,
  highlight_med = 0xff403d52,
  highlight_high = 0xff524f67,
}

function M.toColors()
  ---@type config.colors
  return {
    background = M.base,
    foreground = M.text,
    card = { background = M.surface, foreground = M.text },
    popup = { background = M.overlay, foreground = M.text },
    primary = { background = M.rose, foreground = M.overlay },
    secondary = { background = M.foam, foreground = M.overlay },
    tertiary = { background = M.pine, foreground = M.text },
    accent = { background = M.iris, foreground = M.overlay },
    muted = { background = M.muted, foreground = M.base },
    info = { background = M.foam, foreground = M.base },
    success = { background = M.pine, foreground = M.base },
    warning = { background = M.gold, foreground = M.base },
    destructive = { background = M.love, foreground = M.base },
    border = M.highlight_med,
  }
end

return M
