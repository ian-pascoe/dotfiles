local icons = require("config.icons")
local settings = require("config.settings")
local colors = require("config.colors")

---@class items.control_center.wifi
local M = {}

local popup_width = 200

M.button = Sbar.add("item", "wifi.button", {
  drawing = false,
  position = "right",
  width = 0,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icons.wifi,
    padding_left = 8,
    padding_right = 8,
  },
  label = {
    drawing = false,
    padding_left = 0,
    padding_right = 8,
  },
  popup = {
    align = "left",
  },
  click_script = "sketchybar --set $NAME popup.drawing=toggle",
  update_freq = 60,
})

---@type table<string, Sketchybar.Item>
M.popup = {}

M.popup.ssid = Sbar.add("item", "wifi.popup.ssid", {
  position = "popup." .. M.button.name,
  align = "center",
  width = popup_width,
  icon = {
    font = {
      style = "Bold",
    },
    string = icons.wifi_router,
  },
  label = {
    font = {
      style = "Bold",
    },
    max_chars = 18,
    string = "????????????",
  },
  background = {
    height = 2,
    color = colors.muted.background,
    y_offset = -15,
  },
})

M.popup.hostname = Sbar.add("item", "wifi.popup.hostname", {
  position = "popup." .. M.button.name,
  icon = {
    align = "left",
    string = "Hostname:",
    font = {
      family = settings.fonts.regular,
      style = "Bold",
      size = 12,
    },
    width = popup_width / 2,
  },
  label = {
    max_chars = 20,
    string = "????????????",
    width = popup_width / 2,
    align = "right",
  },
})

M.popup.ip = Sbar.add("item", "wifi.popup.ip", {
  position = "popup." .. M.button.name,
  icon = {
    align = "left",
    string = "IP:",
    font = {
      family = settings.fonts.regular,
      style = "Bold",
      size = 12,
    },
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
})

M.popup.mask = Sbar.add("item", "wifi.popup.mask", {
  position = "popup." .. M.button.name,
  icon = {
    align = "left",
    string = "Subnet mask:",
    font = {
      family = settings.fonts.regular,
      style = "Bold",
      size = 12,
    },
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
})

M.popup.router = Sbar.add("item", "wifi.popup.router", {
  position = "popup." .. M.button.name,
  icon = {
    align = "left",
    string = "Router:",
    font = {
      family = settings.fonts.regular,
      style = "Bold",
      size = 12,
    },
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
})

M.button:subscribe({ "wifi_change", "system_woke" }, function()
  Sbar.exec("ipconfig getifaddr en0", function(ip_address)
    local connected = (ip_address ~= "")
    M.button:set({
      icon = {
        string = connected and icons.wifi or icons.wifi_off,
      },
    })
  end)
end)

M.button:subscribe({
  "mouse.exited",
  "mouse.exited.global",
}, function(_)
  M.button:set({
    popup = { drawing = false },
    background = { color = colors.transparent },
  })
end)

M.button:subscribe({
  "mouse.entered",
}, function(_)
  Sbar.exec("networksetup -getcomputername", function(result)
    M.popup.hostname:set({ label = result })
  end)
  Sbar.exec("ipconfig getifaddr en0", function(result)
    M.popup.ip:set({ label = result })
  end)
  Sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
    M.popup.ssid:set({ label = result })
  end)
  Sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
    M.popup.mask:set({ label = result })
  end)
  Sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
    M.popup.router:set({ label = result })
  end)
  M.button:set({
    popup = { drawing = true },
    background = { color = colors.with_alpha(colors.secondary.background, 0.25) },
  })
end)

local function copy_label_to_clipboard(env)
  local label = Sbar.query(env.NAME).label.value
  Sbar.exec('echo "' .. label .. '" | pbcopy')
  Sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
  Sbar.delay(1, function()
    Sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

M.popup.ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
M.popup.hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
M.popup.ip:subscribe("mouse.clicked", copy_label_to_clipboard)
M.popup.mask:subscribe("mouse.clicked", copy_label_to_clipboard)
M.popup.router:subscribe("mouse.clicked", copy_label_to_clipboard)

return M
