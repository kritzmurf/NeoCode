local api = require("neocode.api")
local utils = require("neocode.utils")

local M = {}

local lang_slug_map = {
  python3 = "python3",
  python = "python",
  javascript = "javascript",
  typescript = "typescript",
  cpp = "cpp",
  c = "c",
  java = "java",
  golang = "golang",
  rust = "rust",
  ruby = "ruby",
  swift = "swift",
  kotlin = "kotlin",
  scala = "scala",
  csharp = "csharp",
}

function M.run_remote(slug, lang, code, callback)
  require("neocode.ui.results").show_loading("Running tests on LeetCode...")
  local lang_slug = lang_slug_map[lang] or lang

  local storage = require("neocode.storage")
  local config = require("neocode").config
  local cache_path = config.storage_dir .. "/cache/questions/" .. slug .. ".json"
  local question = storage.read_json(cache_path)

  if not question then
    utils.notify("Problem not cached. Open it first.", vim.log.levels.ERROR)
    if callback then callback(nil, "Not cached") end
    return
  end

  local test_cases = question.exampleTestcaseList or {}
  local path = "/problems/" .. slug .. "/interpret_solution/"
  local body = {
    lang = lang_slug,
    question_id = question.questionId,
    typed_code = code,
    data_input = table.concat(test_cases, "\n"),
  }

  local referer = "Referer: https://" .. (config.domain or "leetcode.com") .. "/problems/" .. slug .. "/"
  api.rest("POST", path, body, { referer }, function(data, err)
    if err then
      if callback then callback(nil, err) end
      return
    end

    if not data or not data.interpret_id then
      utils.notify("Failed to start remote test", vim.log.levels.ERROR)
      if callback then callback(nil, "No interpret_id") end
      return
    end

    M.poll_result(data.interpret_id, callback)
  end)
end

function M.submit(slug, lang, code, callback)
  require("neocode.ui.results").show_loading("Submitting to LeetCode...")
  local lang_slug = lang_slug_map[lang] or lang

  local storage = require("neocode.storage")
  local config = require("neocode").config
  local cache_path = config.storage_dir .. "/cache/questions/" .. slug .. ".json"
  local question = storage.read_json(cache_path)

  if not question then
    utils.notify("Problem not cached. Open it first.", vim.log.levels.ERROR)
    if callback then callback(nil, "Not cached") end
    return
  end

  local path = "/problems/" .. slug .. "/submit/"
  local body = {
    lang = lang_slug,
    question_id = question.questionId,
    typed_code = code,
  }

  local referer = "Referer: https://" .. (config.domain or "leetcode.com") .. "/problems/" .. slug .. "/"
  api.rest("POST", path, body, { referer }, function(data, err)
    if err then
      if callback then callback(nil, err) end
      return
    end

    if not data or not data.submission_id then
      utils.notify("Failed to submit", vim.log.levels.ERROR)
      if callback then callback(nil, "No submission_id") end
      return
    end

    M.poll_result(data.submission_id, callback)
  end)
end

function M.poll_result(id, callback)
  local path = "/submissions/detail/" .. id .. "/check/"

  utils.poll(function(done)
    api.rest("GET", path, nil, nil, function(data, err)
      if err then
        done(true, { state = "ERROR", error = err })
        return
      end

      if data and data.state == "SUCCESS" then
        done(true, data)
      elseif data and data.state == "PENDING" or data.state == "STARTED" then
        done(false, nil)
      else
        done(true, data or { state = "ERROR", error = "Unknown state" })
      end
    end)
  end, 500, 20, function(err, result)
    if err then
      utils.notify(err, vim.log.levels.ERROR)
      if callback then callback(nil, err) end
      return
    end
    if callback then callback(result, nil) end
  end)
end

return M
