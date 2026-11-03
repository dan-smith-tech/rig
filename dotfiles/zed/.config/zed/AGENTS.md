# Rules

- No matter the task or context, the following are not to be broken or ignored.
- If something is needed to follow a rule (like an installed tool, or a servcie reachable/connected) but is not available, tell me and I will fix it. Do not ignore or fall back to a different approach.

## Git: read-only

- Never run git commands that write to history or the index: commit, add, stage, reset, rebase, merge, cherry-pick, revert, push, pull, fetch, stash, tag, rm, mv, restore --staged, clean, or any interactive variant.
- Never invoke them indirectly (terminal, scripts, Makefiles, hooks).
- Inspection commands are allowed.
- Never run a validation command that would invoke any of the above (e.g. pre-commit runner, release script). Tell me instead.

## Context7 (mandatory)

- Use Context7 for all library, framework and package documentation, with no exceptions.
- Never rely on memory for APIs.
- Check the version in the project's dependency files first.
- First tool calls before writing code: `resolve-library-id`, then `query-docs`, naming the library (or ID like `/org/repo`) and version.
- Keep queries narrow.
- Inspecting the installed package afterwards is fine for exact signatures but is no substitute.
- If Context7 has no result, say so and check the library source or installed package. Do not guess.
- On an auth or connection error, do not retry or guess. Tell me the server appears disconnected and to re-authenticate in Settings -> AI -> MCP Servers (sign in to context7 in the browser). Retry once after I confirm.
- For non-library topics (Arch Linux config, systemd, CLI tools, protocols), fetch one official page (Arch Wiki, man page, upstream docs, not blogs or forums) and state which you used.

## rtk (mandatory)

- Prefix every noisy read-only command with it (rtk git status, rtk git diff, rtk git log, rtk ls, rtk read, rtk grep, rtk cargo test).
- If rtk output looks wrong, use `rtk bypass <command>`.
- If a wrapped command errors, run it plain.
- Never wrap forbidden git operations with rtk.

## Verify before finishing

- Find test suites, runners and config (pyproject.toml, Cargo.toml, justfile, package.json).
- Find CI config (.github/workflows, .gitlab-ci.yml, .circleci, Jenkinsfile, etc.) and list every job: lint, type check, format check, build, etc.
- Run each locally, using CI's commands and flags where possible.
- Skip anything needing remote services, secrets or deployment, and say what was skipped and why.
- Fix failures at the cause and rerun until green.
- Never disable, delete or weaken tests or checks.
- Report failures that predate your changes or are out of scope.
- Add or update tests for changed behaviour where a test setup exists.
- Final message: checks run with results, and checks not run.

## Re-read before editing

- My files may have changed since you last read them.
- Before every edit, re-read each file you will touch and its closely related files, including at the start of each edit round.
- Treat my edits as intentional and keep them unless I ask otherwise.
- If something looks like a mistake, point it out rather than silently fixing it.
- Keep your notes of file contents in sync with disk.
- Mention briefly in the final message if my changes affect earlier work (renamed symbols, moved code).

## Keep context small

- Use quiet or summary modes for builds, tests, linters and package managers, or pipe through tail or grep.
- Never print whole logs, lockfiles, generated files or large JSON.
- Search first, then read only the needed line range.
- Do not re-read a file you just read unless it may have changed.
- Never fetch whole repo pages, long READMEs or other large pages. Prefer Context7 or a specific raw file, one page at a time.
- If a page may be long, say so and ask me to paste the relevant section.
- Keep replies short and plain. No task restating, repeated code or diff summaries.
- In general, keep language simple and to the point.
