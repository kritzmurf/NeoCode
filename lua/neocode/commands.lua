local utils = require("neocode.utils")

local M = {}

local subcommands = {}

subcommands.login = function()
  local config = require("neocode").config
  local login = require("neocode.auth.login")
  login.run(config)
end

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
  local slug = args[1]

  if slug == "list" then
    local study = require("neocode.study")
    local available = study.available_plans()
    utils.notify("Available plans: " .. table.concat(available, ", "))
    return
  end

  local plan_view = require("neocode.ui.plan_view")
  plan_view.toggle({ expand = slug })
end

subcommands.open = function(args)
  local slug = args[1]
  if not slug then
    utils.notify("Usage: :Neocode open <problem-slug>", vim.log.levels.WARN)
    return
  end
  local ui = require("neocode.ui")
  ui.open_problem(slug)
end

subcommands.close = function()
  require("neocode.ui").close()
end

subcommands.next = function()
  local config = require("neocode").config
  local study = require("neocode.study")
  local problem = study.next_unsolved(config.active_plan)
  if not problem then
    utils.notify("All problems solved in " .. config.active_plan .. "!")
    return
  end
  local ui = require("neocode.ui")
  ui.open_problem(problem.slug, config.active_plan)
end

subcommands.test = function()
  local ui_state = require("neocode.ui").get_state()
  if not ui_state.current_slug then
    utils.notify("No problem open. Use :Neocode open <slug> first.", vim.log.levels.WARN)
    return
  end
  local config = require("neocode").config
  local runner = require("neocode.runner")
  local results_ui = require("neocode.ui.results")
  runner.run(ui_state.current_slug, config.lang, function(results, _err)
    if results then
      results_ui.show(results)
    end
  end)
end

subcommands.run = function()
  local ui_state = require("neocode.ui").get_state()
  if not ui_state.current_slug then
    utils.notify("No problem open. Use :Neocode open <slug> first.", vim.log.levels.WARN)
    return
  end
  local config = require("neocode").config
  local submit = require("neocode.api.submit")
  local results_ui = require("neocode.ui.results")
  local editor = require("neocode.ui.editor")
  local code = require("neocode.storage").read_file(
    editor.get_solution_path(ui_state.current_slug, config.lang)
  )
  if not code then return end
  submit.run_remote(ui_state.current_slug, config.lang, code, function(result, _err)
    if result then
      results_ui.show_submission(result, ui_state.current_plan)
    end
  end)
end

subcommands.submit = function()
  local ui_state = require("neocode.ui").get_state()
  if not ui_state.current_slug then
    utils.notify("No problem open. Use :Neocode open <slug> first.", vim.log.levels.WARN)
    return
  end
  local config = require("neocode").config
  local submit = require("neocode.api.submit")
  local results_ui = require("neocode.ui.results")
  local progress = require("neocode.study.progress")
  local editor = require("neocode.ui.editor")
  local code = require("neocode.storage").read_file(
    editor.get_solution_path(ui_state.current_slug, config.lang)
  )
  if not code then return end
  submit.submit(ui_state.current_slug, config.lang, code, function(result, _err)
    if result then
      if result.status_msg == "Accepted" and ui_state.current_plan then
        progress.mark_solved(ui_state.current_plan, ui_state.current_slug)
      elseif ui_state.current_plan then
        progress.mark_attempted(ui_state.current_plan, ui_state.current_slug)
      end
      results_ui.show_submission(result, ui_state.current_plan)
    end
  end)
end

subcommands.progress = function()
  local config = require("neocode").config
  local study = require("neocode.study")
  local summary = study.get_plan_summary(config.active_plan)
  if not summary then return end
  utils.notify(string.format(
    "%s: %d/%d solved (%d%%)",
    summary.name,
    summary.stats.solved,
    summary.stats.total,
    summary.stats.total > 0 and math.floor(summary.stats.solved / summary.stats.total * 100) or 0
  ))
end

subcommands.lang = function(args)
  local lang = args[1]
  if not lang then
    local config = require("neocode").config
    utils.notify("Current language: " .. config.lang)
    return
  end
  require("neocode").config.lang = lang
  utils.notify("Language set to: " .. lang)
end

subcommands.fetch = function(args)
  local slug = args[1]
  if not slug then
    utils.notify("Usage: :Neocode fetch <problem-slug>", vim.log.levels.WARN)
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
      "Usage: :Neocode <command>\n"
        .. "  login    - interactive login to LeetCode\n"
        .. "  auth     - validate LeetCode session\n"
        .. "  plan     - browse study plans\n"
        .. "  open     - open a problem workspace\n"
        .. "  close    - close workspace\n"
        .. "  next     - next unsolved problem\n"
        .. "  test     - run local tests\n"
        .. "  run      - run on LeetCode server\n"
        .. "  submit   - submit to LeetCode\n"
        .. "  progress - show plan progress\n"
        .. "  lang     - show/set language\n"
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

  if parts[2] == "open" and n <= 3 then
    local config = require("neocode").config
    local cache_dir = config.storage_dir .. "/cache/questions"
    local files = vim.fn.glob(cache_dir .. "/*.json", false, true)
    local slugs = {}
    for _, f in ipairs(files) do
      table.insert(slugs, vim.fn.fnamemodify(f, ":t:r"))
    end
    if n == 3 then
      return vim.tbl_filter(function(s)
        return s:find(parts[3], 1, true) == 1
      end, slugs)
    end
    return slugs
  end

  return {}
end

return M
