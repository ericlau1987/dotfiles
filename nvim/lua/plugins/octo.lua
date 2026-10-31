return {
  {
    "pwntester/octo.nvim",
    opts = {
      -- `origin` uses the `github-intentiv` SSH alias (see ~/.ssh/config) so it
      -- picks up ~/.ssh/aml-platform. Map it back to the real host, otherwise
      -- octo shells out to `gh --hostname github-intentiv` and reports
      -- "You are not logged into any accounts on github-intentiv".
      ssh_aliases = { ["github-intentiv"] = "github.com" },
    },
  },
}
