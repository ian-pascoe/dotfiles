local config = require("config")
local colors = config.colors
local settings = config.settings

---@class components.button.options: Sketchybar.ItemOptions
---@field hover? Sketchybar.ItemOptions

---@class components.button: Sketchybar.Item
---@field name string
---@field options components.button.options
---@field base_options Sketchybar.ItemOptions
---@field hover_options Sketchybar.ItemOptions
---@field item Sketchybar.Item
local Button = {}
Button.__index = Button

---@type Sketchybar.ItemOptions
local DEFAULTS = {
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

---@type Sketchybar.ItemOptions
local HOVER_DEFAULTS = {
  background = {
    color = colors.with_alpha(colors.primary.background, 0.8),
  },
}

---@type Sketchybar.ItemOptions
local SECONDARY_DEFAULTS = Util.tbl_deep_extend({}, DEFAULTS, {
  icon = { color = colors.secondary.foreground },
  label = { color = colors.secondary.foreground },
  background = { color = colors.secondary.background },
})
---@type Sketchybar.ItemOptions
local SECONDARY_HOVER_DEFAULTS = {
  background = { color = colors.with_alpha(colors.secondary.background, 0.8) },
}

---@type Sketchybar.ItemOptions
local TERTIARY_DEFAULTS = Util.tbl_deep_extend({}, DEFAULTS, {
  icon = { color = colors.tertiary.foreground },
  label = { color = colors.tertiary.foreground },
  background = { color = colors.tertiary.background },
})
---@type Sketchybar.ItemOptions
local TERTIARY_HOVER_DEFAULTS = {
  background = { color = colors.with_alpha(colors.tertiary.background, 0.8) },
}

---@type Sketchybar.ItemOptions
local ACCENT_DEFAULTS = Util.tbl_deep_extend({}, DEFAULTS, {
  icon = { color = colors.accent.foreground },
  label = { color = colors.accent.foreground },
  background = { color = colors.accent.background },
})
---@type Sketchybar.ItemOptions
local ACCENT_HOVER_DEFAULTS = {
  background = { color = colors.with_alpha(colors.accent.background, 0.8) },
}

---@type Sketchybar.ItemOptions
local GHOST_DEFAULTS = Util.tbl_deep_extend({}, DEFAULTS, {
  icon = { color = colors.foreground },
  label = { color = colors.foreground },
  background = { color = colors.transparent },
})
---@type Sketchybar.ItemOptions
local GHOST_HOVER_DEFAULTS = {
  icon = { color = colors.accent.foreground },
  label = { color = colors.accent.foreground },
  background = { color = colors.with_alpha(colors.accent.background, 0.8) },
}

---@type Sketchybar.ItemOptions
local OUTLINE_DEFAULTS = Util.tbl_deep_extend({}, DEFAULTS, {
  icon = { color = colors.foreground },
  label = { color = colors.foreground },
  background = {
    color = colors.transparent,
    border_color = colors.border,
    border_width = 1,
  },
})
---@type Sketchybar.ItemOptions
local OUTLINE_HOVER_DEFAULTS = {
  icon = { color = colors.accent.foreground },
  label = { color = colors.accent.foreground },
  background = { color = colors.with_alpha(colors.accent.background, 0.8) },
}

--- Creates a new Button instance.
---@param name string
---@param variant? "primary" | "secondary" | "tertiary" | "accent" | "ghost" | "outline"
---@param options? components.button.options
---@return components.button
function Button:new(name, variant, options)
  ---@type components.button
  ---@diagnostic disable-next-line: missing-fields
  local instance = {}

  instance.name = name

  options = options or {}
  local hover_options = options.hover or {}
  options.hover = nil -- remove hover from options to avoid passing it to sketchybar

  local resolved_options = {}
  local resolved_hover_options = {}
  if variant == "secondary" then
    resolved_options = Util.tbl_deep_extend({}, SECONDARY_DEFAULTS, options)
    resolved_hover_options = Util.tbl_deep_extend({}, SECONDARY_HOVER_DEFAULTS, hover_options)
  elseif variant == "tertiary" then
    resolved_options = Util.tbl_deep_extend({}, TERTIARY_DEFAULTS, options)
    resolved_hover_options = Util.tbl_deep_extend({}, TERTIARY_HOVER_DEFAULTS, hover_options)
  elseif variant == "accent" then
    resolved_options = Util.tbl_deep_extend({}, ACCENT_DEFAULTS, options)
    resolved_hover_options = Util.tbl_deep_extend({}, ACCENT_HOVER_DEFAULTS, hover_options)
  elseif variant == "ghost" then
    resolved_options = Util.tbl_deep_extend({}, GHOST_DEFAULTS, options)
    resolved_hover_options = Util.tbl_deep_extend({}, GHOST_HOVER_DEFAULTS, hover_options)
  elseif variant == "outline" then
    resolved_options = Util.tbl_deep_extend({}, OUTLINE_DEFAULTS, options)
    resolved_hover_options = Util.tbl_deep_extend({}, OUTLINE_HOVER_DEFAULTS, hover_options)
  else
    resolved_options = Util.tbl_deep_extend({}, DEFAULTS, options)
    resolved_hover_options = Util.tbl_deep_extend({}, HOVER_DEFAULTS, hover_options)
  end

  -- Per-instance deep copies to prevent shared nested tables
  resolved_options = Util.tbl_deep_copy(resolved_options)
  resolved_hover_options = Util.tbl_deep_copy(resolved_hover_options)

  instance.base_options = resolved_options
  instance.hover_options = resolved_hover_options
  instance.options = Util.tbl_deep_extend({}, instance.base_options, { hover = instance.hover_options })

  instance.item = Sbar.add("item", name, instance.base_options)

  -- Create a metatable that proxies method calls to instance.item
  setmetatable(instance, {
    __index = function(t, k)
      if self[k] then
        return self[k]
      end
      local item_method = t.item[k]
      if type(item_method) == "function" then
        return function(_, ...)
          return item_method(t.item, ...)
        end
      end
      return item_method
    end,
  })

  -- default hover behavior, can be overridden
  instance:on_hover()

  return instance
end

--- Action to perform on hover.
---@param options_or_fn? Sketchybar.ItemOptions | fun(hovering: boolean) options to apply on hover, or function to call on hover/leave
---@param override_default_behavior? boolean if true, does not apply default hover behavior (setting hover options)
function Button:on_hover(options_or_fn, override_default_behavior)
  if type(options_or_fn) == "function" then
    local fn = options_or_fn
    self.item:subscribe("mouse.entered", function()
      if not override_default_behavior then
        self.item:set(self.hover_options)
      end
      fn(true)
    end)
    self.item:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
      if not override_default_behavior then
        self.item:set(self.base_options)
      end
      fn(false)
    end)
    return
  end

  local hover_options = options_or_fn
  if hover_options then
    self.hover_options = Util.tbl_deep_extend({}, self.hover_options or {}, hover_options)
  end

  self.item:subscribe("mouse.entered", function()
    self.item:set(self.hover_options)
  end)
  self.item:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
    self.item:set(self.base_options)
  end)
end

--- Action to perform on click.
--- @param fn fun()
function Button:on_click(fn)
  self.item:subscribe("mouse.clicked", fn)
end

--- Sets new options for the button.
---@param options components.button.options
function Button:set(options)
  local hover = options.hover
  options.hover = nil
  if next(options) ~= nil then
    self.base_options = Util.tbl_deep_extend({}, self.base_options, options)
    self.item:set(options)
  end
  if hover then
    self.hover_options = Util.tbl_deep_extend({}, self.hover_options, hover)
    self:on_hover() -- refresh subscriptions with updated hover options
  end
  self.options = Util.tbl_deep_extend({}, self.base_options, { hover = self.hover_options })
end

--- Removes the button from sketchybar.
function Button:remove()
  Sbar.remove(self.name)
end

return Button
