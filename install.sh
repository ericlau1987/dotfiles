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
link claude/CLAUDE.md   ~/.claude/CLAUDE.md
link harness/agents     ~/.claude/agents

if command -v claude >/dev/null; then
  claude plugin list 2>/dev/null | grep -q engineering@knowledge-work-plugins || {
    claude plugin marketplace add anthropics/knowledge-work-plugins
    claude plugin install engineering@knowledge-work-plugins
  }
  claude plugin list 2>/dev/null | grep -q ponytail@ponytail || {
    claude plugin marketplace add DietrichGebert/ponytail
    claude plugin install ponytail@ponytail
  }
  claude plugin list 2>/dev/null | grep -q cloudflare@cloudflare || {
    claude plugin marketplace add cloudflare/skills
    claude plugin install cloudflare@cloudflare
  }
else
  echo "claude not installed: skipping engineering, ponytail and cloudflare plugins"
fi

command -v zoe >/dev/null || { command -v brew >/dev/null && brew install furkankly/tap/zoetrope; }

if command -v herdr >/dev/null; then
  herdr integration install claude >/dev/null   # session ids per pane, for zoetrope
  grep -q furkankly.zoetrope ~/.config/herdr/plugins.json 2>/dev/null || herdr plugin install furkankly/zoetrope/herdr-plugin --yes
  # its key (prefix+shift+z) is already in herdr/config.toml
  # reviewr (diff review pane, key prefix+d in herdr/config.toml) needs herdr >= 0.9.3
  hv=$(herdr --version | awk '{print $2}')
  if [ "$(printf '%s\n0.9.3\n' "$hv" | sort -V | head -1)" = "0.9.3" ]; then
    grep -q persiyanov.reviewr ~/.config/herdr/plugins.json 2>/dev/null || herdr plugin install persiyanov/herdr-reviewr --yes
  else
    echo "herdr $hv < 0.9.3: skipping reviewr (brew upgrade herdr, restart herdr, rerun)"
  fi
  grep -q chmarax.herdr-nvim ~/.config/herdr/plugins.json 2>/dev/null || herdr plugin install ChmaraX/herdr-nvim
else
  echo "herdr not installed: brew install herdr, then rerun"
fi
