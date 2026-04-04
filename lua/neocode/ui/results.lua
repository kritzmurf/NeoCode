local M = {}

local state = {
  bufnr = nil,
  win = nil,
}

function M.show(results)
  M.close()

  local lines = {}
  local passed = 0
  local total = #results

  for _, r in ipairs(results) do
    if r.passed then
      passed = passed + 1
    end
  end

  -- Header
  table.insert(lines, string.format(
    "  Local Test Results    %d/%d passed",
    passed, total
  ))
  table.insert(lines, string.rep("-", 50))
  table.insert(lines, "")

  -- Individual results
  for _, r in ipairs(results) do
    local status = r.passed and "PASS" or "FAIL"
    table.insert(lines, string.format("  Test %d  %s", r.test, status))
    table.insert(lines, string.format("    Input:    %s", tostring(r.input):gsub("\n", ", ")))
    if r.expected ~= nil then
      table.insert(lines, string.format("    Expected: %s", vim.json.encode(r.expected)))
    end
    table.insert(lines, string.format("    Output:   %s", vim.json.encode(r.actual)))
    if r.error then
      table.insert(lines, "    (runtime error)")
    end
    table.insert(lines, "")
  end

  -- Create buffer
  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].filetype = "neocode-results"

  -- Float dimensions
  local width = 60
  local height = math.min(#lines, 25)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Close on q or Esc
  local opts = { buffer = state.bufnr, silent = true }
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
end

function M.show_submission(result, plan_slug)
  M.close()

  local lines = {}
  local status = result.status_msg or "Unknown"

  -- Header
  table.insert(lines, string.format("  LeetCode Submission    %s", status))
  table.insert(lines, string.rep("-", 50))
  table.insert(lines, "")

  if status == "Accepted" then
    table.insert(lines, string.format(
      "  Runtime: %s (beats %.1f%%)",
      result.status_runtime or "?",
      tonumber(result.runtime_percentile) or 0
    ))
    table.insert(lines, string.format(
      "  Memory:  %s (beats %.1f%%)",
      result.status_memory or "?",
      tonumber(result.memory_percentile) or 0
    ))
    table.insert(lines, string.format(
      "  Tests:   %d/%d passed",
      result.total_correct or 0,
      result.total_testcases or 0
    ))

    if plan_slug then
      table.insert(lines, "")
      local study = require("neocode.study")
      local summary = study.get_plan_summary(plan_slug)
      if summary then
        table.insert(lines, string.format(
          "  [%s] %d/%d complete",
          summary.name,
          summary.stats.solved,
          summary.stats.total
        ))
      end
    end
  else
    if result.total_correct and result.total_testcases then
      table.insert(lines, string.format(
        "  Tests:   %d/%d passed",
        result.total_correct,
        result.total_testcases
      ))
    end
    if result.last_testcase then
      table.insert(lines, "")
      table.insert(lines, "  Failed test case:")
      table.insert(lines, string.format("    Input:    %s", tostring(result.last_testcase):gsub("\n", ", ")))
    end
    if result.expected_output then
      table.insert(lines, string.format("    Expected: %s", result.expected_output))
    end
    if result.code_output then
      table.insert(lines, string.format("    Output:   %s", result.code_output))
    end
    if result.runtime_error then
      table.insert(lines, "")
      table.insert(lines, "  Runtime Error:")
      for _, eline in ipairs(vim.split(result.runtime_error, "\n")) do
        table.insert(lines, "    " .. eline)
      end
    end
    if result.compile_error then
      table.insert(lines, "")
      table.insert(lines, "  Compile Error:")
      for _, eline in ipairs(vim.split(result.compile_error, "\n")) do
        table.insert(lines, "    " .. eline)
      end
    end
  end

  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].filetype = "neocode-results"

  local width = 60
  local height = math.min(#lines, 25)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  local opts = { buffer = state.bufnr, silent = true }
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    vim.api.nvim_buf_delete(state.bufnr, { force = true })
  end
  state.win = nil
  state.bufnr = nil
end

return M
