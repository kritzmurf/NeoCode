local M = {}

M.config = {}

function M.setup(opts)
  local defaults = require("neocode.config").defaults
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  local storage = require("neocode.storage")
  storage.ensure_dir(M.config.storage_dir)
end

return M
