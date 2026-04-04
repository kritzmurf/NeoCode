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
        package.loaded["neocode"] = nil
        package.loaded["neocode.commands"] = nil
        require("neocode").setup({ storage_dir = _G.tmp })
        _G.commands = require("neocode.commands")
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

T["complete"] = new_set()

T["complete"]["no args returns all subcommands sorted"] = function()
  child.lua('_G.result = _G.commands.complete(nil, "Neocode ", nil)')
  local result = child.lua_get("_G.result")
  eq(type(result), "table")
  eq(#result > 0, true)
  -- Verify sorted
  for i = 2, #result do
    eq(result[i] >= result[i - 1], true)
  end
  -- Verify key commands present
  local has = {}
  for _, v in ipairs(result) do
    has[v] = true
  end
  eq(has["auth"], true)
  eq(has["plan"], true)
  eq(has["open"], true)
  eq(has["submit"], true)
end

T["complete"]["partial prefix filters"] = function()
  child.lua('_G.result = _G.commands.complete(nil, "Neocode pl", nil)')
  local result = child.lua_get("_G.result")
  eq(result, { "plan" })
end

T["complete"]["plan subcommand shows plan names and list"] = function()
  -- Need a partial arg to trigger 3rd-position completion (trimempty eats trailing space)
  child.lua('_G.result = _G.commands.complete(nil, "Neocode plan b", nil)')
  local result = child.lua_get("_G.result")
  local has = {}
  for _, v in ipairs(result) do
    has[v] = true
  end
  eq(has["blind75"], true)
end

T["dispatch"] = new_set()

T["dispatch"]["no subcommand does not error"] = function()
  -- Should show help via notify, not throw
  child.lua('_G.commands.dispatch({ fargs = {} })')
end

T["dispatch"]["unknown command does not error"] = function()
  child.lua('_G.commands.dispatch({ fargs = { "fakecmd" } })')
end

return T
