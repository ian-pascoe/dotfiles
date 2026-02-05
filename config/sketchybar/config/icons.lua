---@class config.icons
local M = {
  apple = "",
  home = "󰥓",
  settings = "󰒓",
  theme = "",
  signout = "󰍃",
  lock = "󰌾",
  restart = "󰜉",
  power = "󰐥",
  service = "󰢍",
  resize = "󰩨",
  clock = "",
  wifi = "󰖩",
  wifi_router = "󰑩",
  wifi_off = "󱚼",
  clipboard = "󰅇",
  cpu = "",
  memory = "",
  disk = "",
  ellipsis = "",
  bluetooth = {
    on = "󰂯",
    off = "󰂲",
  },
  control_center = "",
  monitoring = "",

  volume = {
    _100 = "",
    _66 = "",
    _33 = "",
    _10 = "",
    _0 = "󰸈",
  },
  microphone = {
    _100 = "󰍬",
    _66 = "󰍬",
    _33 = "󰍬",
    _10 = "󰍬",
    _0 = "󰍭",
  },
  battery = {
    non_charging = {
      _100 = "󰁹",
      _90 = "󰂂",
      _80 = "󰂁",
      _70 = "󰂀",
      _60 = "󰁿",
      _50 = "󰁾",
      _40 = "󰁽",
      _30 = "󰁼",
      _20 = "󰁻",
      _10 = "󰁺",
      _0 = "󰂃",
    },
    charging = {
      _100 = "󰂅",
      _90 = "󰂋",
      _80 = "󰂊",
      _70 = "󰢞",
      _60 = "󰂉",
      _50 = "󰢝",
      _40 = "󰂈",
      _30 = "󰂇",
      _20 = "󰂆",
      _10 = "󰢜",
      _0 = "󰢟",
    },
  },
  media = {
    music = "󰝚",
    play = "",
    pause = "",
    back = "",
    forward = "",
    play_pause = "󰐎",
  },
}

M.app_icons = {
  ["Font Book"] = "",
  ["Google Chrome"] = "",
  ["Chromium"] = "",
  ["Ghostty"] = "󰊠",
  ["Messages"] = "󰍥",
  ["System Settings"] = "󰒓",
  ["Activity Monitor"] = "󰍛",
  ["Notes"] = "",
  ["FaceTime"] = "",
  ["Disk Utility"] = "",
  ["Finder"] = "",
  ["Spotify"] = "",
  ["Music"] = "󰝚",
  ["Reminders"] = "",
  ["App Store"] = "",
  ["Pearcleaner"] = "󱨎",
  ["Weather"] = "",
  ["Helium"] = "",
  ["Passwords"] = "",
  ["WireGuard"] = "󰖂",
  ["Mail"] = "",
  ["Obsidian"] = "",
  ["Contacts"] = "󰖸",
  ["Calendar"] = "󰃭",
  ["Figma"] = "",
  ["zoom.us"] = "",
  ["Safari"] = "",
  ["Discord"] = "",
}

function M.map(app_name)
  if M.app_icons[app_name] then
    return M.app_icons[app_name]
  else
    return ""
  end
end

return M
