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
        package.loaded["neocode.utils"] = nil
        _G.utils = require("neocode.utils")
      ]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["notify"] = new_set()

T["notify"]["prepends neocode prefix"] = function()
  child.lua([[
    _G.last_msg = nil
    _G.last_level = nil
    local orig = vim.notify
    vim.notify = function(msg, level)
      _G.last_msg = msg
      _G.last_level = level
    end
    _G.utils.notify("test message")
    vim.notify = orig
  ]])
  eq(child.lua_get("_G.last_msg"), "neocode: test message")
end

T["notify"]["defaults to INFO level"] = function()
  child.lua([[
    _G.last_level = nil
    local orig = vim.notify
    vim.notify = function(msg, level)
      _G.last_level = level
    end
    _G.utils.notify("test")
    vim.notify = orig
  ]])
  local level = child.lua_get("_G.last_level")
  local info = child.lua_get("vim.log.levels.INFO")
  eq(level, info)
end

T["read_buf_content"] = new_set()

T["read_buf_content"]["returns all lines joined"] = function()
  child.lua([[
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line1", "line2", "line3" })
    _G.result = _G.utils.read_buf_content(buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  ]])
  eq(child.lua_get("_G.result"), "line1\nline2\nline3")
end

T["read_buf_content"]["empty buffer returns empty string"] = function()
  child.lua([[
    local buf = vim.api.nvim_create_buf(false, true)
    _G.result = _G.utils.read_buf_content(buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  ]])
  eq(child.lua_get("_G.result"), "")
end

T["poll"] = new_set()

T["poll"]["immediate finish calls on_done with result"] = function()
  child.lua([[
    _G.poll_result = nil
    _G.poll_err = "not called"
    _G.utils.poll(function(done)
      done(true, "success")
    end, 10, 5, function(err, result)
      _G.poll_err = err
      _G.poll_result = result
    end)
  ]])
  -- poll is synchronous on first tick if check_fn calls done immediately
  eq(child.lua_get("_G.poll_result"), "success")
  local err = child.lua_get("_G.poll_err == nil")
  eq(err, true)
end

T["poll"]["times out at max attempts"] = function()
  child.lua([[
    _G.poll_err = nil
    _G.poll_result = "not called"
    _G.utils.poll(function(done)
      done(false, nil)
    end, 1, 1, function(err, result)
      _G.poll_err = err
      _G.poll_result = result
    end)
  ]])
  -- With max_attempts=1 and done(false), should time out on first tick
  -- Need to wait for the deferred call
  vim.uv.sleep(50)
  local err = child.lua_get("_G.poll_err")
  eq(type(err), "string")
  eq(err:find("Timed out") ~= nil, true)
end

return T
