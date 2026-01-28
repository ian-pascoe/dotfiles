local config = require("config")
local icons = config.icons
local colors = config.colors

---@class util.battery
local M = {}

M.thresholds = {
  {
    percent = 100,
    charging_icon = icons.battery.charging._100,
    non_charging_icon = icons.battery.non_charging._100,
    color = colors.success.background,
  },
  {
    percent = 90,
    charging_icon = icons.battery.charging._90,
    non_charging_icon = icons.battery.non_charging._90,
    color = colors.success.background,
  },
  {
    percent = 80,
    charging_icon = icons.battery.charging._80,
    non_charging_icon = icons.battery.non_charging._80,
    color = colors.success.background,
  },
  {
    percent = 70,
    charging_icon = icons.battery.charging._70,
    non_charging_icon = icons.battery.non_charging._70,
    color = colors.success.background,
  },
  {
    percent = 60,
    charging_icon = icons.battery.charging._60,
    non_charging_icon = icons.battery.non_charging._60,
    color = colors.info.background,
  },
  {
    percent = 50,
    charging_icon = icons.battery.charging._50,
    non_charging_icon = icons.battery.non_charging._50,
    color = colors.info.background,
  },
  {
    percent = 40,
    charging_icon = icons.battery.charging._40,
    non_charging_icon = icons.battery.non_charging._40,
    color = colors.warning.background,
  },
  {
    percent = 30,
    charging_icon = icons.battery.charging._30,
    non_charging_icon = icons.battery.non_charging._30,
    color = colors.warning.background,
  },
  {
    percent = 20,
    charging_icon = icons.battery.charging._20,
    non_charging_icon = icons.battery.non_charging._20,
    color = colors.destructive.background,
  },
  {
    percent = 10,
    charging_icon = icons.battery.charging._10,
    non_charging_icon = icons.battery.non_charging._10,
    color = colors.destructive.background,
  },
  {
    percent = 0,
    charging_icon = icons.battery.charging._0,
    non_charging_icon = icons.battery.non_charging._0,
    color = colors.destructive.background,
  },
}

return M
