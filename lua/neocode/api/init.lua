local utils = require("neocode.utils")

local M = {}

local state = {
  session = nil,
  csrf = nil,
  domain = nil,
}

function M.set_credentials(session, csrf)
  state.session = session
  state.csrf = csrf
end

function M.set_domain(domain)
  state.domain = domain
end

function M.is_authenticated()
  return state.session ~= nil and state.csrf ~= nil
end

function M.graphql(query, variables, callback)
  if not M.is_authenticated() then
    utils.notify("Not authenticated. Run :neocode auth first.", vim.log.levels.ERROR)
    return
  end

  local domain = state.domain or "leetcode.com"
  local url = "https://" .. domain .. "/graphql/"

  local body = vim.json.encode({
    query = query,
    variables = variables or {},
  })

  local cmd = {
    "curl", "-s",
    "-X", "POST",
    "-H", "Content-Type: application/json",
    "-H", "Cookie: LEETCODE_SESSION=" .. state.session .. "; csrftoken=" .. state.csrf,
    "-H", "X-Csrftoken: " .. state.csrf,
    "-H", "Referer: https://" .. domain,
    "-H", "Origin: https://" .. domain,
    "--data-raw", body,
    url,
  }

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        utils.notify("HTTP error: " .. (obj.stderr or "unknown"), vim.log.levels.ERROR)
        if callback then
          callback(nil, "HTTP error")
        end
        return
      end

      local ok, data = pcall(vim.json.decode, obj.stdout)
      if not ok then
        utils.notify("Failed to parse API response", vim.log.levels.ERROR)
        if callback then
          callback(nil, "JSON parse error")
        end
        return
      end

      if data.errors then
        local msg = data.errors[1] and data.errors[1].message or "Unknown API error"
        utils.notify("API error: " .. msg, vim.log.levels.ERROR)
        if callback then
          callback(nil, msg)
        end
        return
      end

      if callback then
        callback(data.data, nil)
      end
    end)
  end)
end

function M.rest(method, path, body, extra_headers, callback)
  if not M.is_authenticated() then
    utils.notify("Not authenticated. Run :neocode auth first.", vim.log.levels.ERROR)
    return
  end

  local domain = state.domain or "leetcode.com"
  local url = "https://" .. domain .. path

  local cmd = {
    "curl", "-s",
    "-X", method,
    "-H", "Content-Type: application/json",
    "-H", "Cookie: LEETCODE_SESSION=" .. state.session .. "; csrftoken=" .. state.csrf,
    "-H", "X-Csrftoken: " .. state.csrf,
    "-H", "Referer: https://" .. domain .. path,
    "-H", "Origin: https://" .. domain,
  }

  if extra_headers then
    for _, h in ipairs(extra_headers) do
      table.insert(cmd, "-H")
      table.insert(cmd, h)
    end
  end

  if body then
    table.insert(cmd, "--data-raw")
    table.insert(cmd, type(body) == "string" and body or vim.json.encode(body))
  end

  table.insert(cmd, url)

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        utils.notify("HTTP error: " .. (obj.stderr or "unknown"), vim.log.levels.ERROR)
        if callback then
          callback(nil, "HTTP error")
        end
        return
      end

      local ok, data = pcall(vim.json.decode, obj.stdout)
      if not ok then
        if callback then
          callback(obj.stdout, nil)
        end
        return
      end

      if callback then
        callback(data, nil)
      end
    end)
  end)
end

return M
