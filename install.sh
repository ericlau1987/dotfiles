#!/usr/bin/env bash
# Links dotfiles into place. Existing real files are kept as <path>.bak.
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"

link() { # link <repo path> <target>
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] && [ ! -L "$2" ]; then mv "$2" "$2.bak"; echo "backed up $2 -> $2.bak"; fi
  ln -sfn "$D/$1" "$2"
  echo "linked $2"
}

link herdr/config.toml ~/.config/herdr/config.toml
link nvim              ~/.config/nvim
link harness           ~/.claude/skills/harness
link harness/agents     ~/.claude/agents

if command -v claude >/dev/null; then
  claude plugin list 2>/dev/null | grep -q engineering@knowledge-work-plugins || {
    claude plugin marketplace add anthropics/knowledge-work-plugins
    claude plugin install engineering@knowledge-work-plugins
  }
else
  echo "claude not installed: skipping engineering plugin"
fi

if command -v herdr >/dev/null; then
  grep -q chmarax.herdr-nvim ~/.config/herdr/plugins.json 2>/dev/null || herdr plugin install ChmaraX/herdr-nvim
else
  echo "herdr not installed: brew install herdr, then rerun"
fi
