local html = require("neocode.ui.html")

local M = {}

function M.open(question, win)
  local lines = {}

  -- Header
  table.insert(lines, string.format(
    "#%s  %s  [%s]",
    question.questionFrontendId,
    question.title,
    question.difficulty
  ))
  table.insert(lines, string.rep("-", 60))
  table.insert(lines, "")

  -- Tags
  if question.topicTags and #question.topicTags > 0 then
    local tags = {}
    for _, tag in ipairs(question.topicTags) do
      table.insert(tags, tag.name)
    end
    table.insert(lines, "Tags: " .. table.concat(tags, ", "))
    table.insert(lines, "")
  end

  -- Description body
  local body = html.to_lines(question.content)
  for _, line in ipairs(body) do
    table.insert(lines, line)
  end

  -- Create scratch buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Buffer options
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "neocode-description"

  -- Display in target window
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_buf(win, bufnr)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  return bufnr
end

return M
