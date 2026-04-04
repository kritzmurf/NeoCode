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
        _G.storage = require("neocode.storage")
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

-- ensure_dir
T["ensure_dir"] = new_set()

T["ensure_dir"]["creates nested directories"] = function()
  child.lua('_G.storage.ensure_dir(_G.tmp .. "/a/b/c")')
  local exists = child.lua_get('vim.fn.isdirectory(_G.tmp .. "/a/b/c")')
  eq(exists, 1)
end

-- write_json / read_json
T["json"] = new_set()

T["json"]["round-trip simple table"] = function()
  child.lua([[
    local path = _G.tmp .. "/test.json"
    _G.storage.write_json(path, { key = "value", num = 42 })
    _G.result = _G.storage.read_json(path)
  ]])
  local result = child.lua_get("_G.result")
  eq(result.key, "value")
  eq(result.num, 42)
end

T["json"]["round-trip nested table"] = function()
  child.lua([[
    local path = _G.tmp .. "/nested.json"
    local data = { a = { b = { c = "deep" } }, list = { 1, 2, 3 } }
    _G.storage.write_json(path, data)
    _G.result = _G.storage.read_json(path)
  ]])
  local result = child.lua_get("_G.result")
  eq(result.a.b.c, "deep")
  eq(result.list, { 1, 2, 3 })
end

T["json"]["read non-existent file returns nil"] = function()
  local result = child.lua_get('_G.storage.read_json(_G.tmp .. "/nope.json")')
  eq(result, vim.NIL)
end

T["json"]["read empty file returns nil"] = function()
  child.lua('vim.fn.writefile({}, _G.tmp .. "/empty.json")')
  local result = child.lua_get('_G.storage.read_json(_G.tmp .. "/empty.json")')
  eq(result, vim.NIL)
end

T["json"]["read malformed JSON returns nil"] = function()
  child.lua('vim.fn.writefile({"not json {"}, _G.tmp .. "/bad.json")')
  local result = child.lua_get('_G.storage.read_json(_G.tmp .. "/bad.json")')
  eq(result, vim.NIL)
end

T["json"]["write creates parent directories"] = function()
  child.lua([[
    local path = _G.tmp .. "/sub/dir/data.json"
    _G.ok = _G.storage.write_json(path, { x = 1 })
  ]])
  eq(child.lua_get("_G.ok"), true)
  local exists = child.lua_get('vim.fn.filereadable(_G.tmp .. "/sub/dir/data.json")')
  eq(exists, 1)
end

-- write_file / read_file
T["file"] = new_set()

T["file"]["round-trip text content"] = function()
  child.lua([[
    local path = _G.tmp .. "/test.txt"
    _G.storage.write_file(path, "hello world")
    _G.result = _G.storage.read_file(path)
  ]])
  eq(child.lua_get("_G.result"), "hello world")
end

T["file"]["read non-existent file returns nil"] = function()
  local result = child.lua_get('_G.storage.read_file(_G.tmp .. "/nope.txt")')
  eq(result, vim.NIL)
end

T["file"]["multiline content preserved"] = function()
  child.lua([[
    local path = _G.tmp .. "/multi.txt"
    _G.storage.write_file(path, "line1\nline2\nline3")
    _G.result = _G.storage.read_file(path)
  ]])
  local result = child.lua_get("_G.result")
  eq(result, "line1\nline2\nline3")
end

T["file"]["write creates parent directories"] = function()
  child.lua([[
    local path = _G.tmp .. "/deep/nested/file.txt"
    _G.storage.write_file(path, "content")
  ]])
  local exists = child.lua_get('vim.fn.filereadable(_G.tmp .. "/deep/nested/file.txt")')
  eq(exists, 1)
end

return T
