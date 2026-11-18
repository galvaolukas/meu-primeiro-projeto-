---
name: impl-peer-review
description: >-
  Independent peer review of an implemented change (the diff) via a fresh subagent: a reviewer
  with no memory of the implementation session pressure-tests the diff and writes one scoped
  Markdown findings artifact for user-directed remediation. Project-agnostic — any repo or
  language; auto-discovers project rule files and the verify command. Use after an implementation
  pass (feature, bug fix, refactor) when the user explicitly asks for an external review of the
  diff before commit or PR. Do not use for spec/TechSpec review — use spec-peer-review.
trigger: explicit
argument-hint: "[--files p1,p2] [--context p1,p2] [--base ref] [--staged] [--out dir] [--verify cmd] [--model <model>]"
---

# Implementation Peer Review

An independent reviewer pressure-tests an implementation diff. This skill runs that peer review
only on explicit user request after an implementation pass; its scope is the diff plus any
`--context` files the user names, decoupled from any task-tracking system. **The runtime's native
subagent facility is the review engine**: each round is one dispatch of a fresh, isolated agent
(e.g. the `Agent` tool in Claude Code, run in the foreground so its result is available before
continuing) that has no access to this session's reasoning — only the composed prompt and the
files it reads itself. The findings file the reviewer writes is the sole source of truth — treat
its returned summary as operational evidence only.

## Bundled files

Resolve every `scripts/<name>` or `references/<name>` path relative to this `SKILL.md`'s directory
(`<skill-dir>`). All bundled files are read-only — read or run them, never edit them during a round.

## Asking the user

When a step tells you to ask the user (which findings to incorporate, whether to run another
round), use the runtime's interactive question tool — the one that presents a question and pauses
until the user answers (e.g. AskUserQuestion). If the runtime has no such tool, present the
question as the complete assistant message and stop; answer it yourself only after the user replies.

## Inputs

All inputs are optional. Defaults make the common path `impl-peer-review` with no arguments.

- `--files <p1,p2,...>` — scope the review to explicit paths instead of the full branch diff.
- `--context <p1,p2,...>` — additional context files to feed the reviewer (a spec, ADR, design
  doc, RFC, README). The skill never assumes any of these exist.
- `--base <git-ref>` — base ref for the diff. Defaults to `main`. Use `--base HEAD~N` for a
  narrower scope.
- `--staged` — review staged changes only (`git diff --staged`) instead of a branch diff.
- `--out <dir>` — output directory for round artifacts. See Output Directory.
- `--verify <cmd>` — the verification command (build/tests) used as both the readiness gate and
  the post-remediation gate. When omitted, auto-detect per `references/readiness-checks.md`; if
  none resolves, ask the user.
- `--model <name>` (default `opus`): the model to run the reviewer subagent with, when the
  runtime's subagent facility exposes a model override (e.g. the `Agent` tool's `model`
  parameter). When the runtime has no such override, ignore this input and use the runtime's
  default subagent model.

## Output Directory

Resolve `<out>` in this order:

1. `--out` if provided.
2. Otherwise, if the repo exposes an unambiguous `.docs/tasks/<slug>/` layout for the current
   work, use that task's `qa/` directory: `.docs/tasks/<slug>/qa/`.
3. Otherwise, default to `.peer-reviews/<UTC-timestamp-YYYYMMDDTHHMMSSZ>/` at the repository root.

Create the directory if it does not exist. Every artifact is versioned with `-roundN`; never
overwrite a prior round — increment to the next round instead.

## Findings Artifact

Each round has exactly one authoritative findings file: `<out>/impl-review-findings-roundN.md`.
The reviewer writes that file and no other. If the target path is missing, ambiguous, unwritable,
or outside `<out>`, the reviewer refuses and stops — no stdout fallback.

The findings format — frontmatter, section headings, and per-item fields — is defined in
`references/impl-review-prompt.md` and enforced by `scripts/validate-findings.sh`.

## Procedures

**Step 0: Verify an independent subagent facility is available**

Confirm the runtime exposes a native read-only-capable subagent dispatch mechanism (e.g. the
`Agent` tool in Claude Code). If none exists, abort with a one-line message stating that this
skill needs an isolated subagent to preserve reviewer independence — do not simulate the review
by reasoning about the diff yourself in the current session; that defeats the point of an
independent pass.

**Step 1: Validate Input and Compute Scope**

1. Confirm the user has just completed (or paused) the implementation pass and explicitly asked to
   review the current state. Do not run review rounds during active editing.
2. Resolve the diff scope:
   - If `--files` is provided, verify each path exists and limit the diff to those paths.
   - If `--staged` is provided, use `git diff --staged`.
   - Otherwise run `git diff <base>...HEAD --name-only` (default `<base>` is `main`) to compute the
     changed file set. If the diff is empty, abort and tell the user there is nothing to review.
3. Resolve `<out>` (see Output Directory) and create it if needed.
4. Resolve the verification command (`--verify`, else auto-detect, else ask the user).
5. **STOP. Read `references/readiness-checks.md` in full before running the review.** Verify every
   readiness marker passes; the markers and their auto-detect order live in that file. If any
   marker fails, report the failed markers and abort — external review on a broken or incomplete
   change wastes credit and produces noise.
6. Determine the next review round number by listing existing
   `<out>/impl-review-findings-round*.md` and `<out>/impl-review-summary-round*.md` files. Start at
   `round1` when none exist.

**Step 2: Compose the Review Prompt**

1. **STOP. Read `references/impl-review-prompt.md` in full before composing the prompt.** It is the
   canonical executable reviewer prompt template; substitute its placeholders verbatim and do not
   paraphrase it. The assembled prompt must start with the reviewer instructions, not with a
   Markdown wrapper describing the template.
2. Capture the diff payload:
   - Run `git diff <base>...HEAD -- <changed-files>` (or `git diff --staged -- <changed-files>` for
     `--staged`) and write the raw patch to `<out>/impl-review-diff-roundN.patch`.
   - Run `git log --oneline <base>...HEAD -- <changed-files>` and capture the commit list (empty
     string if `--staged`).
3. Define the round artifact paths under `<out>/`: `impl-review-findings-roundN.md`,
   `impl-review-events-roundN.jsonl` (event log), `impl-review-result-roundN.err` (stderr),
   `impl-review-status-before-roundN.txt`, `impl-review-status-after-roundN.txt`, and
   `impl-review-validation-error-roundN.md` (only when needed).
4. Discover existing project rule files to populate `{project_rules}`: root-level `CLAUDE.md`,
   `AGENTS.md`, `.cursor/rules/*`, `.cursorrules`, `CONTRIBUTING.md`; nested `CLAUDE.md`/`AGENTS.md`
   in the directories the diff touches; and any project memory/directive docs (e.g. `docs/_memory/`,
   standing directives, lessons indexes). Nested and memory rules hold the load-bearing invariants
   root-only discovery misses.
5. Substitute the placeholders in the prompt template:
   - `{scope_summary}` — one-paragraph description of what was implemented. Derive from the user's
     brief, the commit messages, or — if `--context` was passed — the linked spec/PRD.
   - `{context_paths}` — newline-separated repo-root paths from `--context`, or `none`. When the
     reviewed diff implements a task from a spec directory (e.g. `.docs/tasks/<slug>/`,
     `specs/<name>/`, `docs/rfcs/<name>/`), also include that spec's contract-bearing sibling
     artifacts here even when the user passed no `--context` (see Guardrails: Contract parity).
   - `{project_rules}` — newline-separated discovered rule-file paths, or `none`.
   - `{changed_files}` — newline-separated repo-root paths.
   - `{diff_path}` — repo-root path to the patch file from step 2.
   - `{commit_list}` — captured `git log --oneline` output, or `none` if `--staged`.
   - `{findings_path}` — exact absolute path to `<out>/impl-review-findings-roundN.md`.
   - `{round}` — numeric review round `N`.
6. Write the assembled prompt to `<out>/impl-review-prompt-roundN.md`.

**Step 3: Execute the Independent Review**

1. Capture the pre-run status snapshot:

   ```bash
   git status --short > <out>/impl-review-status-before-roundN.txt
   ```

2. Dispatch the runtime's native subagent facility (e.g. the `Agent` tool, `run_in_background:
   false` so the result is available before continuing) with the full assembled prompt from
   `<out>/impl-review-prompt-roundN.md` as its task, and `model` set to the resolved `--model`
   when the facility supports a model override. The subagent must be a fresh dispatch with no
   access to this session's implementation history — it reads only the diff, `{context_paths}`,
   and `{project_rules}` named in the prompt.
3. Capture the post-run status snapshot:

   ```bash
   git status --short > <out>/impl-review-status-after-roundN.txt
   ```

4. If the subagent dispatch errors or is refused, fail loudly — no silent retry, and no
   substitute of reasoning about the diff yourself in its place.
5. Require the findings target file to exist after the subagent returns. If missing, the round is
   invalid even when the subagent reported success — write `impl-review-validation-error-roundN.md`
   and ask whether to rerun.

**Step 4: Validate and Summarize Findings**

1. Run the bundled read-only validator:

   ```bash
   bash <skill-dir>/scripts/validate-findings.sh --kind implementation --round N --path <out>/impl-review-findings-roundN.md
   ```

2. Manually inspect the findings file and verify the semantic contract:
   - every finding has a real file path/line or an explicit reason it is not applicable;
   - blockers include a rationale tied to project rules or architecture constraints;
   - no `TBD`, placeholder text, invented paths, or stdout-only findings;
   - when spec contract artifacts were passed in `{context_paths}`, the findings explicitly assess
     contract parity field by field (see Guardrails: Contract parity) — a `SHIP` verdict with no
     contract-parity assessment is an invalid round;
   - comparing the pre/post status snapshots shows no changes outside the expected review
     artifact/log paths.
3. If validation fails, write `<out>/impl-review-validation-error-roundN.md` with the failed
   checks, command, exit status, and artifact paths. Do not summarize the round as `SHIP`.
4. Write `<out>/impl-review-summary-roundN.md` from the validated findings file with: the verdict
   (`SHIP` / `FIX_BEFORE_SHIP` / `REWORK`); one-line rationale per blocker; the risks list; the
   nits list; files most likely affected by remediation; and the operational artifact paths.
5. Present a concise user-facing summary: verdict, blocker/risk/nit counts, main themes, and the
   artifact paths written for the round.
6. Hold all source, test, config, doc, and commit edits until Step 5.

**Step 5: User-Directed Remediation**

1. Ask the user which findings to incorporate:
   - A) all blockers
   - B) selected blockers/risks/nits
   - C) nothing — keep the review as a record only
   - D) manual edits before any remediation
2. Apply only the findings the user selected.
3. Re-run the resolved verification command after applying any code change. If it fails, fix the
   new failure or surface it back to the user before declaring remediation done.
4. Record the remediation decision in `<out>/impl-review-remediation-roundN.md`, listing:
   incorporated items with the new commit/diff range; deferred items; files changed; and the
   verification command and outcome with a timestamp.
5. Show the user what changed and what remains deferred. Commit or push only on explicit user
   instruction.

**Step 6: Optional Additional Rounds**

1. Ask whether the user wants another peer-review round against the updated code or wants to stop
   with the current state.
2. Run further rounds only when the user explicitly requests one: re-run from Step 2 against the
   new diff and create a fresh `roundN+1` artifact set in the same `<out>` directory.

## Guardrails

**Contract parity.** For a spec-workflow diff, engineering quality alone can never earn `SHIP`.
When the diff implements a task from a spec directory (`.docs/tasks/<slug>/`, `specs/<name>/`,
`docs/rfcs/<name>/`), the reviewer must receive that spec's contract-bearing sibling artifacts —
canonical example documents, input/schema tables, QA seeds, test contracts, parity maps — and
assess the deliverable against them field by field. A round whose `{context_paths}` omitted those
artifacts is invalid; a task-file paraphrase is never a sufficient contract source. Real incident:
seven rounds reached `SHIP` on a deliverable that contradicted the spec's canonical example document
because no round ever received it.

**Credit once.** The independent subagent dispatch is the only place this skill spends external
review effort. Run it once per round; rerun only when the round is explicitly invalid and the
user asks for it.
