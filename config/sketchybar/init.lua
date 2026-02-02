-- This is only needed once to install the sketchybar module
-- (or for an update of the module)
os.execute("[ ! -d $HOME/.local/share/sketchybar_lua/ ] && (git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)")

-- Add the sketchybar module to the package cpath (the module could be
-- installed into the default search path then this would not be needed)
package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"

-- Globals
Util = require("util")

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
