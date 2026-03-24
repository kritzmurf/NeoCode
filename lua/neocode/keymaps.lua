local M = {}

function M.set_description_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- Close workspace
  vim.keymap.set("n", "q", function()
    require("neocode.ui").close()
  end, opts)

  -- Navigate to editor pane
  vim.keymap.set("n", "<C-l>", function()
    local ui_state = require("neocode.ui").get_state()
    if ui_state.editor_win and vim.api.nvim_win_is_valid(ui_state.editor_win) then
      vim.api.nvim_set_current_win(ui_state.editor_win)
    end
  end, opts)
end

function M.set_editor_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- Navigate to description pane
  vim.keymap.set("n", "<C-h>", function()
    local ui_state = require("neocode.ui").get_state()
    if ui_state.desc_win and vim.api.nvim_win_is_valid(ui_state.desc_win) then
      vim.api.nvim_set_current_win(ui_state.desc_win)
    end
  end, opts)

  -- Run local tests
  vim.keymap.set("n", "<leader>lct", function()
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
end

return M
