---
name: commit
description: "Create consistently formatted Git commits while recording human and AI-agent responsibility: preserve the user's configured identity as committer, assign the integrating model and reasoning effort as author, format subjects by action and optional scope, and use conventional Git trailers for distinct contributing agents. Use when creating commits with agent attribution, documenting multi-agent contributions, amending agent metadata, or rewriting recent commits to add or correct author, subject, and trailer records."
---

# Git Agent Attribution

Attribute commits without replacing human responsibility: keep the configured Git user as committer and record only agents that materially contributed to the commit.

## Apply the attribution policy

1. Inspect the worktree, current branch, staged scope, recent commits, upstream, and configured identity.
2. Preserve `git config user.name` and `git config user.email` as committer. Do not set `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`, or `--reset-author`.
3. Identify the harness that runs the agent. Use the lowercase platform name as `{harness}`; for example, use `codex` when the agent runs in Codex, or `claude-code` when it runs in Claude Code. If the harness is unavailable, ask the user instead of inventing it.
4. Identify the agent that integrated and owns the final change. Use it as the single author:

   ```text
   {model}-{reasoning_effort}@{harness} <{harness}@agent.invalid>
   ```

   Use the real model identifier and reasoning effort available in the current environment, normalized to lowercase and joined with hyphens—for example, `gpt-5.6-sol-high@codex` when running in Codex. Never omit the reasoning effort when it is available. If the model identifier already includes the effort suffix, do not append it again.

   When the harness is Codex, resolve both values from the current session record in `~/.codex/state_5.sqlite` instead of relying on the model's self-identification. Codex exposes the current session ID as `CODEX_THREAD_ID`; query the matching `threads.id` row read-only:

   ```bash
   sqlite3 -readonly "$HOME/.codex/state_5.sqlite" \
     -cmd ".parameter init" \
     -cmd ".parameter set :thread_id $CODEX_THREAD_ID" \
     'SELECT model, reasoning_effort FROM threads WHERE id = :thread_id;'
   ```

   Treat the returned `model` and `reasoning_effort` columns as authoritative for the current Codex session. If `CODEX_THREAD_ID` is unavailable, the database cannot be read, no matching row exists, or either value is null or empty, ask the user instead of inventing it.

   When the harness is Claude Code, resolve both values from the current session transcript instead of relying on the model's self-identification. Claude Code exposes the current session ID as `CLAUDE_CODE_SESSION_ID` and stores the transcript as a JSONL file under `~/.claude/projects/`; read the `model` and `effort` fields recorded on the latest assistant message:

   ```bash
   transcript=$(find "$HOME/.claude/projects" -name "$CLAUDE_CODE_SESSION_ID.jsonl" 2>/dev/null | head -1)
   grep '"type":"assistant"' "$transcript" | tail -1 | grep -o '"model":"[^"]*"\|"effort":"[^"]*"'
   ```

   Treat the returned `model` and `effort` values as authoritative for the current Claude Code session; the latest assistant message reflects any mid-session `/model` change, whereas `~/.claude/settings.json` only holds the startup default. The environment variable `CLAUDE_EFFORT`, when set, may be used to cross-check the effort value. For example, `model` `claude-fable-5` with `effort` `high` yields the author identity `claude-fable-5-high@claude-code <claude-code@agent.invalid>`. If `CLAUDE_CODE_SESSION_ID` is unavailable, no matching transcript file exists, or either value is missing, ask the user instead of inventing it.

   For other harnesses, use the values made available by that environment; if either value is unavailable, ask the user.
5. Record other models with conventional trailers according to their material role:
   - Code or artifact contributor: `Co-authored-by`
   - Reviewer: `Reviewed-by`
   - Tester: `Tested-by`
   - Problem reporter: `Reported-by`
   - Solution proposer: `Suggested-by`
   - Other material assistance: `Helped-by`
6. Prefer one commit per agent when contributions are cleanly separable. For a shared commit, use the final integrator as author and trailers for the others.
7. Compare trailer identities with the author by the full `{model}-{reasoning_effort}@{harness}` identifier, not agent instance. If a sub-agent uses the same full identifier as the author, omit all of its trailers even when it performed separate work. For every other identifier, record each distinct material role it performed. For example, include both `Reviewed-by` and `Tested-by` when the same non-author agent reviewed and tested the change. Remove only exact duplicate trailers for the same identifier and role.
8. Verify the resulting author, committer, subject, and trailers with `git log`.

Do not credit an agent merely because it was spawned, consulted, or listed. Credit only contributions used in the committed result.

## Format the commit subject

Format a commit subject as:

```text
{action}: {scope}: {message}
```

- Derive `scope` from the staged change, using the narrowest recognizable scope name such as `tui`, `core`, or `app-server`.
- Omit `scope` when the change is cross-cutting, spans a broad scope, or is general:

  ```text
  {action}: {message}
  ```

- Use a concise lowercase `action` that classifies the change, such as `fix`, `improve`, `docs`, `feat`, `test`, `refactor`, `build`, `ci`, or `chore`.
- Write `message` as a concise summary of the committed change.

Examples:

```text
fix: tui: preserve selection after refresh
improve: core: reuse MCP client sessions
docs: explain remote executor setup
```

## Format trailers

Use standard co-author trailers for agents that directly produced committed content:

```text
Co-authored-by: {model}-{reasoning_effort}@{harness} <{harness}@agent.invalid>
```

Use `{harness}@agent.invalid` for every agent author and trailer identity, where `{harness}` is the platform running the agent. In Codex, use `codex@agent.invalid`; in Claude Code, use `claude-code@agent.invalid`. Distinguish agents by the `{model}-{reasoning_effort}@{harness}` display name rather than by email. Use conventional role trailers for non-authoring work:

```text
Reviewed-by: o3-high@codex <codex@agent.invalid>
Tested-by: gpt-5.6-terra-medium@codex <codex@agent.invalid>
Reported-by: o4-mini-high@codex <codex@agent.invalid>
```

Add trailers with repeated `--trailer` options when possible so Git formats them correctly.

Do not use custom `Agent-*` trailers. Do not add `Signed-off-by` unless the user explicitly requests the certification required by the project's DCO or contribution policy.

## Create a new attributed commit

Confirm the staged files contain only the intended change, then commit without overriding the committer:

```bash
git commit \
  --author="gpt-5.6-sol-high@codex <codex@agent.invalid>" \
  --trailer="Co-authored-by: o3-high@codex <codex@agent.invalid>" \
  --trailer="Reviewed-by: gpt-5.6-terra-medium@codex <codex@agent.invalid>" \
  --trailer="Tested-by: gpt-5.6-terra-medium@codex <codex@agent.invalid>" \
  -m "feat: tui: describe the change"
```

Omit trailers that do not apply. If a reviewer, tester, or co-author is also `gpt-5.6-sol-high@codex`, omit all trailers for that full identifier because it is already represented as author. Otherwise, keep every applicable distinct role, as shown by the reviewer and tester trailers for `gpt-5.6-terra-medium@codex` above.

## Amend or rewrite attribution

For the latest commit, amend only the requested metadata:

```bash
git commit --amend --no-edit \
  --author="gpt-5.6-sol-high@codex <codex@agent.invalid>"
```

For multiple recent commits:

1. Confirm the exact commit range and ensure the worktree is clean.
2. Check whether the commits have an upstream or were pushed.
3. Warn that rewriting changes commit hashes and invalidates signatures.
4. Rewrite only the requested commits, preserving messages and content.
5. Never force-push unless the user explicitly requests it; use `--force-with-lease` rather than `--force` when authorized.

## Verify

Inspect both identities and the full message after committing or rewriting:

```bash
git log -1 --format='commit %H%nauthor: %an <%ae>%ncommitter: %cn <%ce>%nsubject: %s%n%n%b'
git status --short --branch
```

The expected result is:

- Author: integrating agent's full model-and-effort identity
- Committer: configured human Git identity
- Subject: `{action}: {scope}: {message}`, or `{action}: {message}` when scope is omitted
- Body: only applicable conventional trailers for distinct model identities
- Worktree: unchanged except for the requested commit operation
