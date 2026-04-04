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
        require("neocode").setup({ storage_dir = _G.tmp })
        -- Reset api credentials between tests
        package.loaded["neocode.auth"] = nil
        package.loaded["neocode.api"] = nil
        _G.auth = require("neocode.auth")
        _G.api = require("neocode.api")
      ]])
    end,
    post_case = function()
      child.lua('vim.fn.delete(_G.tmp, "rf")')
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["load_cookies"] = new_set()

T["load_cookies"]["valid cookie file"] = function()
  child.lua([[
    local path = _G.tmp .. "/cookies"
    vim.fn.writefile({
      "LEETCODE_SESSION=abc123",
      "csrftoken=xyz789",
    }, path)
    _G.result = _G.auth.load_cookies(path)
  ]])
  eq(child.lua_get("_G.result"), true)
  eq(child.lua_get("_G.api.is_authenticated()"), true)
end

T["load_cookies"]["missing file returns false"] = function()
  local result = child.lua_get('_G.auth.load_cookies(_G.tmp .. "/nonexistent")')
  eq(result, false)
end

T["load_cookies"]["empty file returns false"] = function()
  child.lua([[
    local path = _G.tmp .. "/cookies"
    vim.fn.writefile({}, path)
    _G.result = _G.auth.load_cookies(path)
  ]])
  eq(child.lua_get("_G.result"), false)
end

T["load_cookies"]["missing LEETCODE_SESSION returns false"] = function()
  child.lua([[
    local path = _G.tmp .. "/cookies"
    vim.fn.writefile({ "csrftoken=xyz789" }, path)
    _G.result = _G.auth.load_cookies(path)
  ]])
  eq(child.lua_get("_G.result"), false)
end

T["load_cookies"]["missing csrftoken returns false"] = function()
  child.lua([[
    local path = _G.tmp .. "/cookies"
    vim.fn.writefile({ "LEETCODE_SESSION=abc123" }, path)
    _G.result = _G.auth.load_cookies(path)
  ]])
  eq(child.lua_get("_G.result"), false)
end

T["load_cookies"]["skips comments and blank lines"] = function()
  child.lua([[
    local path = _G.tmp .. "/cookies"
    vim.fn.writefile({
      "# This is a comment",
      "",
      "LEETCODE_SESSION=abc123",
      "# Another comment",
      "",
      "csrftoken=xyz789",
    }, path)
    _G.result = _G.auth.load_cookies(path)
  ]])
  eq(child.lua_get("_G.result"), true)
  eq(child.lua_get("_G.api.is_authenticated()"), true)
end

T["load_cookies"]["trims whitespace around keys and values"] = function()
  child.lua([[
    local path = _G.tmp .. "/cookies"
    vim.fn.writefile({
      "  LEETCODE_SESSION  =  abc123  ",
      "  csrftoken  =  xyz789  ",
    }, path)
    _G.result = _G.auth.load_cookies(path)
  ]])
  eq(child.lua_get("_G.result"), true)
end

T["load_cookies"]["ignores extra keys"] = function()
  child.lua([[
    local path = _G.tmp .. "/cookies"
    vim.fn.writefile({
      "SOME_OTHER_KEY=value",
      "LEETCODE_SESSION=abc123",
      "another=thing",
      "csrftoken=xyz789",
    }, path)
    _G.result = _G.auth.load_cookies(path)
  ]])
  eq(child.lua_get("_G.result"), true)
end

return T
