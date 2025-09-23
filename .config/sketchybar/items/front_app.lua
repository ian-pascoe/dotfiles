local icons = require("config.icons")

local front_app = Sbar.add("item", "front_app", {
	position = "center",
	display = "active",
	label = {
		padding_left = 5,
		padding_right = 10,
	},
})

front_app:subscribe("front_app_switched", function(env)
	local app_name = env.INFO
	front_app:set({
		label = { string = app_name },
		icon = { string = icons.map(app_name) },
	})
end)
