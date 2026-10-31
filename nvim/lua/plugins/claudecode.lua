-- Override for lazyvim.plugins.extras.ai.claudecode
-- Works around a crash on window toggle: Snacks' terminal registers a
-- buf-scoped BufEnter -> vim.cmd.startinsert() handler. claudecode.nvim
-- recreates the split with nvim_win_set_buf(), which fires that handler
-- inside textlock; startinsert throws E565 and Snacks' _on wrapper
-- re-raises it. Disabling auto_insert removes the offending handler.

local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local shell = is_windows and "powershell -NoLogo" or "zsh"

-- One float style shared by Claude Code + snacks terminals
local float_win = {
  position = "float",
  border = "rounded",
  width = 0.9,
  height = 0.9,
  wo = { winblend = 15 },
}

return {
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        auto_insert = false,
        provider = "snacks",
        snacks_win_opts = float_win,
      },
    },
    init = function()
      -- Workaround: Claude's terminal renders blank/black until the pty is
      -- resized. The window opens at a stale/animated size (mini-animate grows
      -- it after the job's pty was already sized), so Claude's TUI paints into
      -- the wrong grid. Nudge the window width once the terminal is up to force
      -- a pty resize + repaint. Deferred past mini-animate's animation window.
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function(ev)
          if not vim.api.nvim_buf_get_name(ev.buf):lower():find("claude") then
            return
          end
          vim.defer_fn(function()
            local win = vim.fn.bufwinid(ev.buf)
            if win == -1 or not vim.api.nvim_win_is_valid(win) then
              return
            end
            local w = vim.api.nvim_win_get_width(win)
            pcall(vim.api.nvim_win_set_width, win, w + 1)
            pcall(vim.api.nvim_win_set_width, win, w)
          end, 350)
        end,
      })
    end,
  },

  -- snacks: default floating terminal + a <C-/> toggle bound to your shell
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = vim.tbl_extend("force", { style = "terminal" }, float_win),
      },
    },
    keys = {
      {
        "<c-/>",
        function()
          Snacks.terminal.toggle(shell, { win = float_win })
        end,
        mode = { "n", "t" },
        desc = "Toggle Floating Terminal",
      },
    },
  },
}
