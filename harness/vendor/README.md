# Vendored skills

Copied from https://github.com/borghei/Claude-Skills at commit 2c12c7e (engineering/), 2026-11-01.
License: MIT + Commons Clause (see LICENSE) — personal use, not for resale.

Not installed as global skills: each harness agent reads only its own, by path
(`~/.claude/skills/harness/vendor/<skill>/SKILL.md`). Scripts are stdlib-only Python; checked for network,
shell and delete calls before vendoring. Run them from the skill folder: `python <skill>/scripts/<tool>.py`.

| Skill | Used by |
|---|---|
| gcp-cloud-architect | architect, coder-devops |
| migration-architect | architect, coder-database |
| observability-designer | architect |
| senior-frontend | coder-frontend |
| a11y-audit | coder-frontend |
| api-design-reviewer | coder-backend |
| database-schema-designer | coder-database |
| docker-development | coder-devops |
| helm-chart-builder | coder-devops |
| senior-devops | coder-devops |
| ci-cd-pipeline-builder | coder-devops |
| devops-workflow-engineer | coder-devops |
| dependency-auditor | coder-devops |
| kubernetes-operator | coder-devops |
| runbook-generator | coder-devops |
| pr-review-expert | reviewer |

To update: re-copy the folders from a newer commit, re-run the script check, update the commit above.
