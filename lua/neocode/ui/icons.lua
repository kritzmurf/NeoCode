local M = {}

local nerd = {
  folder_closed = "\u{e5ff}",  -- nf-custom-folder
  folder_open   = "\u{e5fe}",  -- nf-custom-folder_open
  solved        = "\u{f00c}",  -- nf-fa-check
  attempted     = "\u{f12a}",  -- nf-fa-exclamation
  unsolved      = "\u{f096}",  -- nf-fa-square_o
}

local ascii = {
  folder_closed = ">",
  folder_open   = "v",
  solved        = "[x]",
  attempted     = "[~]",
  unsolved      = "[ ]",
}

local function has_nerd_font()
  -- Check if the terminal can render a Nerd Font glyph by measuring its display width.
  -- Nerd Font glyphs are single-width characters; if missing, they render as
  -- replacement characters or zero-width, which strdisplaywidth reports differently.
  local width = vim.fn.strdisplaywidth("\u{e5ff}")
  return width == 1 or width == 2
end

function M.get()
  local config = require("neocode").config
  local setting = config.ui.icons or "auto"

  if setting == "nerd" then
    return nerd
  elseif setting == "ascii" then
    return ascii
  else
    if has_nerd_font() then
      return nerd
    end
    return ascii
  end
end

return M
