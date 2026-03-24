local utils = require("neocode.utils")
local storage = require("neocode.storage")

local M = {}

local lang_runners = {
  python3 = "neocode.runner.languages.python",
  python = "neocode.runner.languages.python",
}

local function parse_expected_outputs(content)
  if not content then
    return {}
  end
  local outputs = {}
  for output in content:gmatch("<strong>Output:</strong>%s*([^\n<]+)") do
    table.insert(outputs, vim.trim(output))
  end
  return outputs
end

local function load_question(slug)
  local config = require("neocode").config
  local cache_path = config.storage_dir .. "/cache/questions/" .. slug .. ".json"
  return storage.read_json(cache_path)
end

function M.run(slug, lang_slug, callback)
  local question = load_question(slug)
  if not question then
    utils.notify("Problem not cached. Open it first.", vim.log.levels.ERROR)
    return
  end

  local runner_module = lang_runners[lang_slug]
  if not runner_module then
    utils.notify("No local runner for: " .. lang_slug, vim.log.levels.ERROR)
    return
  end

  local runner = require(runner_module)
  local editor = require("neocode.ui.editor")
  local solution_path = editor.get_solution_path(slug, lang_slug)

  if vim.fn.filereadable(solution_path) == 0 then
    utils.notify("No solution file found. Open the problem first.", vim.log.levels.ERROR)
    return
  end

  -- Parse metadata
  local ok, meta = pcall(vim.json.decode, question.metaData)
  if not ok then
    utils.notify("Failed to parse problem metadata", vim.log.levels.ERROR)
    return
  end

  local test_cases = question.exampleTestcaseList or {}
  local expected_outputs = parse_expected_outputs(question.content)

  -- Generate and run harness
  local harness_path = runner.generate_harness(solution_path, meta, test_cases, expected_outputs)
  local cmd = runner.run_command(harness_path)

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      -- Clean up temp file
      os.remove(harness_path)

      if obj.code ~= 0 and (not obj.stdout or obj.stdout == "") then
        utils.notify("Test runner error:\n" .. (obj.stderr or "unknown error"), vim.log.levels.ERROR)
        if callback then
          callback(nil, obj.stderr)
        end
        return
      end

      -- Parse JSON output lines
      local results = {}
      for line in obj.stdout:gmatch("[^\n]+") do
        local parse_ok, result = pcall(vim.json.decode, line)
        if parse_ok then
          table.insert(results, result)
        end
      end

      if #results == 0 then
        utils.notify("No test results. Check your solution for syntax errors.\n" .. (obj.stderr or ""), vim.log.levels.WARN)
        if callback then
          callback(nil, "No results")
        end
        return
      end

      if callback then
        callback(results, nil)
      end
    end)
  end)
end

return M
