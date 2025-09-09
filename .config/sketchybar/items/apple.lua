local config = require("config")

local apple_logo = Sbar.add("item", "apple_icon", {
	padding_right = 15,
	icon = {
		string = config.icons.apple,
		color = config.colors.primary.background,
	},
	label = {
		drawing = false,
	},
	popup = {
		height = 35,
	},
})

apple_logo:subscribe("change_mode", function(env)
	local icon = config.icons.apple
	if env.MODE == "service" then
		icon = config.icons.service
	elseif env.MODE == "resize" then
		icon = config.icons.resize
	end

	apple_logo:set({
		icon = {
			string = icon,
		},
	})
end)

apple_logo:subscribe("mouse.clicked", function(_)
	apple_logo:set({ popup = { drawing = "toggle" } })
end)

local apple_prefs = Sbar.add("item", "apple_icon_popup", {
	position = "popup." .. apple_logo.name,
	padding_left = 10,
	padding_right = 10,
	icon = config.icons.settings,
	label = "Preferences",
})

apple_prefs:subscribe("mouse.clicked", function(_)
	Sbar.exec("open -a 'System Preferences'")
	apple_logo:set({ popup = { drawing = false } })
end)

local signout = Sbar.add("item", "signout", {
	position = "popup." .. apple_logo.name,
	padding_left = 10,
	padding_right = 10,
	icon = config.icons.signout,
	label = "Sign Out",
})
signout:subscribe("mouse.clicked", function(_)
	Sbar.exec("osascript -e 'tell application \"System Events\" to log out'")
	apple_logo:set({ popup = { drawing = false } })
end)

local shutdown = Sbar.add("item", "shutdown", {
	position = "popup." .. apple_logo.name,
	padding_left = 10,
	padding_right = 10,
	icon = config.icons.power,
	label = "Shut Down",
})
shutdown:subscribe("mouse.clicked", function(_)
	Sbar.exec("osascript -e 'tell application \"System Events\" to shut down'")
	apple_logo:set({ popup = { drawing = false } })
end)
