return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
    end,
    keys = {
      { "<leader>ji", "<cmd>MoltenInit<cr>", desc = "Init Jupyter kernel" },
      { "<leader>jl", "<cmd>MoltenEvaluateLine<cr>", desc = "Evaluate line" },
      { "<leader>jc", "<cmd>MoltenReevaluateCell<cr>", desc = "Re-evaluate cell" },
      { "<leader>jd", "<cmd>MoltenDelete<cr>", desc = "Delete cell output" },
      { "<leader>jo", "<cmd>MoltenShowOutput<cr>", desc = "Show output" },
      {
        "<leader>jv",
        ":<C-u>MoltenEvaluateVisual<cr>",
        mode = "v",
        desc = "Evaluate visual selection",
      },
    },
  },
  {
    "GCBallesteros/jupytext.nvim",
    config = function()
      require("jupytext").setup({
        style = "hydrogen",
        output_extension = "auto",
        force_ft = "python",
      })
    end,
  },
}
