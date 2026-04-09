local utils = require("neocode.utils")
local storage = require("neocode.storage")

local M = {}

local state = {
  bufnr = nil,
  win = nil,
  step = nil,
  config = nil,
  session = nil,
  csrf = nil,
}

local function is_alive()
  return state.bufnr
    and vim.api.nvim_buf_is_valid(state.bufnr)
    and state.win
    and vim.api.nvim_win_is_valid(state.win)
end

local function close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    vim.api.nvim_buf_delete(state.bufnr, { force = true })
  end
  state.win = nil
  state.bufnr = nil
  state.step = nil
  state.config = nil
  state.session = nil
  state.csrf = nil
end

local function render(lines)
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end
  vim.bo[state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false

  -- Resize window to fit content
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local height = math.min(#lines, 25)
    vim.api.nvim_win_set_height(state.win, height)
  end
end

local function clear_keymaps()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end
  local maps = vim.api.nvim_buf_get_keymap(state.bufnr, "n")
  for _, map in ipairs(maps) do
    pcall(vim.api.nvim_buf_del_keymap, state.bufnr, "n", map.lhs)
  end
end

local function set_keymaps(keymap_table)
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end
  clear_keymaps()
  local opts = { buffer = state.bufnr, silent = true, nowait = true }
  -- Always bind q and Esc to close
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  for lhs, rhs in pairs(keymap_table) do
    vim.keymap.set("n", lhs, rhs, opts)
  end
end

local function open_browser(domain)
  if vim.fn.executable("xdg-open") == 1 then
    vim.system({ "xdg-open", "https://" .. domain }, {})
    utils.notify("Opening leetcode.com (check your browser for a new tab)")
  else
    utils.notify("Open https://" .. domain .. " in your browser")
  end
end

-- Forward declarations for step functions
local step_checking, step_authenticated, step_welcome
local step_csrf_prompt, step_confirm_save, step_validating, step_complete, step_failed

step_checking = function()
  state.step = "checking"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  Checking existing session...",
    "",
    "  q / Esc  Cancel",
  })
  set_keymaps({})

  -- Skip straight to welcome if no cookie file — avoids error notification
  if vim.fn.filereadable(state.config.cookie_path) == 0 then
    step_welcome()
    return
  end

  local auth = require("neocode.auth")
  local api = require("neocode.api")

  api.set_domain(state.config.domain)

  if not auth.load_cookies(state.config.cookie_path) then
    step_welcome()
    return
  end

  auth.validate(function(success, username)
    if not is_alive() then return end
    if success then
      step_authenticated(username)
    else
      step_welcome()
    end
  end)
end

step_authenticated = function(username)
  state.step = "authenticated"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  Already authenticated as " .. (username or "unknown"),
    "",
    "  q / Esc  Close",
  })
  set_keymaps({})
end

step_welcome = function()
  state.step = "welcome"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  To authenticate, copy two cookies from your",
    "  browser's DevTools:",
    "",
    "    1. Sign in to leetcode.com",
    "    2. DevTools (F12) \u{2192} Application \u{2192} Cookies",
    "    3. Copy LEETCODE_SESSION and csrftoken values",
    "",
    "  Enter    Paste LEETCODE_SESSION          Step 1/2",
    "  o        Open leetcode.com in browser",
    "  q / Esc  Cancel",
  })
  set_keymaps({
    ["<CR>"] = function()
      vim.schedule(function()
        if not is_alive() then return end
        local ok, value = pcall(vim.fn.input, "LEETCODE_SESSION: ")
        vim.cmd("redraw")
        if not is_alive() then return end
        if not ok or value == "" then
          step_welcome()
          return
        end
        state.session = vim.trim(value)
        step_csrf_prompt()
      end)
    end,
    ["o"] = function()
      open_browser(state.config.domain)
    end,
  })
end

step_csrf_prompt = function()
  state.step = "csrf_prompt"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  \u{2713} LEETCODE_SESSION received",
    "",
    "  Enter    Paste csrftoken                 Step 2/2",
    "  o        Open leetcode.com in browser",
    "  q / Esc  Cancel",
  })
  set_keymaps({
    ["<CR>"] = function()
      vim.schedule(function()
        if not is_alive() then return end
        local ok, value = pcall(vim.fn.input, "csrftoken: ")
        vim.cmd("redraw")
        if not is_alive() then return end
        if not ok or value == "" then
          step_csrf_prompt()
          return
        end
        state.csrf = vim.trim(value)
        step_confirm_save()
      end)
    end,
    ["o"] = function()
      open_browser(state.config.domain)
    end,
  })
end

step_confirm_save = function()
  state.step = "confirm_save"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  \u{2713} LEETCODE_SESSION received",
    "  \u{2713} csrftoken received",
    "",
    "  Save to: " .. state.config.cookie_path,
    "",
    "  Enter    Save and validate",
    "  q / Esc  Cancel",
  })
  set_keymaps({
    ["<CR>"] = function()
      step_validating()
    end,
  })
end

step_validating = function()
  state.step = "validating"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  Saving and validating...",
    "",
    "  q / Esc  Cancel",
  })
  set_keymaps({})

  local content = "LEETCODE_SESSION=" .. state.session .. "\ncsrftoken=" .. state.csrf
  storage.write_file(state.config.cookie_path, content)

  local auth = require("neocode.auth")
  local api = require("neocode.api")

  api.set_domain(state.config.domain)

  if not auth.load_cookies(state.config.cookie_path) then
    step_failed()
    return
  end

  auth.validate(function(success, username)
    if not is_alive() then return end
    if success then
      step_complete(username)
    else
      step_failed()
    end
  end)
end

step_complete = function(username)
  state.step = "complete"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  \u{2713} Authenticated as " .. (username or "unknown"),
    "",
    "  q / Esc  Close",
  })
  set_keymaps({})
end

step_failed = function()
  state.step = "failed"
  render({
    "  NeoCode Login",
    string.rep("\u{2500}", 50),
    "",
    "  \u{2717} Cookies saved but session appears expired.",
    "    Try signing in to leetcode.com again and",
    "    run :NeoCode login with fresh cookies.",
    "",
    "  Enter    Try again",
    "  q / Esc  Close",
  })
  set_keymaps({
    ["<CR>"] = function()
      state.session = nil
      state.csrf = nil
      step_welcome()
    end,
  })
end

function M.run(config)
  -- Close any existing login window
  close()

  state.config = config

  -- Create buffer
  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].filetype = "neocode-login"

  -- Float dimensions
  local width = 52
  local height = 10
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  step_checking()
end

return M
