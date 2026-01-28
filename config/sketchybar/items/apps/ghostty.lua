local config = require("config")
local settings = config.settings
local icons = config.icons

local Button = require("components.button")

---@class items.apps.ghostty
local M = {}

--- Keeps track of whether the mouse is still hovering over the button
local still_hovering = false

M.button = Button:new("apps.ghostty.button", "outline", {
  position = "left",
  padding_left = settings.paddings.xs,
  icon = { string = icons.map("Ghostty") },
  label = { drawing = false },
  popup = {
    drawing = false,
    align = "center",
  },
})

M.tooltip = Sbar.add("item", "apps.ghostty.tooltip", {
  position = "popup." .. M.button.name,
  icon = { drawing = false },
  label = {
    string = "Ghostty Terminal",
  },
})

M.button:on_hover(function(hovering)
  still_hovering = hovering
  if hovering then
    Sbar.delay(0.5, function()
      if still_hovering then
        M.button:set({
          popup = { drawing = true },
        })
      end
    end)
  else
    M.button:set({
      popup = { drawing = false },
    })
  end
end)

M.button:on_click(function()
  Sbar.exec("open -na Ghostty")
end)

return M
