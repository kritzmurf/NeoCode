local storage = require("neocode.storage")

local M = {}

local function progress_path(plan_slug)
  local config = require("neocode").config
  return config.storage_dir .. "/progress/" .. plan_slug .. ".json"
end

function M.load(plan_slug)
  return storage.read_json(progress_path(plan_slug)) or {}
end

function M.save(plan_slug, progress)
  storage.write_json(progress_path(plan_slug), progress)
end

function M.mark_solved(plan_slug, problem_slug)
  local progress = M.load(plan_slug)
  progress[problem_slug] = progress[problem_slug] or {}
  progress[problem_slug].solved = true
  progress[problem_slug].last_attempt = os.date("%Y-%m-%d")
  progress[problem_slug].attempts = (progress[problem_slug].attempts or 0) + 1
  M.save(plan_slug, progress)
end

function M.mark_attempted(plan_slug, problem_slug)
  local progress = M.load(plan_slug)
  progress[problem_slug] = progress[problem_slug] or {}
  progress[problem_slug].last_attempt = os.date("%Y-%m-%d")
  progress[problem_slug].attempts = (progress[problem_slug].attempts or 0) + 1
  M.save(plan_slug, progress)
end

function M.is_solved(plan_slug, problem_slug)
  local progress = M.load(plan_slug)
  return progress[problem_slug] and progress[problem_slug].solved == true
end

function M.get_stats(plan_slug, plan)
  local progress = M.load(plan_slug)
  local total = 0
  local solved = 0
  local attempted = 0
  local seen = {}

  for _, category in ipairs(plan.categories) do
    for _, problem in ipairs(category.problems) do
      if not seen[problem.slug] then
        seen[problem.slug] = true
        total = total + 1
        local p = progress[problem.slug]
        if p then
          if p.solved then
            solved = solved + 1
          elseif p.attempts and p.attempts > 0 then
            attempted = attempted + 1
          end
        end
      end
    end
  end

  return {
    total = total,
    solved = solved,
    attempted = attempted,
    unsolved = total - solved,
  }
end

return M
