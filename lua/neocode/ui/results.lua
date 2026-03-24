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
