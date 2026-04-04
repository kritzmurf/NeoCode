local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_once = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    pre_case = function()
      -- Clear module cache for fresh setup each test
      child.lua([[
        package.loaded["neocode"] = nil
        package.loaded["neocode.config"] = nil
        package.loaded["neocode.storage"] = nil
      ]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["defaults"] = new_set()

T["defaults"]["has required keys"] = function()
  child.lua('_G.defaults = require("neocode.config").defaults')
  local d = child.lua_get("_G.defaults")
  eq(type(d.lang), "string")
  eq(type(d.domain), "string")
  eq(type(d.storage_dir), "string")
  eq(type(d.cookie_path), "string")
  eq(type(d.active_plan), "string")
  eq(type(d.ui), "table")
  eq(type(d.ui.description_width), "number")
end

T["defaults"]["default lang is python3"] = function()
  local lang = child.lua_get('require("neocode.config").defaults.lang')
  eq(lang, "python3")
end

T["defaults"]["default domain is leetcode.com"] = function()
  local domain = child.lua_get('require("neocode.config").defaults.domain')
  eq(domain, "leetcode.com")
end

T["setup"] = new_set()

T["setup"]["empty opts uses defaults"] = function()
  child.lua('require("neocode").setup({})')
  local config = child.lua_get('require("neocode").config')
  eq(config.lang, "python3")
  eq(config.domain, "leetcode.com")
  eq(config.active_plan, "blind75")
end

T["setup"]["overrides single key"] = function()
  child.lua('require("neocode").setup({ lang = "cpp" })')
  local config = child.lua_get('require("neocode").config')
  eq(config.lang, "cpp")
  eq(config.domain, "leetcode.com")
end

T["setup"]["deep merges nested tables"] = function()
  child.lua('require("neocode").setup({ ui = { description_width = 0.6 } })')
  local config = child.lua_get('require("neocode").config')
  eq(config.ui.description_width, 0.6)
end

T["setup"]["nil opts uses defaults"] = function()
  child.lua('require("neocode").setup()')
  local config = child.lua_get('require("neocode").config')
  eq(config.lang, "python3")
end

return T
