# Harness agent flow

How `/harness <task>` runs in herdr: one lead agent coordinates five helper agents, from design doc to an approved pull request for every sub-task.

Live page: https://claude.ai/artifact/CLW9mE2AZSM3ZagBQh2ojj

## Who talks to whom

Helpers never talk to each other. Every message goes through the lead (`herdr agent prompt` / `herdr agent read`).

```mermaid
flowchart TB
  YOU(["You"])
  LEAD["LEAD<br/>preflight · runs checks · decides next step"]
  YOU <-->|"/harness · design gate · PR gate"| LEAD
  LEAD --> ARCH["architect"] --> D[("docs/design/")]
  LEAD --> TRK["tracker"] --> N[("Notion Task Board")]
  LEAD --> COD["coder"] --> C[("code")]
  LEAD --> REV["reviewer"] --> R[("reads diff")]
  LEAD --> PR["pr"] --> G[("GitHub PR")]
  LEAD --> CHK["checks pane<br/>lint · test · build"]
```

## The whole flow

```mermaid
flowchart TD
  START(["You: /harness task"]) --> PRE{"LEAD: engineering<br/>plugin installed?"}
  PRE -->|no| INST["LEAD installs it"] --> A
  PRE -->|yes| A["LEAD → architect: design<br/>prior art · 2–3 approaches · recommendation"]
  A -->|DESIGN SKIP| T
  A -->|DESIGN READY| DG{{"⏸ You: design gate"}}
  DG -->|comments / go with B| REVISE["LEAD → architect: revise"] --> DG
  DG -->|approved| T["LEAD → tracker: plan<br/>Notion parent tasks + sub-tasks"]
  T --> SETUP["LEAD starts coder, reviewer, pr<br/>reads CI · opens checks pane"]
  SETUP --> CODE

  subgraph LOOP["For each sub-task"]
    CODE["LEAD → coder: code<br/>tracker: started → In Progress"] --> TEST{"LEAD runs checks"}
    TEST -->|fail| FIXT["LEAD → coder: fix attempt n<br/>/debug from n ≥ 2"] --> TEST
    TEST -->|pass| RV{"LEAD → reviewer<br/>/code-review high"}
    RV -->|FINDINGS| FIXR["LEAD → tracker: log round<br/>LEAD → coder: fix"] --> TEST
    RV -->|CLEAN| SHIP["LEAD → pr: ship<br/>branch · commit · push · PR with Notion links"]
    SHIP --> TL["LEAD → tracker: PR field<br/>status → Review"]
    TL --> PG{{"⏸ You: PR gate"}}
    PG -->|changes| FIXP["LEAD → tracker: log comments<br/>LEAD → coder: fix"] --> TEST
  end

  PG -->|approved, more sub-tasks| CODE
  PG -->|approved, last one| END(["LEAD reports final status<br/>never merges unless you say so"])
```

Stops early and asks you after 3 failed test runs, or 3 review rounds that still have findings.

## Where you step in

| Gate | What you do |
|---|---|
| Design gate | Approve, comment, or pick another approach ("go with B") |
| PR gate | Once per sub-task: approve, or request changes and the same PR is updated |
| Stuck | 3 failed test runs, or 3 review rounds still finding issues |

## The agents

| Agent | Job | Skills | Never |
|---|---|---|---|
| lead | Coordinates, runs checks, talks to you | harness ([SKILL.md](SKILL.md)) | Writes code, commits, edits Notion |
| architect | Design doc in `docs/design/` | system-design, architecture | Writes code or Notion |
| tracker | Notion tasks, status, PR field | Notion | Deletes tasks, writes code |
| coder | Code, fixes, tests; splits multi-area work across `coder-<area>` subagents (github-actions, cloudflare, backend, frontend, database, cloud, devops) | testing-strategy, debug | Commits, pushes |
| reviewer | Replies `REVIEW CLEAN` or `REVIEW FINDINGS` | code-review (built in) | Edits files |
| pr | Branch, commit, push, PR body with Notion links | deploy-checklist | Force-pushes, merges |

Role files: [roles/](roles/) · Coder subagents: [agents/](agents/)
