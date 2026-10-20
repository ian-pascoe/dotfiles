-- WezTerm Config
-- Mirrors dot_config/ghostty/config: keep the two in step. Settings Ghostty
-- leaves at its defaults are set here where WezTerm's defaults differ.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- dynamic theme
-- Colors come from the current theme variant's ghostty.conf, the one file
-- every variant has with a full terminal palette (as theme-palette reads it),
-- so no variant needs a WezTerm file. set-theme repoints ~/.config/theme;
-- watching its parent directory reloads on that swap, and watching the file
-- reloads when the variant itself changes.
local config_home = os.getenv("XDG_CONFIG_HOME") or (wezterm.home_dir .. "/.config")
local theme_file = config_home .. "/theme/ghostty.conf"

-- Reads a Ghostty theme file into WezTerm colors, or nil when it is missing.
local function ghostty_colors(path)
  local file = io.open(path)
  if not file then
    return nil
  end

  local values, palette = {}, {}
  for line in file:lines() do
    local key, value = line:match("^%s*([%w-]+)%s*=%s*(%S+)")
    if key == "palette" then
      local index, hex = value:match("^(%d+)=(#?%x+)$")
      if index then
        palette[tonumber(index)] = hex
      end
    elseif key then
      values[key] = value
    end
  end
  file:close()

  local background, foreground = values["background"], values["foreground"]
  if not (background and foreground) then
    return nil
  end

  local ansi, brights = {}, {}
  for i = 0, 7 do
    ansi[i + 1] = palette[i]
    brights[i + 1] = palette[i + 8]
  end
  local muted = palette[8] or foreground
  local inactive_tab = { bg_color = background, fg_color = muted }

  return {
    background = background,
    foreground = foreground,
    cursor_bg = values["cursor-color"] or foreground,
    cursor_border = values["cursor-color"] or foreground,
    cursor_fg = values["cursor-text"] or background,
    selection_bg = values["selection-background"],
    selection_fg = values["selection-foreground"],
    ansi = #ansi == 8 and ansi or nil,
    brights = #brights == 8 and brights or nil,
    split = muted,
    tab_bar = {
      background = background,
      active_tab = { bg_color = values["selection-background"] or muted, fg_color = foreground },
      inactive_tab = inactive_tab,
      inactive_tab_hover = { bg_color = background, fg_color = foreground },
      new_tab = inactive_tab,
      new_tab_hover = { bg_color = background, fg_color = foreground },
    },
  }
end

config.colors = ghostty_colors(theme_file)
wezterm.add_to_config_reload_watch_list(config_home)
wezterm.add_to_config_reload_watch_list(theme_file)

-- window
config.window_decorations = "RESIZE" -- macos-titlebar-style = hidden
config.window_padding = { left = "10pt", right = "10pt", top = "10pt", bottom = "10pt" }
config.window_close_confirmation = "NeverPrompt"
config.quit_when_all_windows_are_closed = true
-- Ghostty shows no tabs with its titlebar hidden; show them only when there are several.
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- background
config.window_background_opacity = 0.95

-- font
config.font = wezterm.font("GeistMono Nerd Font", { weight = "Regular" })
config.font_size = 12

-- cursor
-- Ghostty blinks hard, without fading.
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 600
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- Ghostty defaults
config.audible_bell = "Disabled" -- bell-features = no-system,no-audio
config.hide_mouse_cursor_when_typing = false -- mouse-hide-while-typing = false
config.scrollback_lines = 10000 -- near scrollback-limit = 10000000 bytes
-- macos-option-as-alt is true on US layouts: both Option keys send Alt.
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- keybindings
config.keys = {
  { key = "Insert", mods = "CTRL", action = wezterm.action.CopyTo("Clipboard") },
  { key = "Insert", mods = "SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
}

return config
