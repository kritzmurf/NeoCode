local M = {}

--- Create a temporary directory and return its path.
function M.make_tmp_dir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, "p")
  return path
end

--- Remove a temporary directory.
function M.cleanup_tmp_dir(path)
  vim.fn.delete(path, "rf")
end

--- Write a file into a directory.
function M.write_tmp_file(dir, name, content)
  local filepath = dir .. "/" .. name
  local parent = vim.fn.fnamemodify(filepath, ":h")
  vim.fn.mkdir(parent, "p")
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), filepath)
  return filepath
end

--- Set up neocode in a child Neovim with a temp storage dir.
--- Returns the tmp_dir so the caller can clean it up.
function M.setup_neocode(child, opts)
  local tmp_dir = child.lua_get("vim.fn.tempname()")
  child.lua("vim.fn.mkdir(..., 'p')", { tmp_dir })

  local setup_opts = vim.tbl_deep_extend("force", {
    storage_dir = tmp_dir,
    cookie_path = tmp_dir .. "/cookies",
  }, opts or {})

  child.lua("require('neocode').setup(...)", { setup_opts })
  return tmp_dir
end

return M
