local calendar = Sbar.add("item", "calendar", {
	position = "right",
	align = "right",
	label = {
		align = "right",
		font = {
			style = "Regular",
			size = 14.0,
		},
	},
	update_freq = 1,
})

local function update()
	calendar:set({
		icon = { string = "󰅐" },
		label = { string = os.date("%r") },
	})
end

calendar:subscribe("routine", update)
calendar:subscribe("forced", update)
