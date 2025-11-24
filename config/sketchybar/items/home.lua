local colors = require("config.colors")
local icons = require("config.icons")

local popup_width = 150

---@class items.home
local M = {}

M.button = Sbar.add("item", "home.button", {
  padding_left = 0,
  icon = {
    string = icons.home,
    font = { size = 32.0 },
    color = colors.primary.background,
    padding_left = 35,
    padding_right = 35,
  },
  label = { drawing = false },
  background = {
    drawing = true,
    color = colors.with_alpha(colors.primary.background, 0.15),
    height = 40,
  },
  click_script = "sketchybar --set $NAME popup.drawing=toggle",
  popup = {},
})

M.button:subscribe("mouse.entered", function()
  M.button:set({
    background = { color = colors.with_alpha(colors.primary.background, 0.25) },
  })
end)
M.button:subscribe({
  "mouse.exited",
  "mouse.exited.global",
}, function()
  M.button:set({
    popup = { drawing = false },
    background = { color = colors.with_alpha(colors.primary.background, 0.15) },
  })
end)

---@type table<string, Sketchybar.Item | {popup: table<string, Sketchybar.Item>}>
M.popup = {}

M.popup.prefs = Sbar.add("item", "home.popup.prefs", {
  position = "popup." .. M.button.name,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icons.settings,
    padding_left = 10,
    width = popup_width / 2,
    align = "left",
  },
  label = {
    string = "Preferences",
    padding_right = 10,
    width = popup_width / 2,
    align = "right",
  },
  background = {
    color = colors.transparent,
  },
})
M.popup.prefs:subscribe("mouse.entered", function()
  M.popup.prefs:set({
    background = { color = colors.with_alpha(colors.primary.background, 0.25) },
  })
end)
M.popup.prefs:subscribe("mouse.exited", function()
  M.popup.prefs:set({
    background = { color = colors.transparent },
  })
end)
M.popup.prefs:subscribe("mouse.clicked", function(_)
  Sbar.exec("open -a 'System Preferences'")
  M.button:set({ popup = { drawing = false } })
end)

M.popup.theme = Sbar.add("item", "home.popup.theme", {
  position = "popup." .. M.button.name,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icons.theme,
    padding_left = 10,
    width = popup_width / 2,
    align = "left",
  },
  label = {
    string = "Theme",
    padding_right = 10,
    width = popup_width / 2,
    align = "right",
  },
  background = {
    color = colors.transparent,
  },
  popup = {
    align = "right",
  },
})
M.popup.theme:subscribe("mouse.entered", function()
  M.popup.theme:set({
    background = { color = colors.with_alpha(colors.primary.background, 0.25) },
    popup = { drawing = true },
  })
end)
M.popup.theme:subscribe("mouse.exited", function()
  M.popup.theme:set({
    background = { color = colors.transparent },
  })
end)
M.popup.theme:subscribe("mouse.exited.global", function()
  M.popup.theme:set({
    popup = { drawing = false },
  })
end)

M.popup.theme.popup = {}
Sbar.exec("ls -l $HOME/.themes/", function(result)
  local themes = {}
  for line in result:gmatch("[^\r\n]+") do
    -- Only process directory lines (start with 'd')
    if line:match("^d") then
      local theme_name = line:match("%S+$")
      if theme_name then
        table.insert(themes, theme_name)
      end
    end
  end

  for _, theme in ipairs(themes) do
    M.popup.theme.popup[theme] = Sbar.add("item", "home.popup.theme." .. theme, {
      position = "popup." .. M.popup.theme.name,
      padding_left = 0,
      padding_right = 0,
      label = {
        string = theme,
        padding_left = 10,
        padding_right = 10,
        width = popup_width,
        align = "left",
      },
      background = {
        color = colors.transparent,
      },
    })
    M.popup.theme.popup[theme]:subscribe("mouse.entered", function()
      M.popup.theme.popup[theme]:set({
        background = { color = colors.with_alpha(colors.primary.background, 0.25) },
      })
    end)
    M.popup.theme.popup[theme]:subscribe("mouse.exited", function()
      M.popup.theme.popup[theme]:set({
        background = { color = colors.transparent },
      })
    end)
    M.popup.theme.popup[theme]:subscribe("mouse.exited.global", function()
      M.popup.theme:set({
        popup = { drawing = false },
      })
    end)
    M.popup.theme.popup[theme]:subscribe("mouse.clicked", function(_)
      Sbar.exec("/usr/bin/env zsh -c 'set-theme " .. theme .. "'")
      M.popup.theme:set({ popup = { drawing = false } })
      M.button:set({ popup = { drawing = false } })
    end)
  end
end)

M.popup.lock = Sbar.add("item", "home.popup.lock", {
  position = "popup." .. M.button.name,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icons.lock,
    padding_left = 10,
    width = popup_width / 2,
    align = "left",
  },
  label = {
    string = "Lock",
    padding_right = 10,
    width = popup_width / 2,
    align = "right",
  },
  background = {
    color = colors.transparent,
  },
})
M.popup.lock:subscribe("mouse.entered", function()
  M.popup.lock:set({
    background = { color = colors.with_alpha(colors.primary.background, 0.25) },
  })
end)
M.popup.lock:subscribe("mouse.exited", function()
  M.popup.lock:set({
    background = { color = colors.transparent },
  })
end)
M.popup.lock:subscribe("mouse.clicked", function(_)
  Sbar.exec("pmset displaysleepnow")
  M.button:set({ popup = { drawing = false } })
end)

M.popup.signout = Sbar.add("item", "home.popup.signout", {
  position = "popup." .. M.button.name,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icons.signout,
    padding_left = 10,
    width = popup_width / 2,
    align = "left",
  },
  label = {
    string = "Sign Out",
    padding_right = 10,
    width = popup_width / 2,
    align = "right",
  },
  background = {
    color = colors.transparent,
  },
})
M.popup.signout:subscribe("mouse.entered", function()
  M.popup.signout:set({
    background = { color = colors.with_alpha(colors.primary.background, 0.25) },
  })
end)
M.popup.signout:subscribe("mouse.exited", function()
  M.popup.signout:set({
    background = { color = colors.transparent },
  })
end)
M.popup.signout:subscribe("mouse.clicked", function(_)
  Sbar.exec("osascript -e 'tell application \"System Events\" to log out'")
  M.button:set({ popup = { drawing = false } })
end)

M.popup.restart = Sbar.add("item", "home.popup.restart", {
  position = "popup." .. M.button.name,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icons.restart,
    padding_left = 10,
    width = popup_width / 2,
    align = "left",
  },
  label = {
    string = "Restart",
    padding_right = 10,
    width = popup_width / 2,
    align = "right",
  },
  background = {
    color = colors.transparent,
  },
})
M.popup.restart:subscribe("mouse.entered", function()
  M.popup.restart:set({
    background = { color = colors.with_alpha(colors.primary.background, 0.25) },
  })
end)
M.popup.restart:subscribe("mouse.exited", function()
  M.popup.restart:set({
    background = { color = colors.transparent },
  })
end)
M.popup.restart:subscribe("mouse.clicked", function(_)
  Sbar.exec("osascript -e 'tell application \"System Events\" to restart'")
  M.button:set({ popup = { drawing = false } })
end)

M.popup.shutdown = Sbar.add("item", "home.popup.shutdown", {
  position = "popup." .. M.button.name,
  padding_left = 0,
  padding_right = 0,
  icon = {
    string = icons.power,
    padding_left = 10,
    width = popup_width / 2,
    align = "left",
  },
  label = {
    string = "Shut Down",
    padding_right = 10,
    width = popup_width / 2,
    align = "right",
  },
  background = {
    color = colors.transparent,
  },
})
M.popup.shutdown:subscribe("mouse.entered", function()
  M.popup.shutdown:set({
    background = { color = colors.with_alpha(colors.primary.background, 0.25) },
  })
end)
M.popup.shutdown:subscribe("mouse.exited", function()
  M.popup.shutdown:set({
    background = { color = colors.transparent },
  })
end)
M.popup.shutdown:subscribe("mouse.clicked", function(_)
  Sbar.exec("osascript -e 'tell application \"System Events\" to shut down'")
  M.button:set({ popup = { drawing = false } })
end)

return M
