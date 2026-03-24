local storage = require("neocode.storage")
local utils = require("neocode.utils")

local M = {}

local lang_map = {
  python3 = { ext = "py", filetype = "python" },
  python = { ext = "py", filetype = "python" },
  javascript = { ext = "js", filetype = "javascript" },
  typescript = { ext = "ts", filetype = "typescript" },
  cpp = { ext = "cpp", filetype = "cpp" },
  c = { ext = "c", filetype = "c" },
  java = { ext = "java", filetype = "java" },
  golang = { ext = "go", filetype = "go" },
  rust = { ext = "rs", filetype = "rust" },
  ruby = { ext = "rb", filetype = "ruby" },
  swift = { ext = "swift", filetype = "swift" },
  kotlin = { ext = "kt", filetype = "kotlin" },
  scala = { ext = "scala", filetype = "scala" },
  csharp = { ext = "cs", filetype = "cs" },
}

local function get_lang_info(lang_slug)
  return lang_map[lang_slug] or { ext = "txt", filetype = "text" }
end

local function find_snippet(question, lang_slug)
  if not question.codeSnippets then
    return nil
  end
  for _, snippet in ipairs(question.codeSnippets) do
    if snippet.langSlug == lang_slug then
      return snippet.code
    end
  end
  return nil
end

local function solution_path(slug, lang_slug)
  local config = require("neocode").config
  local info = get_lang_info(lang_slug)
  local file_slug = slug:gsub("-", "_")
  return config.storage_dir .. "/solutions/" .. slug .. "/" .. file_slug .. "." .. info.ext
end

function M.open(question, lang_slug, win)
  local path = solution_path(question.titleSlug, lang_slug)
  local info = get_lang_info(lang_slug)
  local is_new = vim.fn.filereadable(path) == 0

  if is_new then
    local snippet = find_snippet(question, lang_slug)
    if snippet then
      storage.write_file(path, snippet)
    else
      utils.notify("No code snippet for language: " .. lang_slug, vim.log.levels.WARN)
      storage.write_file(path, "")
    end
  end

  vim.api.nvim_set_current_win(win)
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].filetype = info.filetype

  return bufnr
end

function M.get_solution_path(slug, lang_slug)
  return solution_path(slug, lang_slug)
end

return M
