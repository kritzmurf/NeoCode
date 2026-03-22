local utils = require("neocode.utils")

local M = {}

local subcommands = {}

subcommands.auth = function()
  local config = require("neocode").config
  local auth = require("neocode.auth")
  local api = require("neocode.api")

  api.set_domain(config.domain)

  if not auth.load_cookies(config.cookie_path) then
    return
  end

  auth.validate()
end

subcommands.plan = function(args)
  local config = require("neocode").config
  local study = require("neocode.study")

  local slug = args[1] or config.active_plan

  if slug == "list" then
    local available = study.available_plans()
    utils.notify("Available plans: " .. table.concat(available, ", "))
    return
  end

  study.print_summary(slug)
end

subcommands.fetch = function(args)
  local slug = args[1]
  if not slug then
    utils.notify("Usage: :NeoCode fetch <problem-slug>", vim.log.levels.WARN)
    return
  end

  local config = require("neocode").config
  local auth = require("neocode.auth")
  local api = require("neocode.api")

  api.set_domain(config.domain)

  if not api.is_authenticated() then
    if not auth.load_cookies(config.cookie_path) then
      return
    end
  end

  local problems = require("neocode.api.problems")
  problems.fetch_question(slug, function(question, err)
    if err then
      return
    end
    utils.notify(string.format(
      "#%s %s [%s]",
      question.questionFrontendId,
      question.title,
      question.difficulty
    ))
  end)
end

function M.dispatch(opts)
  local args = opts.fargs or {}
  local subcmd = table.remove(args, 1)

  if not subcmd then
    utils.notify(
      "Usage: :NeoCode <command>\n"
        .. "  auth     - validate LeetCode session\n"
        .. "  plan     - browse study plans\n"
        .. "  fetch    - fetch a problem by slug",
      vim.log.levels.INFO
    )
    return
  end

  local handler = subcommands[subcmd]
  if not handler then
    utils.notify("Unknown command: " .. subcmd, vim.log.levels.ERROR)
    return
  end

  handler(args)
end

function M.complete(_, cmd_line, _)
  local parts = vim.split(cmd_line, "%s+", { trimempty = true })
  local n = #parts

  if n <= 2 then
    local subcmds = vim.tbl_keys(subcommands)
    table.sort(subcmds)

    if n == 2 then
      return vim.tbl_filter(function(s)
        return s:find(parts[2], 1, true) == 1
      end, subcmds)
    end

    return subcmds
  end

  if parts[2] == "plan" and n <= 3 then
    local study = require("neocode.study")
    local available = study.available_plans()
    table.insert(available, "list")

    if n == 3 then
      return vim.tbl_filter(function(s)
        return s:find(parts[3], 1, true) == 1
      end, available)
    end

    return available
  end

  return {}
end

return M
