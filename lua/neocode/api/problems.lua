local api = require("neocode.api")
local queries = require("neocode.api.queries")
local storage = require("neocode.storage")
local utils = require("neocode.utils")

local M = {}

function M.fetch_question(slug, callback)
  local config = require("neocode").config
  local cache_path = config.storage_dir .. "/cache/questions/" .. slug .. ".json"

  local cached = storage.read_json(cache_path)
  if cached then
    if callback then
      callback(cached, nil)
    end
    return
  end

  utils.notify("Fetching " .. slug .. "...")
  api.graphql(queries.QUESTION_DATA, { titleSlug = slug }, function(data, err)
    if err then
      if callback then
        callback(nil, err)
      end
      return
    end

    local question = data and data.question
    if not question then
      utils.notify("Problem not found: " .. slug, vim.log.levels.ERROR)
      if callback then
        callback(nil, "Problem not found")
      end
      return
    end

    storage.write_json(cache_path, question)

    if callback then
      callback(question, nil)
    end
  end)
end

function M.fetch_question_list(filters, callback)
  api.graphql(queries.PROBLEMSET_QUESTION_LIST, {
    categorySlug = "",
    limit = filters and filters.limit or 50,
    skip = filters and filters.skip or 0,
    filters = filters and filters.filters or {},
  }, function(data, err)
    if err then
      if callback then
        callback(nil, err)
      end
      return
    end

    local result = data and data.problemsetQuestionList
    if callback then
      callback(result, nil)
    end
  end)
end

function M.fetch_daily(callback)
  api.graphql(queries.DAILY_QUESTION, {}, function(data, err)
    if err then
      if callback then
        callback(nil, err)
      end
      return
    end

    local daily = data and data.activeDailyCodingChallengeQuestion
    if callback then
      callback(daily, nil)
    end
  end)
end

return M
