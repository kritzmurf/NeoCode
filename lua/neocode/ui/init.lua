local utils = require("neocode.utils")

local M = {}

local state = {
  desc_bufnr = nil,
  editor_bufnr = nil,
  desc_win = nil,
  editor_win = nil,
  current_slug = nil,
  current_plan = nil,
}

local function ensure_auth(callback)
  local api = require("neocode.api")
  local config = require("neocode").config

  if api.is_authenticated() then
    callback()
    return
  end

  local auth = require("neocode.auth")
  api.set_domain(config.domain)

  if not auth.load_cookies(config.cookie_path) then
    return
  end

  callback()
end

function M.open_problem(slug, plan_slug)
  ensure_auth(function()
    local problems = require("neocode.api.problems")
    problems.fetch_question(slug, function(question, err)
      if err or not question or type(question) ~= "table" then
        utils.notify("Could not load problem: " .. (err or slug), vim.log.levels.ERROR)
        return
      end
      M.open_workspace(question, plan_slug)
    end)
  end)
end

function M.open_workspace(question, plan_slug)
  local config = require("neocode").config
  local description = require("neocode.ui.description")
  local editor = require("neocode.ui.editor")
  local keymaps = require("neocode.keymaps")

  -- Close existing workspace if open
  M.close()

  state.current_slug = question.titleSlug
  state.current_plan = plan_slug

  -- Create left split for description
  vim.cmd("vsplit")
  state.desc_win = vim.api.nvim_get_current_win()

  -- The original window becomes the editor (right side, respects splitright)
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    if w ~= state.desc_win then
      state.editor_win = w
      break
    end
  end

  -- Set description width
  local total_width = vim.o.columns
  local desc_width = math.floor(total_width * config.ui.description_width)
  vim.api.nvim_win_set_width(state.desc_win, desc_width)

  -- Open description in left pane
  state.desc_bufnr = description.open(question, state.desc_win)

  -- Open editor in right pane
  state.editor_bufnr = editor.open(question, config.lang, state.editor_win)

  -- Set buffer-local keymaps
  keymaps.set_description_keymaps(state.desc_bufnr)
  keymaps.set_editor_keymaps(state.editor_bufnr)

  -- Focus the editor
  vim.api.nvim_set_current_win(state.editor_win)
end

function M.close()
  if state.desc_bufnr and vim.api.nvim_buf_is_valid(state.desc_bufnr) then
    vim.api.nvim_buf_delete(state.desc_bufnr, { force = true })
  end
  if state.desc_win and vim.api.nvim_win_is_valid(state.desc_win) then
    vim.api.nvim_win_close(state.desc_win, true)
  end
  state.desc_bufnr = nil
  state.editor_bufnr = nil
  state.desc_win = nil
  state.editor_win = nil
  state.current_slug = nil
  state.current_plan = nil
end

function M.get_state()
  return state
end

return M
