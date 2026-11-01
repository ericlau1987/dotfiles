# Harness agent flow

How `/harness <task>` runs in herdr: one lead agent coordinates five helper agents, from design doc to an approved pull request for every sub-task.

Live page: https://claude.ai/artifact/CLW9mE2AZSM3ZagBQh2ojj

## Who talks to whom

Helpers never talk to each other, except the coder and the area specialists it starts. Every other message goes through the lead (`herdr agent prompt` / `herdr agent read`).

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

## Tabs

One herdr workspace per repo, one tab per agent (herdr's own advice: "use tabs to separate views"):

| # | Tab | Panes |
|---|---|---|
| 1 | `lead` | the lead you talk to, plus your nvim sidebar (`prefix+e`) |
| 2 | `architect` | architect |
| 3 | `tracker` | tracker |
| 4 | `coder` | coder, plus a pane for each area specialist it starts (e.g. `rl-coder-devops`) |
| 5 | `reviewer` | reviewer |
| 6 | `pr` | pr |
| 7 | `checks` | test runs; a dev server and its logs when needed |

Agent names carry a task prefix (e.g. `rl-coder`) because herdr names are unique across the whole server.

## Keys (terminal herdr, prefix `ctrl+b`)

Tabs (numbers assume the harness created them in a fresh workspace; other open tabs shift them):

| Keys | Does |
|---|---|
| `ctrl+b` `1` … `7` | jump to lead / architect / tracker / coder / reviewer / pr / checks |
| `ctrl+b` `n` / `p` | next / previous tab |
| `ctrl+b` `g` | go-to picker |

Panes:

| Keys | Does |
|---|---|
| `ctrl+b` `h` / `j` / `k` / `l` | move left / down / up / right |
| `ctrl+b` `tab` | cycle panes |
| `ctrl+b` `z` | zoom one pane full screen (again to restore) |
| `ctrl+b` `x` | close pane (ends what's running in it) |

nvim sidebar (custom bindings in [`herdr/config.toml`](../herdr/config.toml)):

| Keys | Does |
|---|---|
| `ctrl+b` `e` | open / close the nvim sidebar |
| `ctrl+b` `shift+o` | pick a file the agent touched |
| `ctrl+b` `shift+e` | herdr's edit scrollback (moved off `e`) |

`ctrl+b` `?` shows every key.

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

## Decisions

Helpers never ask you directly. They send `ASK` with options and a recommendation to the lead (area specialists go through the coder).
The lead collects them, plus any agent stuck on a permission prompt, and asks you **once** in the lead tab as a numbered
"Decisions needed" list. Independent work keeps going while you decide.

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
| coder | Code, fixes, tests; hands every area to its own `coder-<area>` specialist in a pane (backend, frontend, database, devops) | testing-strategy, debug | Commits, pushes |
| reviewer | Replies `REVIEW CLEAN` or `REVIEW FINDINGS` | code-review (built in) | Edits files |
| pr | Branch, commit, push, PR body with Notion links | deploy-checklist | Force-pushes, merges |

Role files: [roles/](roles/) · Coder subagents: [agents/](agents/)
