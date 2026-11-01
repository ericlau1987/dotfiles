---
name: harness
description: "Control Herdr, a terminal multiplexer for coding agents. Use only when the user explicitly mentions Herdr or asks to use Herdr to inspect or control panes, tabs, workspaces, commands, or another agent. Do not use merely because a task could benefit from a background terminal, delegation, or parallel work. Requires HERDR_ENV=1."
---

# Harness flow

When the user starts a task with `/harness`, run this flow on top of the Herdr rules below.
You are the **lead**: you coordinate, run checks and talk to the user. You never edit code yourself; the `coder` agent does.
The user explicitly wants the tab layout below, so create these tabs even though the Herdr rules default to sibling panes.

Preflight. **Install skills before starting any agent** (agents only load skills at startup):
   `claude plugin list | grep -q engineering@knowledge-work-plugins || (claude plugin marketplace add anthropics/knowledge-work-plugins && claude plugin install engineering@knowledge-work-plugins)`
   `claude plugin list | grep -q ponytail@ponytail || (claude plugin marketplace add DietrichGebert/ponytail && claude plugin install ponytail@ponytail)`
   `claude plugin list | grep -q cloudflare@cloudflare || (claude plugin marketplace add cloudflare/skills && claude plugin install cloudflare@cloudflare)`
   If an install fails, tell the user the exact error and ask whether to continue without those skills.
   The reviewer's `code-review` skill is built into Claude Code and cannot be installed; if missing, the reviewer reads the diff itself.

Layout. One workspace per repo (the one you are in). Keep your own tab as **`lead`** (`herdr tab rename "$HERDR_TAB_ID" lead`).
   Create three more tabs in the same workspace with `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" --label <label> --no-focus`,
   reading each root pane from `.result.root_pane.pane_id`. Never move the user's focus off `lead`.

   | Tab | Panes |
   |---|---|
   | `lead` | you (and the user's nvim sidebar, `prefix+e`) |
   | `agents` | architect (root pane), tracker (split right), coder (split down; the widest pane) |
   | `checks` | a plain shell for test runs (root pane); a second shell split right only when a sub-task needs a dev server or logs |
   | `review` | reviewer (root pane), pr (split right) |

   **Names.** Pick a short task prefix `<p>` (2–4 lowercase letters from the task, e.g. `rl` for rate limiting) and name agents
   `<p>-architect`, `<p>-tracker`, `<p>-coder`, `<p>-reviewer`, `<p>-pr`. Agent names are unique across the whole herdr server,
   so the prefix keeps two harness runs in different repos from clashing. If a name is taken, pick another prefix.
   Below, `architect`, `coder` etc. mean these prefixed names.

0. **Architect first.** In the `agents` tab root pane, start a `claude` agent named `<p>-architect`. Prompt it:
   `Read ~/.claude/skills/harness/roles/architect.md and follow it. design <the user's task, repo path, branch>`
   - `DESIGN SKIP` → go to step 1 without a doc.
   - `DESIGN READY <path>` → **design gate:** show the user the doc path, summary and open questions, and wait.
     Comments → architect `revise <comments>` → show again. Approved → architect: `the user approved; set Status: Approved`.
     Do not start step 1 until the design is approved.
1. **Tracker next.** Split the architect pane right and start a `claude` agent named `<p>-tracker`. Prompt it:
   `Read ~/.claude/skills/harness/roles/tracker.md and follow it. plan <the user's task, repo path, branch> [design <doc path>]`
   Wait for its `TRACKER PLAN`. If it replies `TRACKER ASK`, relay the question to the user.
2. **Coder, reviewer, pr.** Split the `agents` tab down and start `<p>-coder` (`roles/coder.md`). In the `review` tab root pane start
   `<p>-reviewer` (`roles/reviewer.md`), then split it right and start `<p>-pr` (`roles/pr.md`). Prompt each once:
   `Read ~/.claude/skills/harness/roles/<role>.md and follow it. Reply READY.`
   Keep the same coder and reviewer for the whole task so they remember earlier rounds.
   The pr agent is the only one that commits, pushes and opens PRs.
3. **Find the checks once.** Read the repo's CI (`.github/workflows/*.yml`) and scripts (`package.json`, `pyproject.toml`,
   `justfile`, `Makefile`) and list the commands CI runs: lint, typecheck, test, build. Run only those for the parts
   the sub-task touches, in the `checks` tab root pane (a plain shell, not an agent). Reuse it.
   If a sub-task needs the app running, split the checks pane right, start the dev server there, and read its logs from that pane.
4. **Loop each sub-task**, in the order the tracker's plan gives:
   1. **Code.** Coder: `code <sub-task URL> <goal and plan from the tracker> [design <doc path>]`. Wait for `CODE DONE`
      (on `CODE ASK`, answer it or ask the user). Then tracker: `update <sub-task URL> started: <what you changed>`.
   2. **Test.** In the checks pane: `herdr pane run <pane> "<checks>"`, then `herdr pane wait-output` and `pane read`.
      Match on something every run prints (e.g. a final exit marker: append `; echo "CHECKS_EXIT=$?"` and wait for `CHECKS_EXIT=`),
      not on success text, so a failing run does not time out.
      If anything fails, coder: `fix attempt <n> <the failing output>` (n counts failed runs for this sub-task), then test again. A test failure does not count as a review round.
      After 3 failed test runs in a row, tracker: `update <sub-task URL> blocked: tests failing: <error>`, and ask the user.
   3. **Review.** Only once tests pass. Reviewer: `review <scope>` (e.g. `uncommitted`, or the commit range).
   4. **If `REVIEW FINDINGS`:** tracker: `update <sub-task URL> review round <n>: <the numbered findings>`.
      Coder: `fix <the numbered findings>`. Pass any `disputed` items to the reviewer in the next round. Then go back to step 2 (test, then review round n+1).
   5. **If `REVIEW CLEAN`:** pr agent: `ship <sub-task URL> <parent URL> <one-line summary> [design <doc path>] tests: <commands → result> review: <n> rounds, clean`.
      Wait for `PR OK <url>`; on `PR ASK`, fix it or ask the user. Then tracker: `update <sub-task URL> review clean, tests pass, PR <url>`.
      Do not commit or push yourself.
   6. **Manual review gate.** Stop and ask the user to review the PR. Show: the PR URL, the Notion sub-task URL,
      a 3-line summary of the change, what checks ran, and "the reviewer's notes are in the `review` tab".
      If `herdr notification` can alert the user, send one. Then wait. Do not start the next sub-task until the user answers.
      - **Approved** → tracker: `update <sub-task URL> manual review approved PR <url>`, then the next sub-task.
      - **Changes requested** → tracker: `update <sub-task URL> manual review: <the user's comments>`.
        Treat the comments as findings: coder `fix <the user's comments>` → test → review → pr agent `ship` (updates the same PR) → this gate again.
      Approval does not mean merge. Never merge unless the user says so.
   7. **Stop after 3 review rounds** that still have findings. Tracker: `update <sub-task URL> blocked after 3 review rounds: <open findings>`,
      then show the user the open findings and ask how to proceed. Do not start the next sub-task.
   Never skip tests, review or the manual review gate, and never mark a sub-task done yourself; the tracker sets status.
   If any `--wait` times out or stalls, read the agent before re-sending: a timeout does not prove the prompt was not delivered.
   For long agent replies, ask the agent to write them to a Markdown file and reply with the path.
5. When everything is done, tell the user the final tracker status, and ask before closing the `agents`, `checks` and `review` tabs you created.

# Herdr

Herdr organizes terminals into workspaces, tabs, and panes, recognizes coding agents running inside panes, and exposes the current session through the `herdr` CLI.

Before issuing any control command, verify that this agent is running inside a Herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, say that you are not running inside Herdr and stop. Do not inspect or control the focused Herdr session from outside Herdr.

When the check passes, the `herdr` binary in `PATH` talks to the current session. Use it to inspect neighboring work, create terminal layout, start agents and commands, read output, and wait for state changes.

## Learn the current CLI

The installed binary is the authority for command syntax. Start with:

```bash
herdr --help
```

Then print the relevant command group by running the group without a subcommand:

```bash
herdr agent
herdr pane
herdr workspace
herdr tab
herdr worktree
herdr terminal
herdr notification
herdr integration
herdr session
herdr machine
```

Do not run bare `herdr` for discovery; it launches or attaches the TUI. Do not probe a mutating nested command by omitting arguments. Commands such as `herdr workspace create` are valid with defaults and will execute.

Most control commands return JSON. Read identifiers and state from those responses instead of predicting them.

## Understand layout, panes, and agents

Choose the primitive that matches the job:

- Workspace, tab, and pane topology organize terminal locations.
- Pane commands control raw terminals, shells, tests, servers, input, and output.
- Agent commands control the recognized coding agent currently occupying a pane.

A pane exists whether or not it contains an agent. `agent start` requires an existing available shell pane and never creates, splits, or moves layout. Use pane commands for ordinary processes. Use agent commands when Herdr must validate agent identity or interpret `idle`, `working`, `blocked`, `done`, and `unknown` lifecycle states.

Agent commands accept either a unique live agent name or the pane ID currently hosting that agent. They do not accept terminal IDs or bare agent-kind labels. Names must match `[a-z][a-z0-9_-]{0,31}` and be unique among live agents. A name follows the current pane occupant and is cleared when that agent exits, is released, or is replaced.

`idle` and `done` both mean the agent is ready for input. The CLI/API uses the server's seen state to distinguish them; explicit focus commands mark the target seen, while reads do not. Each TUI client tracks viewed completions independently, so its Done badge can differ from the CLI or another client's badge. `blocked` means Herdr recognized an approval or question UI. `unknown` means an agent is present but Herdr cannot classify it confidently; it does not prove completion.

## Use IDs and caller context

Public IDs are opaque stable handles:

- workspace: `w1`
- tab: `w1:t1`
- pane: `w1:p1`

Closed tab and pane IDs are not reused. A pane moved into another workspace receives a new workspace-qualified pane ID. After `pane move`, continue with `.result.move_result.pane.pane_id` or the live agent name. The old value is reported as `.result.move_result.previous_pane_id`; only the moved process's inherited caller context keeps resolving that old ID, so do not use it as a general agent target.

Herdr injects the caller's context into each managed pane:

```bash
printf '%s\n' "$HERDR_WORKSPACE_ID" "$HERDR_TAB_ID" "$HERDR_PANE_ID"
```

Prefer `--current` when a pane command should target the calling pane. An omitted `pane split` target uses the calling pane when `HERDR_PANE_ID` is available, otherwise the focused pane. Other commands may use the UI-focused pane, which can belong to the user or another client.

Discover live state with:

```bash
herdr workspace list
herdr tab list --workspace "$HERDR_WORKSPACE_ID"
herdr pane current --current
herdr pane list --workspace "$HERDR_WORKSPACE_ID"
herdr agent list
```

Creation responses expose the IDs to use next. `workspace create` returns `.result.workspace`, `.result.tab`, and `.result.root_pane`. `tab create` returns `.result.tab` and `.result.root_pane`. `pane split` returns the new pane as `.result.pane`.

IDs and live agent names are scoped to one server. Two saved SSH machines can both have `w1:p1` or an agent named `reviewer`. Selecting a machine in the TUI does not retarget commands running in your pane: without `--machine`, they still use the inherited session and socket context.

To control a saved SSH machine, use the same global prefix for discovery and every later command:

```bash
herdr --machine <label-or-id> agent list
herdr --machine <label-or-id> pane list
herdr --machine <label-or-id> agent prompt <remote-agent-name> "Reply with your current status." --wait --timeout 120000
```

The selector must be an enabled saved profile ID or a unique, case-sensitive label, not an arbitrary SSH hostname. Commands use that profile's remote session without an open TUI. Do not combine `--machine` with `--session` or `--remote`. Discover IDs on that machine; inherited local IDs and `--current` do not identify remote panes.

Both installations must support machine API forwarding, and the remote server must already be running and API-compatible. Forwarding never installs, starts, or restarts a server and never falls back to Local. Local configuration, session management, installation commands, and interactive attachment are not forwarded. Remote worktree paths must be absolute, `~`, or start with `~/`; plugin link paths must be absolute. A connection failure does not prove a mutation was not applied: inspect remote state before retrying.

`herdr machine list` lists saved connection profiles, not a cross-machine pane inventory; add `--json` for scripts. Only add, remove, enable, or disable profiles when the user asks. Removing a profile disconnects the client but does not stop remote sessions. Adding a machine uses the remote default session unless `--remote-session` is explicitly supplied. Setup asks before stopping an incompatible server and defaults to No; do not approve replacement without the user's consent. Experimental handoff is not part of `machine add`.

## Start and coordinate an agent

Default to a sibling pane in the current tab and the current working directory. Do not create a workspace, tab, worktree, or different cwd unless the user explicitly requests that topology or location.

Honor a direction requested by the user. Otherwise inspect the caller pane:

```bash
herdr pane layout --pane "$HERDR_PANE_ID"
```

Split a wide pane to the right and a narrow or tall pane down. Avoid repeated same-direction splits that create unusably narrow columns or short rows. Keep the user's focus in the calling pane and explicitly preserve the caller's working directory:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
```

Replace `right` with `down` when appropriate. Read the new pane ID from `.result.pane.pane_id`.

An available shell pane must be at its interactive prompt, with the shell itself in the foreground and no foreground command, editor, or agent running. Start a supported agent in that pane with a useful unique name:

```bash
herdr agent start reviewer --kind codex --pane <returned-pane-id>
```

Use the kind requested by the user. Run `herdr agent` to inspect the installed kind list and options. Pass native agent arguments only after `--`:

```bash
herdr agent start reviewer --kind codex --pane <returned-pane-id> -- <agent-args...>
```

A successful `agent start` returns only after Herdr detects the expected agent in the same pane and considers it ready for interactive input. If the agent is blocked during startup, the command returns `agent_not_ready` immediately but keeps the name available for `agent read` and `agent send-keys`. Wait until the agent becomes idle before prompting it. Startup defaults to a 30-second timeout.

Submit work through the agent surface:

```bash
herdr agent prompt reviewer "Review the current diff and report only actionable findings." --wait --timeout 120000
```

`agent prompt` honors the pane's live bracketed-paste mode and sends text followed by encoded Enter as one ordered submission. It reports successful submission only after both have been written; that alone does not prove the agent started a turn. For Codex on Windows, Herdr sends a paste boundary before Enter so submission does not depend on prompt size. It rejects an agent already waiting at an approval or question dialog with `agent_blocked` before sending any input. Inspect the blocked UI and ask the user before answering it. For normal agent work, `--wait` is enough: it waits for the first settled `idle`, `done`, or `blocked` state. Do not repeat those defaults with `--until`.

With `--wait`, a prompt sent from a non-working state must produce observed `working` or `blocked` activity. After submission, Herdr waits up to five seconds for that activity; unrelated `idle`, `done`, or session changes do not satisfy this gate. It returns `agent_prompt_stalled` if no activity is observed, or `timeout` if the caller's timeout expires first. The caller timeout includes submission time. Without a timeout, the settled-state wait is indefinite after activity is observed. This wait tracks lifecycle state, not an individual turn; if the agent is already working, completion of the active turn may satisfy it.

Use `--until` only for a state-specific workflow, such as waiting for an already-running agent to request input:

```bash
herdr agent wait reviewer --until blocked --timeout 120000
```

Without `--until`, standalone `agent wait` uses the same settled-state defaults as `agent prompt --wait`.

Use logical keys for interactive agent UI controls:

```bash
herdr agent send-keys reviewer esc
herdr agent send-keys reviewer ctrl+c
```

Herdr validates all keys before writing any bytes. Read the result through the resolved agent:

```bash
herdr agent get reviewer
herdr agent read reviewer --source recent-unwrapped --lines 120
```

If a wait fails or returns `blocked`, inspect `agent get` and `agent read` before deciding what input to send. A timeout or stalled response does not prove the prompt was never delivered; do not blindly submit it again. Use the pane surface only when raw terminal control is intentional.

## Run an ordinary command in another pane

Create a sibling pane with the same geometry rule, preserve the caller's working directory, and keep user focus unchanged:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
```

Read the new pane ID from `.result.pane.pane_id`, then run and inspect the command:

```bash
herdr pane run <returned-pane-id> "just test"
herdr pane wait-output <returned-pane-id> --match "test result" --timeout 120000
herdr pane read <returned-pane-id> --source recent-unwrapped --lines 120
```

`pane run` atomically sends command text and Enter. `pane wait-output` searches the selected snapshot immediately, so output that already exists can match. Use `--match <text>` for a literal substring or `--regex <pattern>` for a Rust regular expression. Omitting `--timeout` allows an indefinite wait.

Use the read source that matches the task:

- `visible`: the currently rendered viewport.
- `recent`: recent rendered output, including soft wraps.
- `recent-unwrapped`: recent output with soft wraps joined; prefer it for logs and transcripts.
- `detection`: the plain-text bottom-buffer snapshot used for agent detection.

Use `--format ansi` when colors and terminal styling are evidence. Otherwise use text.

`--lines` asks Herdr for more rows from the pane's available screen and host scrollback. Alternate-screen rows do not enter ordinary host scrollback. For supported idle agents, Herdr can collect application-owned history and restore the viewport afterward, but not every application or response can be recovered this way.

If a larger recent read still does not reveal the completed response, ask the agent to write it as Markdown in a temporary directory and reply only with the file path, then read that file on the same machine. Use this only as a fallback; do not request file output in the initial prompt.

## Safety and coordination rules

- Use `--no-focus` for background work unless the user asked to switch context.
- Use `--current`, an explicit pane ID, or a unique agent name. Do not rely on another client's focused pane.
- Parse IDs from JSON responses. Do not derive them from sidebar order or examples.
- Do not close workspaces, tabs, panes, or sessions you did not create unless the user explicitly asked. `workspace close --group` closes the primary workspace and its linked worktree workspaces; never add it merely to bypass `workspace_group_close_required`.
- Use `--trust-repository` only after the user has verified the repository. It grants per-request Git trust; it is not a routine retry for a failed worktree command.
- Client and server versions can differ after an update. Check `herdr status` before relying on new server features. A missing method is not permission to stop or upgrade a server.
- Never run `herdr server stop` from an active session unless the user explicitly intends to stop the server and its pane processes.
- Never kill the main Herdr process. Use named test sessions for experiments that need an isolated server.
- CLI server errors are JSON on stderr with exit status 1. CLI syntax errors exit with status 2.
