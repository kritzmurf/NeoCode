local M = {}

function M.notify(msg, level)
  vim.notify("neocode: " .. msg, level or vim.log.levels.INFO)
end

function M.read_buf_content(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n")
end

function M.poll(check_fn, interval_ms, max_attempts, on_done)
  local attempts = 0
  local function tick()
    attempts = attempts + 1
    check_fn(function(finished, result)
      if finished then
        on_done(nil, result)
      elseif attempts >= max_attempts then
        on_done("Timed out waiting for result", nil)
      else
        vim.defer_fn(tick, interval_ms)
      end
    end)
  end
  tick()
end

return M
