local M = {}

local function keys()
  return require("neocode").config.keys
end

function M.set_description_keymaps(bufnr)
  local k = keys()
  local opts = { buffer = bufnr, silent = true }

  vim.keymap.set("n", k.desc_close, function()
    require("neocode.ui").close()
  end, opts)

  vim.keymap.set("n", k.desc_to_editor, function()
    local ui_state = require("neocode.ui").get_state()
    if ui_state.editor_win and vim.api.nvim_win_is_valid(ui_state.editor_win) then
      vim.api.nvim_set_current_win(ui_state.editor_win)
    end
  end, opts)
end

function M.set_editor_keymaps(bufnr)
  local k = keys()
  local opts = { buffer = bufnr, silent = true }

  vim.keymap.set("n", k.editor_to_desc, function()
    local ui_state = require("neocode.ui").get_state()
    if ui_state.desc_win and vim.api.nvim_win_is_valid(ui_state.desc_win) then
      vim.api.nvim_set_current_win(ui_state.desc_win)
    end
  end, opts)

  vim.keymap.set("n", k.test, function()
    local ui_state = require("neocode.ui").get_state()
    if not ui_state.current_slug then
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
  end, opts)

  vim.keymap.set("n", k.run, function()
    local ui_state = require("neocode.ui").get_state()
    if not ui_state.current_slug then
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
  end, opts)

  vim.keymap.set("n", k.submit, function()
    local ui_state = require("neocode.ui").get_state()
    if not ui_state.current_slug then
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
  end, opts)
end

return M
