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
        package.loaded["neocode.ui.editor"] = nil
        require("neocode").setup({ storage_dir = _G.tmp })
        _G.editor = require("neocode.ui.editor")
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

T["get_solution_path"] = new_set()

T["get_solution_path"]["python3 produces .py extension"] = function()
  local path = child.lua_get('_G.editor.get_solution_path("two-sum", "python3")')
  eq(path:match("%.py$") ~= nil, true)
end

T["get_solution_path"]["javascript produces .js extension"] = function()
  local path = child.lua_get('_G.editor.get_solution_path("two-sum", "javascript")')
  eq(path:match("%.js$") ~= nil, true)
end

T["get_solution_path"]["cpp produces .cpp extension"] = function()
  local path = child.lua_get('_G.editor.get_solution_path("two-sum", "cpp")')
  eq(path:match("%.cpp$") ~= nil, true)
end

T["get_solution_path"]["golang produces .go extension"] = function()
  local path = child.lua_get('_G.editor.get_solution_path("two-sum", "golang")')
  eq(path:match("%.go$") ~= nil, true)
end

T["get_solution_path"]["unknown lang defaults to .txt"] = function()
  local path = child.lua_get('_G.editor.get_solution_path("two-sum", "brainfuck")')
  eq(path:match("%.txt$") ~= nil, true)
end

T["get_solution_path"]["dashes in slug become underscores in filename"] = function()
  local path = child.lua_get('_G.editor.get_solution_path("two-sum", "python3")')
  eq(path:match("two_sum%.py$") ~= nil, true)
end

T["get_solution_path"]["path includes slug directory"] = function()
  local path = child.lua_get('_G.editor.get_solution_path("two-sum", "python3")')
  eq(path:match("/solutions/two%-sum/") ~= nil, true)
end

return T
