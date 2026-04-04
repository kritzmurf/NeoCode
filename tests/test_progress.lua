local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_once = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    pre_case = function()
      -- Fresh temp dir and neocode setup for each test
      child.lua([[
        _G.tmp = vim.fn.tempname()
        vim.fn.mkdir(_G.tmp, "p")
        require("neocode").setup({ storage_dir = _G.tmp })
        -- Clear module cache so progress reads fresh files
        package.loaded["neocode.study.progress"] = nil
        _G.progress = require("neocode.study.progress")
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

T["load"] = new_set()

T["load"]["fresh plan returns empty table"] = function()
  local result = child.lua_get('_G.progress.load("testplan")')
  eq(result, {})
end

T["mark_solved"] = new_set()

T["mark_solved"]["sets solved flag"] = function()
  child.lua('_G.progress.mark_solved("testplan", "two-sum")')
  local p = child.lua_get('_G.progress.load("testplan")')
  eq(p["two-sum"].solved, true)
end

T["mark_solved"]["increments attempts"] = function()
  child.lua('_G.progress.mark_solved("testplan", "two-sum")')
  local p = child.lua_get('_G.progress.load("testplan")')
  eq(p["two-sum"].attempts >= 1, true)
end

T["mark_solved"]["records date"] = function()
  child.lua('_G.progress.mark_solved("testplan", "two-sum")')
  local p = child.lua_get('_G.progress.load("testplan")')
  -- Date format: YYYY-MM-DD
  eq(p["two-sum"].last_attempt:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil, true)
end

T["mark_solved"]["multiple calls accumulate attempts"] = function()
  child.lua([[
    _G.progress.mark_solved("testplan", "two-sum")
    _G.progress.mark_solved("testplan", "two-sum")
    _G.progress.mark_solved("testplan", "two-sum")
  ]])
  local p = child.lua_get('_G.progress.load("testplan")')
  eq(p["two-sum"].attempts, 3)
  eq(p["two-sum"].solved, true)
end

T["mark_attempted"] = new_set()

T["mark_attempted"]["increments without solving"] = function()
  child.lua('_G.progress.mark_attempted("testplan", "two-sum")')
  local p = child.lua_get('_G.progress.load("testplan")')
  eq(p["two-sum"].attempts, 1)
  eq(p["two-sum"].solved, nil)
end

T["is_solved"] = new_set()

T["is_solved"]["true after mark_solved"] = function()
  child.lua('_G.progress.mark_solved("testplan", "two-sum")')
  local result = child.lua_get('_G.progress.is_solved("testplan", "two-sum")')
  eq(result, true)
end

T["is_solved"]["false for unknown problem"] = function()
  -- is_solved returns nil (falsy) for unknown slugs via RPC
  local result = child.lua_get('_G.progress.is_solved("testplan", "unknown-slug") == true')
  eq(result, false)
end

T["is_solved"]["false after only mark_attempted"] = function()
  child.lua('_G.progress.mark_attempted("testplan", "two-sum")')
  local result = child.lua_get('_G.progress.is_solved("testplan", "two-sum") == true')
  eq(result, false)
end

T["get_stats"] = new_set()

T["get_stats"]["no progress"] = function()
  child.lua([[
    _G.plan = {
      categories = {
        { problems = {
          { slug = "a" },
          { slug = "b" },
          { slug = "c" },
        }},
      },
    }
    _G.stats = _G.progress.get_stats("testplan", _G.plan)
  ]])
  local stats = child.lua_get("_G.stats")
  eq(stats.total, 3)
  eq(stats.solved, 0)
  eq(stats.attempted, 0)
  eq(stats.unsolved, 3)
end

T["get_stats"]["partial progress"] = function()
  child.lua([[
    _G.progress.mark_solved("testplan", "a")
    _G.progress.mark_attempted("testplan", "b")
    _G.plan = {
      categories = {
        { problems = {
          { slug = "a" },
          { slug = "b" },
          { slug = "c" },
        }},
      },
    }
    _G.stats = _G.progress.get_stats("testplan", _G.plan)
  ]])
  local stats = child.lua_get("_G.stats")
  eq(stats.total, 3)
  eq(stats.solved, 1)
  eq(stats.attempted, 1)
  eq(stats.unsolved, 2)
end

T["get_stats"]["deduplicates cross-category slugs"] = function()
  child.lua([[
    _G.plan = {
      categories = {
        { problems = { { slug = "a" }, { slug = "b" } } },
        { problems = { { slug = "b" }, { slug = "c" } } },
      },
    }
    _G.stats = _G.progress.get_stats("testplan", _G.plan)
  ]])
  local stats = child.lua_get("_G.stats")
  -- "b" appears twice but should only count once
  eq(stats.total, 3)
end

return T
