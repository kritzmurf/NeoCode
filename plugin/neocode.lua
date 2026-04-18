if vim.g.loaded_neocode then
  return
end
vim.g.loaded_neocode = true

if vim.fn.has("nvim-0.10") ~= 1 then
  vim.notify("neocode requires Neovim >= 0.10", vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command("Neocode", function(opts)
  require("neocode.commands").dispatch(opts)
end, {
  nargs = "*",
  complete = function(arg_lead, cmd_line, cursor_pos)
    return require("neocode.commands").complete(arg_lead, cmd_line, cursor_pos)
  end,
  desc = "neocode - LeetCode study system",
})
