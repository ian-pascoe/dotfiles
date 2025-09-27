local config = require("config")
local colors = config.colors
local settings = config.settings

---@class components.button.options: Sketchybar.ItemOptions
---@field hover? Sketchybar.ItemOptions

---@class components.button
---@field name string
---@field options components.button.options
---@field item Sketchybar.Item
local Button = {}
Button.__index = Button

---@type Sketchybar.ItemOptions
local defaults = {
	padding_left = settings.paddings.none,
	padding_right = settings.paddings.none,
	icon = {
		padding_left = settings.paddings.sm,
		padding_right = settings.paddings.sm,
		color = colors.primary.foreground,
	},
	label = {
		padding_left = settings.paddings.none,
		padding_right = settings.paddings.sm,
		color = colors.primary.foreground,
	},
	background = {
		color = colors.primary.background,
		corner_radius = settings.radii.md,
	},
}
local hover_defaults = {
	background = {
		color = colors.with_alpha(colors.primary.background, 0.8),
	},
}

local secondary_defaults = Util.tbl_deep_extend({}, defaults, {
	icon = {
		color = colors.secondary.foreground,
	},
	label = {
		color = colors.secondary.foreground,
	},
	background = {
		color = colors.secondary.background,
	},
})
local secondary_hover_defaults = {
	background = {
		color = colors.with_alpha(colors.secondary.background, 0.8),
	},
}

local tertiary_defaults = Util.tbl_deep_extend({}, defaults, {
	icon = {
		color = colors.tertiary.foreground,
	},
	label = {
		color = colors.tertiary.foreground,
	},
	background = {
		color = colors.tertiary.background,
	},
})
local tertiary_hover_defaults = {
	background = {
		color = colors.with_alpha(colors.tertiary.background, 0.8),
	},
}

local accent_defaults = Util.tbl_deep_extend({}, defaults, {
	icon = {
		color = colors.accent.foreground,
	},
	label = {
		color = colors.accent.foreground,
	},
	background = {
		color = colors.accent.background,
	},
})
local accent_hover_defaults = {
	background = {
		color = colors.with_alpha(colors.accent.background, 0.8),
	},
}

local ghost_defaults = Util.tbl_deep_extend({}, defaults, {
	icon = {
		color = colors.foreground,
	},
	label = {
		color = colors.foreground,
	},
	background = {
		color = colors.transparent,
	},
})
local ghost_hover_defaults = {
	icon = {
		color = colors.accent.foreground,
	},
	label = {
		color = colors.accent.foreground,
	},
	background = {
		color = colors.with_alpha(colors.accent.background, 0.8),
	},
}

--- Creates a new Button instance.
---@param name string
---@param variant? "primary" | "secondary" | "tertiary" | "accent" | "ghost"
---@param options? components.button.options
---@return components.button
function Button:new(name, variant, options)
	---@type components.button
	---@diagnostic disable-next-line: missing-fields
	local instance = {}
	setmetatable(instance, self)

	instance.name = name

	options = options or {}
	local hover_options = options.hover or {}
	options.hover = nil -- remove hover from options to avoid passing it to sketchybar

	local resolved_options = {}
	local resolved_hover_options = {}
	if variant == "secondary" then
		resolved_options = Util.tbl_deep_extend({}, secondary_defaults, options)
		resolved_hover_options = Util.tbl_deep_extend({}, secondary_hover_defaults, hover_options)
	elseif variant == "tertiary" then
		resolved_options = Util.tbl_deep_extend({}, tertiary_defaults, options)
		resolved_hover_options = Util.tbl_deep_extend({}, tertiary_hover_defaults, hover_options)
	elseif variant == "accent" then
		resolved_options = Util.tbl_deep_extend({}, accent_defaults, options)
		resolved_hover_options = Util.tbl_deep_extend({}, accent_hover_defaults, hover_options)
	elseif variant == "ghost" then
		resolved_options = Util.tbl_deep_extend({}, ghost_defaults, options)
		resolved_hover_options = Util.tbl_deep_extend({}, ghost_hover_defaults, hover_options)
	else
		resolved_options = Util.tbl_deep_extend({}, defaults, options)
		resolved_hover_options = Util.tbl_deep_extend({}, hover_defaults, hover_options)
	end

	instance.options = Util.tbl_deep_extend({}, resolved_options, { hover = resolved_hover_options })

	instance.item = Sbar.add("item", name, resolved_options)

	-- default hover behavior, can be overridden by calling instance:on_hover again
	instance:on_hover(resolved_hover_options)

	return instance
end

--- Sets item options on hover, and reverts them when hover ends.
---@param options Sketchybar.ItemOptions
function Button:on_hover(options)
	self.item:subscribe("mouse.entered", function()
		self.item:set(options)
	end)
	self.item:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
		self.item:set(self.options)
	end)
end

--- Action to perform on click.
--- @param fn fun()
function Button:on_click(fn)
	self.item:subscribe("mouse.clicked", fn)
end

--- Standard sketchybar event subscription.
---@param events string|string[]
---@param fn fun(env: table)
function Button:subscribe(events, fn)
	self.item:subscribe(events, fn)
end

--- Sets new options for the button.
---@param options components.button.options
function Button:set(options)
	self.options = Util.tbl_deep_extend({}, self.options, options)
	local hover_options = Util.tbl_deep_extend({}, self.options.hover or {}, options.hover or {})
	self.item:set(options)
	self:on_hover(hover_options)
end

--- Removes the button from sketchybar.
function Button:remove()
	Sbar.remove(self.name)
end

return Button
