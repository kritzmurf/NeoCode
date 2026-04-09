local M = {}

M.config = {}

function M.setup(opts)
  local defaults = require("neocode.config").defaults
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  local storage = require("neocode.storage")
  storage.ensure_dir(M.config.storage_dir)

  -- Register user-provided custom plans
  if M.config.plans then
    local study = require("neocode.study")
    for slug, source in pairs(M.config.plans) do
      study.register_plan(slug, source)
    end
  end
end

return M
