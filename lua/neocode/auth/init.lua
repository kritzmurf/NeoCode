local api = require("neocode.api")
local queries = require("neocode.api.queries")
local utils = require("neocode.utils")

local M = {}

function M.load_cookies(cookie_path)
  if vim.fn.filereadable(cookie_path) == 0 then
    utils.notify(
      "Cookie file not found: " .. cookie_path .. "\n"
        .. "Create it with two lines:\n"
        .. "  LEETCODE_SESSION=<your session cookie>\n"
        .. "  csrftoken=<your csrf token>",
      vim.log.levels.ERROR
    )
    return false
  end

  local lines = vim.fn.readfile(cookie_path)
  local session, csrf

  for _, line in ipairs(lines) do
    line = vim.trim(line)
    if line ~= "" and not line:match("^#") then
      local key, value = line:match("^([^=]+)=(.+)$")
      if key and value then
        key = vim.trim(key)
        value = vim.trim(value)
        if key == "LEETCODE_SESSION" then
          session = value
        elseif key == "csrftoken" then
          csrf = value
        end
      end
    end
  end

  if not session then
    utils.notify("LEETCODE_SESSION not found in cookie file", vim.log.levels.ERROR)
    return false
  end

  if not csrf then
    utils.notify("csrftoken not found in cookie file", vim.log.levels.ERROR)
    return false
  end

  api.set_credentials(session, csrf)
  return true
end

function M.validate(callback)
  api.graphql(queries.GLOBAL_DATA, {}, function(data, err)
    if err then
      if callback then
        callback(false, nil)
      end
      return
    end

    local user = data and data.userStatus
    if user and user.isSignedIn then
      utils.notify("Authenticated as " .. user.username)
      if callback then
        callback(true, user.username)
      end
    else
      utils.notify("Session invalid or expired. Update your cookies.", vim.log.levels.WARN)
      if callback then
        callback(false, nil)
      end
    end
  end)
end

return M
