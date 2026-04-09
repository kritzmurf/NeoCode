local progress = require("neocode.study.progress")
local utils = require("neocode.utils")

local M = {}

local bundled_plans = {
  blind75 = "neocode.study.plans.blind75",
  neetcode150 = "neocode.study.plans.neetcode150",
  grind75 = "neocode.study.plans.grind75",
}

local custom_plans = {}

function M.register_plan(slug, source)
  custom_plans[slug] = source
end

function M.unregister_plan(slug)
  custom_plans[slug] = nil
end

function M.available_plans()
  local result = {}
  local seen = {}
  for slug, _ in pairs(bundled_plans) do
    table.insert(result, slug)
    seen[slug] = true
  end
  for slug, _ in pairs(custom_plans) do
    if not seen[slug] then
      table.insert(result, slug)
    end
  end
  table.sort(result)
  return result
end

function M.load_plan(slug)
  local source = custom_plans[slug] or bundled_plans[slug]
  if not source then
    utils.notify("Unknown plan: " .. slug .. ". Available: " .. table.concat(M.available_plans(), ", "), vim.log.levels.ERROR)
    return nil
  end

  -- Source is a module path (string) or a plan table directly
  if type(source) == "table" then
    return source
  end

  local ok, plan = pcall(require, source)
  if not ok then
    utils.notify("Failed to load plan: " .. slug, vim.log.levels.ERROR)
    return nil
  end
  return plan
end

function M.get_plan_summary(slug)
  local plan = M.load_plan(slug)
  if not plan then
    return nil
  end

  local stats = progress.get_stats(slug, plan)
  return {
    name = plan.name,
    slug = plan.slug,
    description = plan.description,
    category_count = #plan.categories,
    stats = stats,
  }
end

function M.next_unsolved(slug)
  local plan = M.load_plan(slug)
  if not plan then
    return nil
  end

  for _, category in ipairs(plan.categories) do
    for _, problem in ipairs(category.problems) do
      if not progress.is_solved(slug, problem.slug) then
        return problem
      end
    end
  end

  return nil
end

function M.print_summary(slug)
  local summary = M.get_plan_summary(slug)
  if not summary then
    return
  end

  local lines = {
    summary.name,
    summary.description,
    "",
    string.format(
      "  %d categories, %d problems",
      summary.category_count,
      summary.stats.total
    ),
    string.format(
      "  %d solved, %d attempted, %d remaining",
      summary.stats.solved,
      summary.stats.attempted,
      summary.stats.unsolved
    ),
  }

  local next_problem = M.next_unsolved(slug)
  if next_problem then
    table.insert(lines, "")
    table.insert(lines, string.format(
      "  Next: #%d %s [%s]",
      next_problem.id,
      next_problem.title,
      next_problem.difficulty
    ))
  end

  utils.notify(table.concat(lines, "\n"))
end

return M
