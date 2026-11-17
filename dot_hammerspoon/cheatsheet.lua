-- Keybinding cheat sheet overlay (~/.config/keybindings/cheatsheet.html).
--
-- Two ways in, which-key style:
--   * Hyper+/ (init.lua), or opening hammerspoon://keybindings, toggles it.
--   * Holding cmd on its own for HOLD_SECONDS peeks at it until cmd is released.
-- Esc or a click outside closes a toggled sheet.
local M = {}

local HOLD_SECONDS = 0.8
local PATH = os.getenv("HOME") .. "/.config/keybindings/cheatsheet.html"

local view = nil
local peeking = false
local holdTimer = nil
local escape = nil
local clickWatcher = nil

local function frame()
  local screen = hs.screen.mainScreen():frame()
  local w = math.min(1500, screen.w * 0.94)
  local h = math.min(940, screen.h * 0.92)
  return { x = screen.x + (screen.w - w) / 2, y = screen.y + (screen.h - h) / 2, w = w, h = h }
end

function M.hide()
  if escape then
    escape:delete()
    escape = nil
  end
  if clickWatcher then
    clickWatcher:stop()
    clickWatcher = nil
  end
  if view then
    view:delete()
    view = nil
  end
  peeking = false
end

function M.show(peek)
  if view then
    return
  end
  if not hs.fs.attributes(PATH) then
    hs.alert.show("No cheat sheet at " .. PATH)
    return
  end
  view = hs.webview
    .new(frame(), { developerExtrasEnabled = false })
    :windowStyle({ "borderless", "nonactivating" })
    :level(hs.drawing.windowLevels.modalPanel)
    :shadow(true)
    :allowTextEntry(false)
    :transparent(true)
    :url("file://" .. PATH)
    :show()
  peeking = peek
  if not peek then
    escape = hs.hotkey.bind({}, "escape", M.hide)
    clickWatcher = hs.eventtap
      .new({ hs.eventtap.event.types.leftMouseDown }, function()
        local pos = hs.mouse.absolutePosition()
        local f = frame()
        if pos.x < f.x or pos.x > f.x + f.w or pos.y < f.y or pos.y > f.y + f.h then
          M.hide()
        end
        return false
      end)
      :start()
  end
end

function M.toggle()
  if view then
    M.hide()
  else
    M.show(false)
  end
end

-- which-key style peek: cmd alone, held, with no other key pressed meanwhile.
local function cancelHold()
  if holdTimer then
    holdTimer:stop()
    holdTimer = nil
  end
end

local function onlyCmd(flags)
  return flags.cmd and not (flags.alt or flags.ctrl or flags.shift or flags.fn)
end

local types = hs.eventtap.event.types
M.holdWatcher = hs.eventtap.new({ types.flagsChanged, types.keyDown }, function(event)
  if event:getType() == types.keyDown then
    cancelHold()
    if peeking then
      M.hide()
    end
    return false
  end
  local flags = event:getFlags()
  if onlyCmd(flags) then
    if not holdTimer and not view then
      holdTimer = hs.timer.doAfter(HOLD_SECONDS, function()
        holdTimer = nil
        M.show(true)
      end)
    end
  else
    cancelHold()
    if peeking then
      M.hide()
    end
  end
  return false
end)

function M.start()
  hs.urlevent.bind("keybindings", M.toggle)
  M.holdWatcher:start()
  -- macOS disables an event tap that ever runs slow; turn it back on.
  M.watchdog = hs.timer.doEvery(5, function()
    if not M.holdWatcher:isEnabled() then
      M.holdWatcher:start()
    end
  end)
  return M
end

return M
