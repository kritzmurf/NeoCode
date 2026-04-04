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
        -- Fresh modules each test
        package.loaded["neocode"] = nil
        package.loaded["neocode.study"] = nil
        package.loaded["neocode.study.progress"] = nil
        require("neocode").setup({ storage_dir = _G.tmp })
        _G.study = require("neocode.study")
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

T["available_plans"] = new_set()

T["available_plans"]["returns sorted list"] = function()
  local plans = child.lua_get("_G.study.available_plans()")
  eq(plans, { "blind75", "grind75", "neetcode150" })
end

T["load_plan"] = new_set()

T["load_plan"]["valid slug returns plan table"] = function()
  child.lua('_G.plan = _G.study.load_plan("blind75")')
  local plan = child.lua_get("_G.plan")
  eq(plan.name, "Blind 75")
  eq(plan.slug, "blind75")
  eq(type(plan.categories), "table")
end

T["load_plan"]["invalid slug returns nil"] = function()
  local result = child.lua_get('_G.study.load_plan("nonexistent") == nil')
  eq(result, true)
end

T["get_plan_summary"] = new_set()

T["get_plan_summary"]["returns expected structure"] = function()
  child.lua('_G.summary = _G.study.get_plan_summary("blind75")')
  local s = child.lua_get("_G.summary")
  eq(type(s.name), "string")
  eq(type(s.slug), "string")
  eq(type(s.description), "string")
  eq(type(s.category_count), "number")
  eq(s.category_count > 0, true)
  eq(type(s.stats), "table")
  eq(type(s.stats.total), "number")
  eq(type(s.stats.solved), "number")
end

T["next_unsolved"] = new_set()

T["next_unsolved"]["with no progress returns first problem"] = function()
  child.lua('_G.problem = _G.study.next_unsolved("blind75")')
  local p = child.lua_get("_G.problem")
  eq(type(p.slug), "string")
  eq(type(p.title), "string")
  eq(type(p.id), "number")
end

T["next_unsolved"]["returns nil when all solved"] = function()
  child.lua([[
    local progress = require("neocode.study.progress")
    local plan = _G.study.load_plan("blind75")
    for _, cat in ipairs(plan.categories) do
      for _, prob in ipairs(cat.problems) do
        progress.mark_solved("blind75", prob.slug)
      end
    end
    _G.result = _G.study.next_unsolved("blind75")
  ]])
  local result = child.lua_get("_G.result == nil")
  eq(result, true)
end

return T
