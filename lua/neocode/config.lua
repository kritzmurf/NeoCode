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
    icons = "auto",
  },
  keys = {
    desc_close = "q",
    desc_to_editor = "<C-l>",
    editor_to_desc = "<C-h>",
    test = "<leader>lct",
    run = "<leader>lcr",
    submit = "<leader>lcs",
  },
  on_close = nil,
}

return M
