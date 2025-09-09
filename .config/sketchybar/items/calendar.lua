local calendar = Sbar.add("item", "calendar", {
	position = "right",
	align = "right",
	icon = { drawing = false },
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
	calendar:set({ label = { string = os.date("%a. %d %b.") .. " " .. os.date("%r") } })
end

calendar:subscribe("routine", update)
calendar:subscribe("forced", update)
