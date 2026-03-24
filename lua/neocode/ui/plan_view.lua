local progress = require("neocode.study.progress")
local utils = require("neocode.utils")

local M = {}

local state = {
  bufnr = nil,
  plan = nil,
  plan_slug = nil,
  collapsed = {},
  line_map = {},
}

local function difficulty_label(diff)
  if diff == "Easy" then return "Easy  " end
  if diff == "Medium" then return "Medium" end
  if diff == "Hard" then return "Hard  " end
  return diff
end

local function status_icon(plan_slug, problem_slug)
  if progress.is_solved(plan_slug, problem_slug) then
    return "[x]"
  end
  local prog = progress.load(plan_slug)
  if prog[problem_slug] and prog[problem_slug].attempts and prog[problem_slug].attempts > 0 then
    return "[~]"
  end
  return "[ ]"
end

local function category_stats(plan_slug, category)
  local solved = 0
  for _, p in ipairs(category.problems) do
    if progress.is_solved(plan_slug, p.slug) then
      solved = solved + 1
    end
  end
  return solved, #category.problems
end

function M.render()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local plan = state.plan
  local slug = state.plan_slug
  local lines = {}
  state.line_map = {}

  -- Header
  local stats = require("neocode.study").get_plan_summary(slug)
  table.insert(lines, string.format("  %s", plan.name))
  if stats then
    table.insert(lines, string.format(
      "  %d/%d solved",
      stats.stats.solved, stats.stats.total
    ))
  end
  table.insert(lines, string.rep("-", 60))
  table.insert(lines, "")
  for _ = 1, #lines do
    table.insert(state.line_map, { type = "header" })
  end

  -- Categories and problems
  for cat_idx, category in ipairs(plan.categories) do
    local solved, total = category_stats(slug, category)
    local collapsed = state.collapsed[cat_idx]
    local fold_icon = collapsed and ">" or "v"

    table.insert(lines, string.format(
      "  %s %s    %d/%d",
      fold_icon, category.name, solved, total
    ))
    table.insert(state.line_map, { type = "category", index = cat_idx })

    if not collapsed then
      for _, problem in ipairs(category.problems) do
        local icon = status_icon(slug, problem.slug)
        table.insert(lines, string.format(
          "    %s %4d. %-40s %s",
          icon, problem.id, problem.title, difficulty_label(problem.difficulty)
        ))
        table.insert(state.line_map, { type = "problem", data = problem })
      end
      table.insert(lines, "")
      table.insert(state.line_map, { type = "spacer" })
    end
  end

  vim.bo[state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
end

function M.open(plan_slug)
  local study = require("neocode.study")
  local plan = study.load_plan(plan_slug)
  if not plan then
    return
  end

  state.plan = plan
  state.plan_slug = plan_slug
  state.collapsed = {}

  -- Create buffer
  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].swapfile = false
  vim.bo[state.bufnr].filetype = "neocode-plan"

  -- Open in current window
  vim.api.nvim_set_current_win(vim.api.nvim_get_current_win())
  vim.api.nvim_win_set_buf(0, state.bufnr)
  vim.wo[0].number = false
  vim.wo[0].relativenumber = false
  vim.wo[0].signcolumn = "no"
  vim.wo[0].cursorline = true

  M.render()
  M.set_keymaps()

  return state.bufnr
end

function M.set_keymaps()
  local buf = state.bufnr
  local opts = { buffer = buf, silent = true }

  -- Enter: open problem or toggle category
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local entry = state.line_map[line]
    if not entry then return end

    if entry.type == "category" then
      state.collapsed[entry.index] = not state.collapsed[entry.index]
      M.render()
    elseif entry.type == "problem" then
      local ui = require("neocode.ui")
      ui.open_problem(entry.data.slug, state.plan_slug)
    end
  end, opts)

  -- Tab: toggle category fold
  vim.keymap.set("n", "<Tab>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local entry = state.line_map[line]
    if entry and entry.type == "category" then
      state.collapsed[entry.index] = not state.collapsed[entry.index]
      M.render()
    end
  end, opts)

  -- n: jump to next unsolved
  vim.keymap.set("n", "n", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    for i = cursor_line + 1, #state.line_map do
      local entry = state.line_map[i]
      if entry and entry.type == "problem" then
        if not progress.is_solved(state.plan_slug, entry.data.slug) then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    end
    -- Wrap around from top
    for i = 1, cursor_line do
      local entry = state.line_map[i]
      if entry and entry.type == "problem" then
        if not progress.is_solved(state.plan_slug, entry.data.slug) then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    end
    utils.notify("All problems solved!")
  end, opts)

  -- q: close plan view
  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)
end

function M.close()
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    vim.api.nvim_buf_delete(state.bufnr, { force = true })
  end
  state.bufnr = nil
  state.plan = nil
  state.plan_slug = nil
  state.line_map = {}
end

function M.get_state()
  return state
end

return M
