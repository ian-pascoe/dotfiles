local icons = require("config.icons")

---@class items.front_app
local M = {}

M.widget = Sbar.add("item", "front_app", {
	position = "left",
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

M.widget:subscribe("front_app_switched", function(env)
	local app_name = env.INFO
	M.widget:set({
		icon = {
			string = "󰅂 " .. icons.map(app_name),
		},
		label = {
			string = app_name,
		},
	})
end)

return M
