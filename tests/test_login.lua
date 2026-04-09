local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_once = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    pre_case = function()
      child.lua([[
        _G.tmp = vim.fn.tempname()
        vim.fn.mkdir(_G.tmp, "p")
        require("neocode").setup({
          storage_dir = _G.tmp,
          cookie_path = _G.tmp .. "/cookies",
        })
        package.loaded["neocode.auth"] = nil
        package.loaded["neocode.auth.login"] = nil
        package.loaded["neocode.api"] = nil
        _G.login = require("neocode.auth.login")
      ]])
    end,
    post_case = function()
      child.lua([[
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype == "neocode-login" then
            vim.api.nvim_win_close(win, true)
          end
        end
        vim.fn.delete(_G.tmp, "rf")
      ]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

local function find_login_win(c)
  c.lua([[
    _G._login_buf = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neocode-login" then
        _G._login_buf = buf
        break
      end
    end
  ]])
  return c.lua_get("_G._login_buf")
end

local function get_login_lines(c)
  c.lua([[
    _G._login_lines = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neocode-login" then
        _G._login_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        break
      end
    end
  ]])
  return c.lua_get("_G._login_lines")
end

local function lines_contain(lines, pattern)
  for _, line in ipairs(lines) do
    if line:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

local function open_login(c)
  c.lua("_G.login.run(require('neocode').config)")
end

T["login"] = new_set()

T["login"]["opens floating window"] = function()
  open_login(child)
  local buf = find_login_win(child)
  eq(buf ~= vim.NIL and buf ~= nil, true)
end

T["login"]["shows welcome when no cookies exist"] = function()
  open_login(child)
  local lines = get_login_lines(child)
  eq(lines_contain(lines, "browser's DevTools"), true)
end

T["login"]["q closes the window"] = function()
  open_login(child)
  child.type_keys("q")
  local buf = find_login_win(child)
  eq(buf == vim.NIL or buf == nil, true)
end

T["login"]["Esc closes the window"] = function()
  open_login(child)
  child.type_keys("<Esc>")
  local buf = find_login_win(child)
  eq(buf == vim.NIL or buf == nil, true)
end

T["login"]["welcome screen shows step 1/2 with Enter prompt"] = function()
  open_login(child)
  local lines = get_login_lines(child)
  eq(lines_contain(lines, "Step 1/2"), true)
  eq(lines_contain(lines, "Enter"), true)
end

T["login"]["cookie file is written on save"] = function()
  open_login(child)
  -- Mock vim.fn.input for LEETCODE_SESSION
  child.lua('vim.fn.input = function() return "test_session_value" end')
  child.type_keys("<CR>")
  -- Allow vim.schedule to process
  vim.loop.sleep(50)
  child.lua('vim.cmd("redraw")')
  -- Mock vim.fn.input for csrftoken
  child.lua('vim.fn.input = function() return "test_csrf_value" end')
  child.type_keys("<CR>")
  -- Allow vim.schedule to process
  vim.loop.sleep(50)
  child.lua('vim.cmd("redraw")')
  -- Confirm save
  child.type_keys("<CR>")

  child.lua([[
    local path = _G.tmp .. "/cookies"
    if vim.fn.filereadable(path) == 1 then
      _G._cookie_content = table.concat(vim.fn.readfile(path), "\n")
    else
      _G._cookie_content = ""
    end
  ]])
  eq(child.lua_get("_G._cookie_content"), "LEETCODE_SESSION=test_session_value\ncsrftoken=test_csrf_value")
end

T["login"]["buffer is not modifiable"] = function()
  open_login(child)
  child.lua([[
    _G._modifiable = true
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neocode-login" then
        _G._modifiable = vim.bo[buf].modifiable
        break
      end
    end
  ]])
  eq(child.lua_get("_G._modifiable"), false)
end

return T
