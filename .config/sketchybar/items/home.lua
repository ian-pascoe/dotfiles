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
		popup = { drawing = true },
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

---@type table<string, Sketchybar.Item>
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
