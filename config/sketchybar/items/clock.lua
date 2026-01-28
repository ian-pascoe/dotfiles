local icons = require("config.icons")
local colors = require("config.colors")
local settings = require("config.settings")

---@class items.clock
local M = {}

M.widget = Sbar.add("item", "calendar", {
  position = "right",
  width = 150,
  padding_right = 0,
  icon = {
    string = icons.clock,
    color = colors.primary.background,
    padding_left = 25,
    padding_right = 5,
  },
  label = {
    color = colors.primary.background,
    padding_left = 5,
    padding_right = 25,
    align = "right",
  },
  background = {
    color = colors.with_alpha(colors.primary.background, 0.15),
    height = settings.heights.bar,
  },
  click_script = "open -a Calendar",
  update_freq = 1,
})

M.widget:subscribe({ "routine", "forced" }, function()
  M.widget:set({
    label = { string = os.date("%r") },
  })
end)

return M
