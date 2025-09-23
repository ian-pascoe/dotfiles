Util = require("util")

---@class Sketchybar.AddOptions

---@class Sketchybar.Item

---@class Sketchybar
---@field begin_config fun()
---@field end_config fun()
---@field hotload fun(enable: boolean)
---@field event_loop fun()
---@field add fun(type: "item" | "space", name: string, options: Sketchybar.AddOptions): Sketchybar.Item
Sbar = require("sketchybar")

Sbar.begin_config()
require("bar")
require("default")
require("items")
Sbar.hotload(true)
Sbar.end_config()

Sbar.event_loop()
