local M = {}

M.check = function()
  vim.health.start("Neocode")

  -- Check Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10 (vim.system() available)")
  else
    vim.health.error("Neovim >= 0.10 required for vim.system()")
  end

  -- Check curl
  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl found")
  else
    vim.health.error("curl not found (required for LeetCode API)")
  end

  -- Check python3 (for local test runner)
  if vim.fn.executable("python3") == 1 then
    vim.health.ok("python3 found (local test runner)")
  else
    vim.health.warn("python3 not found (needed for local test runner)")
  end

  -- Check xdg-open (optional, for :NeoCode login browser opening)
  if vim.fn.executable("xdg-open") == 1 then
    vim.health.ok("xdg-open found (can open browser during :NeoCode login)")
  else
    vim.health.info("xdg-open not found (you can still open your browser manually)")
  end

  -- Check cookie file
  local config = require("neocode").config
  if vim.fn.filereadable(config.cookie_path) == 1 then
    local lines = vim.fn.readfile(config.cookie_path)
    local has_session = false
    local has_csrf = false
    for _, line in ipairs(lines) do
      if line:match("^LEETCODE_SESSION=") then
        has_session = true
      end
      if line:match("^csrftoken=") then
        has_csrf = true
      end
    end
    if has_session and has_csrf then
      vim.health.ok("Cookie file found with LEETCODE_SESSION and csrftoken")
    else
      local missing = {}
      if not has_session then
        table.insert(missing, "LEETCODE_SESSION")
      end
      if not has_csrf then
        table.insert(missing, "csrftoken")
      end
      vim.health.warn("Cookie file found but missing: " .. table.concat(missing, ", "))
    end
  else
    vim.health.warn(
      "Cookie file not found at: " .. config.cookie_path .. "\n"
        .. "Run :NeoCode login to set up authentication, or create the file manually:\n"
        .. "  LEETCODE_SESSION=<your session cookie>\n"
        .. "  csrftoken=<your csrf token>"
    )
  end

  -- Check storage directory
  local storage_dir = config.storage_dir
  if vim.fn.isdirectory(storage_dir) == 1 then
    vim.health.ok("Storage directory exists: " .. storage_dir)
  else
    vim.health.info("Storage directory will be created at: " .. storage_dir)
  end

  -- Check study plans
  local study = require("neocode.study")
  local available = study.available_plans()
  vim.health.ok("Bundled study plans: " .. table.concat(available, ", "))
end

return M
