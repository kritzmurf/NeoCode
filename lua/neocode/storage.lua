local M = {}

function M.ensure_dir(path)
  vim.fn.mkdir(path, "p")
end

function M.read_json(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  local lines = vim.fn.readfile(path)
  local content = table.concat(lines, "\n")
  if content == "" then
    return nil
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end
  return data
end

function M.write_json(path, data)
  local dir = vim.fn.fnamemodify(path, ":h")
  M.ensure_dir(dir)
  local ok, json = pcall(vim.json.encode, data)
  if not ok then
    return false
  end
  vim.fn.writefile({ json }, path)
  return true
end

function M.read_file(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  local lines = vim.fn.readfile(path)
  return table.concat(lines, "\n")
end

function M.write_file(path, content)
  local dir = vim.fn.fnamemodify(path, ":h")
  M.ensure_dir(dir)
  local lines = vim.split(content, "\n", { plain = true })
  vim.fn.writefile(lines, path)
end

return M
