---Disables mouse input without disabling terminal mouse reporting.
---
---Terminals can translate scroll events into arrow keys when mouse reporting is
---disabled. This module keeps reporting enabled and discards the resulting
---mouse events at Neovim's input boundary.
local M = {}

local mouse_event_markers = {
  'Mouse',
  'Drag',
  'Release',
  'ScrollWheel',
  'Drop',
}

---Checks whether raw Neovim keycodes contain a mouse event.
---@param keys string
---@return boolean
local function is_mouse_event(keys)
  -- Ordinary text never starts with Neovim's K_SPECIAL byte.
  if keys == '' or keys:byte() ~= 0x80 then return false end

  local translated = vim.fn.keytrans(keys)
  for token in translated:gmatch('<[^>]+>') do
    for _, marker in ipairs(mouse_event_markers) do
      if token:find(marker, 1, true) then return true end
    end
  end

  return false
end

---Enables mouse reporting and installs the mouse event filter.
function M.setup()
  -- Keep mouse reporting enabled so terminals do not translate scroll events into arrow keys.
  vim.o.mouse = 'ar'
  vim.o.mousescroll = 'ver:0,hor:0'
  vim.o.mousemoveevent = false

  vim.on_key(function(key, typed)
    if is_mouse_event(key) or is_mouse_event(typed) then return '' end
  end, vim.api.nvim_create_namespace('disable-mouse'))
end

return M
