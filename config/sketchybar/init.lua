-- Globals
Util = require("util")

-- Load sketchybar types
require("util.sketchybar")

-- Setup theme and colors
require("config.colors").setup()

-- Global Sketchybar instance
---@type Sketchybar
Sbar = require("sketchybar")

Sbar.begin_config()
require("bar")
require("default")
require("items")
Sbar.hotload(true)
Sbar.end_config()

Sbar.event_loop()
