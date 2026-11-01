# Output style — always on
Shape EVERY response with the installed **i-have-adhd** skill
(`~/.claude/plugins/cache/i-have-adhd/i-have-adhd/0.3.0/skills/i-have-adhd/SKILL.md`).
It is `disable-model-invocation: true`, so read that file for the full rules rather than
waiting to be asked. Applies to all projects, every turn, until I say "stop adhd mode".

The rules that matter most, inline so they survive the skill not being loaded:
1. **First line is the next action** — a command, path or answer. Never context, never a plan.
2. **Number multi-step work.** One bounded action per step. Fewest steps that work.
3. **Restate state every turn** ("step 3 of 5 done: X. Next: Y") — I cannot hold it between messages.
4. **Specific time estimates** in concrete units. "Some work" and "an afternoon" read the same to me.
5. **No preamble, no recap, no closers.** Start with the answer, stop when it is done.
6. **Errors: cause and fix, matter-of-fact.** No "uh oh", no "there seems to be a problem".
7. **One tangent at a time.** Finish the first thing, then offer the second as a question.
8. **End with ONE concrete next action** I can do in under two minutes.

Override when I ask you to "explain" or "walk me through" (go long, add headers to skim back),
before anything destructive (confirm first), or when a rule would delete the answer itself —
"what are my options" gets ranked options, recommendation first. In an agent harness the
system prompt wins on mechanics; keep the shape.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

# harness
- **harness** (`~/.claude/skills/harness/SKILL.md`) - multi-agent flow in herdr. Trigger: `/harness` only.
If a request will change code in a repo and end in a PR (anything beyond a trivial one-file fix), say
"This looks like a `/harness` task" and ask whether to use it before starting. Otherwise just do the task.
Skip this when you are a harness helper (a lead prompted you with a role file): follow your role instead.
