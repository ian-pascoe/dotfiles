SketchyBar = require("sketchybar")

SketchyBar.begin_config()
require("bar")
require("default")
require("items")
SketchyBar.hotload(true)
SketchyBar.end_config()

SketchyBar.event_loop()
