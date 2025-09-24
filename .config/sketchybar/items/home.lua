local colors = require("config.colors")
local icons = require("config.icons")

local popup_width = 150

local home = Sbar.add("item", "home_icon", {
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
home:subscribe("mouse.entered", function()
	home:set({
		popup = { drawing = true },
		background = { color = colors.with_alpha(colors.primary.background, 0.25) },
	})
end)
home:subscribe({
	"mouse.exited",
	"mouse.exited.global",
}, function()
	home:set({
		popup = { drawing = false },
		background = { color = colors.with_alpha(colors.primary.background, 0.15) },
	})
end)

local home_prefs = Sbar.add("item", "home.prefs", {
	position = "popup." .. home.name,
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
})
home_prefs:subscribe("mouse.entered", function()
	home_prefs:set({
		background = { color = colors.with_alpha(colors.primary.background, 0.25) },
	})
end)
home_prefs:subscribe("mouse.exited", function()
	home_prefs:set({
		background = { color = colors.transparent },
	})
end)
home_prefs:subscribe("mouse.clicked", function(_)
	Sbar.exec("open -a 'System Preferences'")
	home:set({ popup = { drawing = false } })
end)

local lock = Sbar.add("item", "home.lock", {
	position = "popup." .. home.name,
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
})
lock:subscribe("mouse.entered", function()
	lock:set({
		background = { color = colors.with_alpha(colors.primary.background, 0.25) },
	})
end)
lock:subscribe("mouse.exited", function()
	lock:set({
		background = { color = colors.transparent },
	})
end)
lock:subscribe("mouse.clicked", function(_)
	Sbar.exec("pmset displaysleepnow")
	home:set({ popup = { drawing = false } })
end)

local signout = Sbar.add("item", "home.signout", {
	position = "popup." .. home.name,
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
})
signout:subscribe("mouse.entered", function()
	signout:set({
		background = { color = colors.with_alpha(colors.primary.background, 0.25) },
	})
end)
signout:subscribe("mouse.exited", function()
	signout:set({
		background = { color = colors.transparent },
	})
end)
signout:subscribe("mouse.clicked", function(_)
	Sbar.exec("osascript -e 'tell application \"System Events\" to log out'")
	home:set({ popup = { drawing = false } })
end)

local restart = Sbar.add("item", "home.restart", {
	position = "popup." .. home.name,
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
})
restart:subscribe("mouse.entered", function()
	restart:set({
		background = { color = colors.with_alpha(colors.primary.background, 0.25) },
	})
end)
restart:subscribe("mouse.exited", function()
	restart:set({
		background = { color = colors.transparent },
	})
end)
restart:subscribe("mouse.clicked", function(_)
	Sbar.exec("osascript -e 'tell application \"System Events\" to restart'")
	home:set({ popup = { drawing = false } })
end)

local shutdown = Sbar.add("item", "shutdown", {
	position = "popup." .. home.name,
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
})
shutdown:subscribe("mouse.entered", function()
	shutdown:set({
		background = { color = colors.with_alpha(colors.primary.background, 0.25) },
	})
end)
shutdown:subscribe("mouse.exited", function()
	shutdown:set({
		background = { color = colors.transparent },
	})
end)
shutdown:subscribe("mouse.clicked", function(_)
	Sbar.exec("osascript -e 'tell application \"System Events\" to shut down'")
	home:set({ popup = { drawing = false } })
end)
