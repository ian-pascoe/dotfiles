local icons = require("config.icons")

local front_app = Sbar.add("item", "front_app", {
	position = "center",
	display = "active",
	icon = {
		padding_right = 2,
		font = {
			size = 16,
		},
	},
	label = {
		padding_left = 2,
	},
})

front_app:subscribe("front_app_switched", function(env)
	local app_name = env.INFO
	front_app:set({
		label = { string = app_name },
		icon = { string = icons.map(app_name) },
	})
end)
