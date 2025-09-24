local colors = require("config.colors")
local icons = require("config.icons")
local settings = require("config.settings")

local spaces_mode = Sbar.add("item", "spaces_mode", {
	position = "left",
	padding_left = settings.paddings / 2,
	padding_right = settings.paddings / 2,
	icon = { drawing = false },
	label = {
		string = "main",
		padding_left = 10,
		padding_right = 10,
	},
	background = {
		drawing = true,
		color = colors.with_alpha(colors.secondary.background, 0.8),
		border_color = colors.border,
		border_width = 1,
		corner_radius = 25,
	},
	blur_radius = 10,
})
spaces_mode:subscribe("aerospace_mode_change", function(env)
	local mode = env.MODE or "main"
	spaces_mode:set({
		label = { string = mode },
	})
end)

Sbar.exec("aerospace list-monitors --format '%{monitor-id}'", function(monitor_result)
	local mids = monitor_result:gmatch("[^\n]+")
	for mid in mids do
		mid = Util.trim(mid)
		local mnum = tonumber(mid) or 0
		Sbar.exec("aerospace list-workspaces --monitor " .. mnum, function(workspace_result)
			local wids = workspace_result:gmatch("[^\n]+")
			for wid in wids do
				wid = Util.trim(wid)
				local wnum = tonumber(wid) or 0
				local space_item = Sbar.add("item", "space_item." .. wnum, {
					position = "left",
					padding_left = settings.paddings / 4,
					padding_right = settings.paddings / 4,
					icon = {
						string = wid,
						padding_left = 8,
						padding_right = 8,
						color = colors.foreground,
						highlight_color = colors.primary.background,
						font = { family = settings.font, size = 14 },
					},
					label = {
						drawing = false,
						padding_left = 0,
						padding_right = 8,
						color = colors.foreground,
						highlight_color = colors.primary.background,
						font = {
							family = settings.nerd_font,
							size = 10,
						},
						y_offset = 1,
					},
					background = {
						drawing = true,
						color = colors.with_alpha(colors.card.background, 0.8),
						border_color = colors.border,
						border_width = 1,
						corner_radius = 25,
					},
					associated_display = mnum,
					blur_radius = 10,
					update_freq = 2,
				})

				local function set_focused(result)
					local focused_num = tonumber(result)
					local is_focused = focused_num == wnum
					local color = is_focused and colors.primary.background or colors.border
					space_item:set({
						icon = { highlight = is_focused },
						label = { highlight = is_focused },
						background = { border_color = color },
					})
				end

				space_item:subscribe({ "aerospace_workspace_change", "routine", "forced" }, function(env)
					if env.FOCUSED ~= nil then
						set_focused(env.FOCUSED)
					else
						Sbar.exec("aerospace list-workspaces --focused", set_focused)
					end

					Sbar.exec(
						"aerospace list-windows --workspace " .. wnum .. ' --format "%{app-name}"',
						function(result)
							local icon_line = ""

							if result and result ~= "" then
								local apps = {}
								for app in result:gmatch("[^\n]+") do
									if app and app ~= "" and app ~= "None" then
										apps[app] = true -- Use as set to avoid duplicates
									end
								end

								-- Convert to icon line
								local i = 1
								local max_icons = 4
								for app, _ in pairs(apps) do
									if i > max_icons then
										icon_line = icon_line .. " " .. icons.ellipsis
										break
									end

									if i > 1 and i ~= #apps then
										icon_line = icon_line .. " " .. icons.map(app)
									else
										icon_line = icon_line .. icons.map(app)
									end
									i = i + 1
								end
							end

							space_item:set({ label = { drawing = icon_line ~= "", string = icon_line } })
						end
					)
				end)

				space_item:subscribe("mouse.clicked", function(env)
					if env.BUTTON == "left" then
						Sbar.exec("aerospace workspace " .. wnum)
					elseif env.BUTTON == "right" then
						-- TODO: destroy / create?
						-- For right-click, just focus the workspace
						Sbar.exec("aerospace workspace " .. wnum)
					end
				end)
			end
		end)
	end
end)
