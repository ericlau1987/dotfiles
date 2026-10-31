-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-enter insert (terminal) mode when opening or focusing a terminal buffer.
-- This means the Claude Code terminal and any :terminal are ready to type in
-- immediately, without pressing `i` first.
local term_insert = vim.api.nvim_create_augroup("term_auto_insert", { clear = true })
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter", "BufWinEnter", "WinEnter" }, {
  group = term_insert,
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "terminal" then
      vim.cmd("startinsert")
    end
  end,
})
