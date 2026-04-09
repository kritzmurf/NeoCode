local M = {}

M.defaults = {
  lang = "python3",
  domain = "leetcode.com",
  storage_dir = vim.fn.stdpath("data") .. "/neocode",
  cookie_path = vim.fn.stdpath("config") .. "/neocode_cookies",
  active_plan = "blind75",
  ui = {
    description_width = 0.4,
    plan_width = 40,
  },
  keys = {},
}

return M
