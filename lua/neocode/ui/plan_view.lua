local progress = require("neocode.study.progress")
local utils = require("neocode.utils")
local icons = require("neocode.ui.icons")

local M = {}

local state = {
  bufnr = nil,
  win = nil,
  plans = {},
  summaries = {},
  plan_order = {},
  collapsed = {
    plans = {},
    categories = {},
  },
  line_map = {},
}

local function is_plan_collapsed(slug)
  return state.collapsed.plans[slug] ~= false
end

local function is_category_collapsed(plan_slug, cat_idx)
  local cats = state.collapsed.categories[plan_slug]
  if not cats then return true end
  return cats[cat_idx] ~= false
end

local function difficulty_label(diff)
  if diff == "Easy" then return "Easy  " end
  if diff == "Medium" then return "Medium" end
  if diff == "Hard" then return "Hard  " end
  return diff
end

local function status_icon(plan_slug, problem_slug)
  local ic = icons.get()
  if progress.is_solved(plan_slug, problem_slug) then
    return ic.solved
  end
  local prog = progress.load(plan_slug)
  if prog[problem_slug] and prog[problem_slug].attempts and prog[problem_slug].attempts > 0 then
    return ic.attempted
  end
  return ic.unsolved
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

local function refresh_summaries()
  local study = require("neocode.study")
  for _, slug in ipairs(state.plan_order) do
    state.summaries[slug] = study.get_plan_summary(slug)
  end
end

function M.render()
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local lines = {}
  state.line_map = {}

  -- Compute max title width across all visible problems
  local max_title = 0
  for _, slug in ipairs(state.plan_order) do
    if not is_plan_collapsed(slug) and state.plans[slug] then
      for cat_idx, category in ipairs(state.plans[slug].categories) do
        if not is_category_collapsed(slug, cat_idx) then
          for _, problem in ipairs(category.problems) do
            max_title = math.max(max_title, #problem.title)
          end
        end
      end
    end
  end
  local title_width = math.max(max_title, 30)

  for _, slug in ipairs(state.plan_order) do
    local summary = state.summaries[slug]
    if not summary then goto continue_plan end

    local ic = icons.get()
    local plan_collapsed = is_plan_collapsed(slug)
    local icon = plan_collapsed and ic.folder_closed or ic.folder_open

    -- Plan row
    local plan_line = string.format("  %s %s", icon, summary.name)
    local stats_str = string.format("%d/%d solved", summary.stats.solved, summary.stats.total)
    local pad = math.max(60 - vim.fn.strdisplaywidth(plan_line) - #stats_str, 2)
    plan_line = plan_line .. string.rep(" ", pad) .. stats_str

    table.insert(lines, plan_line)
    table.insert(state.line_map, { type = "plan", slug = slug })

    if not plan_collapsed and state.plans[slug] then
      local plan = state.plans[slug]

      for cat_idx, category in ipairs(plan.categories) do
        local solved, total = category_stats(slug, category)
        local cat_collapsed = is_category_collapsed(slug, cat_idx)
        local cat_icon = cat_collapsed and ic.folder_closed or ic.folder_open

        -- Category row
        local cat_line = string.format("    %s %s", cat_icon, category.name)
        local cat_stats = string.format("%d/%d", solved, total)
        local cat_pad = math.max(60 - vim.fn.strdisplaywidth(cat_line) - #cat_stats, 2)
        cat_line = cat_line .. string.rep(" ", cat_pad) .. cat_stats

        table.insert(lines, cat_line)
        table.insert(state.line_map, { type = "category", plan_slug = slug, cat_idx = cat_idx })

        if not cat_collapsed then
          for _, problem in ipairs(category.problems) do
            local s_icon = status_icon(slug, problem.slug)
            local fmt = "      %s %4d. %-" .. title_width .. "s  %s"
            table.insert(lines, string.format(
              fmt, s_icon, problem.id, problem.title, difficulty_label(problem.difficulty)
            ))
            table.insert(state.line_map, { type = "problem", plan_slug = slug, problem = problem })
          end
        end
      end

      -- Blank separator after expanded plan
      table.insert(lines, "")
      table.insert(state.line_map, { type = "blank" })
    end

    ::continue_plan::
  end

  -- Remove trailing blank line
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
    table.remove(state.line_map)
  end

  vim.bo[state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false

  -- Clamp cursor to valid range
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local cursor = vim.api.nvim_win_get_cursor(state.win)
    local line_count = vim.api.nvim_buf_line_count(state.bufnr)
    if cursor[1] > line_count then
      vim.api.nvim_win_set_cursor(state.win, { line_count, 0 })
    end
  end
end

local function create_buffer(opts)
  opts = opts or {}
  local expand_slug = opts.expand

  local study = require("neocode.study")
  local slugs = study.available_plans()

  state.plans = {}
  state.summaries = {}
  state.plan_order = slugs
  state.collapsed = { plans = {}, categories = {} }
  state.line_map = {}

  for _, slug in ipairs(slugs) do
    state.summaries[slug] = study.get_plan_summary(slug)
  end

  if expand_slug and state.summaries[expand_slug] then
    state.plans[expand_slug] = study.load_plan(expand_slug)
    state.collapsed.plans[expand_slug] = false
    state.collapsed.categories[expand_slug] = {}
  end

  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].swapfile = false
  vim.bo[state.bufnr].filetype = "neocode-plan"

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = state.bufnr,
    callback = function()
      refresh_summaries()
      M.render()
    end,
  })
end

local splash_filetypes = { alpha = true, dashboard = true, starter = true, snacks_dashboard = true }

local function close_splash_screens()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= state.win and vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype
      if splash_filetypes[ft] then
        vim.api.nvim_win_close(win, true)
      end
    end
  end
end

local function open_window()
  local config = require("neocode").config
  local width = config.ui.plan_width or 40

  -- Create a left-side vertical split
  vim.cmd("topleft vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.bufnr)
  vim.api.nvim_win_set_width(state.win, width)

  vim.wo[state.win].number = true
  vim.wo[state.win].relativenumber = true
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].winfixwidth = true

  close_splash_screens()
end

function M.is_open()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

function M.open(opts)
  if M.is_open() then
    vim.api.nvim_set_current_win(state.win)
    return state.bufnr
  end

  -- Create buffer if it doesn't exist
  if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    create_buffer(opts)
  end

  open_window()
  M.render()
  M.set_keymaps()

  return state.bufnr
end

function M.toggle(opts)
  if M.is_open() then
    M.close()
  else
    M.open(opts)
  end
end

function M.set_keymaps()
  local buf = state.bufnr
  local opts = { buffer = buf, silent = true }

  -- Enter: toggle plan/category or open problem
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local entry = state.line_map[line]
    if not entry then return end

    if entry.type == "plan" then
      local slug = entry.slug
      -- Lazy-load plan data on first expand
      if not state.plans[slug] then
        local study = require("neocode.study")
        state.plans[slug] = study.load_plan(slug)
        if not state.plans[slug] then return end
        state.collapsed.categories[slug] = {}
      end
      state.collapsed.plans[slug] = not is_plan_collapsed(slug)
      M.render()

    elseif entry.type == "category" then
      local slug = entry.plan_slug
      state.collapsed.categories[slug] = state.collapsed.categories[slug] or {}
      state.collapsed.categories[slug][entry.cat_idx] = not is_category_collapsed(slug, entry.cat_idx)
      M.render()

    elseif entry.type == "problem" then
      local ui = require("neocode.ui")
      ui.open_problem(entry.problem.slug, entry.plan_slug)
    end
  end, opts)

  -- Tab: toggle fold on plan or category
  vim.keymap.set("n", "<Tab>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local entry = state.line_map[line]
    if not entry then return end

    if entry.type == "plan" then
      local slug = entry.slug
      if not state.plans[slug] then
        local study = require("neocode.study")
        state.plans[slug] = study.load_plan(slug)
        if not state.plans[slug] then return end
        state.collapsed.categories[slug] = {}
      end
      state.collapsed.plans[slug] = not is_plan_collapsed(slug)
      M.render()

    elseif entry.type == "category" then
      local slug = entry.plan_slug
      state.collapsed.categories[slug] = state.collapsed.categories[slug] or {}
      state.collapsed.categories[slug][entry.cat_idx] = not is_category_collapsed(slug, entry.cat_idx)
      M.render()
    end
  end, opts)

  -- n: jump to next unsolved
  vim.keymap.set("n", "n", function()
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    for i = cursor_line + 1, #state.line_map do
      local entry = state.line_map[i]
      if entry and entry.type == "problem" then
        if not progress.is_solved(entry.plan_slug, entry.problem.slug) then
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          return
        end
      end
    end
    -- Wrap around from top
    for i = 1, cursor_line do
      local entry = state.line_map[i]
      if entry and entry.type == "problem" then
        if not progress.is_solved(entry.plan_slug, entry.problem.slug) then
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
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    -- If this is the last window, replace buffer instead of closing
    if #vim.api.nvim_list_wins() == 1 then
      vim.api.nvim_win_set_buf(state.win, vim.api.nvim_create_buf(true, false))
    else
      vim.api.nvim_win_close(state.win, true)
    end
  end
  state.win = nil
end

function M.get_state()
  return state
end

return M
