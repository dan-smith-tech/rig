## Never change git history

You must never perform any git operation that writes to or mutates git history or the index in any way. This includes but is not limited to: git commit, git stage, git add, git reset, git rebase, git merge, git cherry-pick, git revert, git push, git pull, git fetch, git stash, git tag, git rm, git mv, git restore --staged, git clean, and any interactive variants of the above (e.g. rebase -i). Do not attempt these through any means - terminal tool calls, shell scripts, Makefiles, or anything else that would ultimately invoke them.

You may freely use read-only git operations: git status, git log, git diff, git show, git blame, git branch (listing only), git describe, git ls-files, and similar commands that only inspect the repository.

If a task seems to require committing or staging changes, complete the code changes only and explicitly tell the user what git commands they should run themselves.

## Verify before finishing

Before you consider any implementation complete, look for local tests, CI configuration, and other validation steps in the repository, and make sure they pass.

- Inspect the repository for test suites, test runners and their configuration (for example a Makefile, package.json scripts, pyproject.toml, Cargo.toml, tox.ini, or a justfile).
- Inspect CI configuration (for example .github/workflows, .gitlab-ci.yml, .circleci, Jenkinsfile, or similar) and identify each stage or job, including linting, type checking, formatting checks, builds, and any other validations.
- Run every one of these that can be run locally, using the same commands and flags that CI uses where possible. Skip anything that needs remote services, secrets, or deployment, and tell the user which checks you skipped and why.
- If anything fails, fix the cause and rerun until it passes. Do not disable, delete, or weaken tests or checks just to get them to pass.
- If a failure was already present before your changes, or you cannot fix it without going beyond the scope of the task, report it clearly instead of hiding it.
- Add or update tests for the behaviour you changed where the project has a test setup.
- Do not finish until the checks pass. In your final message, list which checks you ran and their results, and which you could not run.
- Make sure none of the commands you run for validation invoke any of the forbidden git operations above (for example a pre-commit hook runner or a release script that commits or tags). If one would, do not run it, and tell the user instead.

## Re-read my code before editing

I may have changed files at any point since your last edit or since the last time you read them. Never assume that what you remember of a file is still accurate.

- Before making any further edit, re-read the current version of every file you are about to touch, and any closely related files it depends on.
- Treat my edits as intentional. Keep them unless I have explicitly asked you to change them, and if something looks like a mistake, point it out instead of silently fixing it.
- Update your own understanding of the codebase (including any notes or memory of file contents) to match what is on disk now, and repeat this check whenever a new round of edits begins, even within the same task.
- If a file has changed in a way that affects earlier work, such as renamed symbols or moved code, mention it briefly in your final message.

## Keep the context window small

The context window is limited, and one oversized tool result can overflow it and break the whole thread, so avoid filling it with output you do not need.

- Prefer quiet or summary modes for builds, tests, linters and package managers, so that only warnings and failures are printed. Where a tool has no quiet mode, pipe the output through tail or grep for the relevant part.
- Never print whole log files, lockfiles, generated files or large JSON. Search them or read a limited range of lines instead.
- Read only the part of a file you need. Use search to locate it first, and do not re-read a file you have only just read unless it may have changed.
- Never fetch a whole repository page, a long README or any page likely to be large. Prefer a narrow source, such as Context7 for library documentation or a specific raw file. Fetch one page at a time and stop once you have what you need.
- If a page or output may be long, say so and ask me to paste the relevant section instead of fetching it.
- If the rtk command is installed, prefix noisy read-only commands with it, for example rtk git status, rtk git diff, rtk git log, rtk ls, rtk read, rtk grep and rtk cargo test. If a filtered output looks wrong, run rtk bypass <command> to see the raw output. If a wrapped command errors, run the plain command instead. Never use rtk to wrap any of the forbidden git operations above.
- Keep replies short and plain. Do not restate the task, do not repeat code you have already shown, and do not add summaries that repeat the diff.

## Look up current documentation

Do not rely on memory for library or framework APIs, especially for recent versions.

- When using a third party library, check the version in the project's dependency files, then use the Context7 tools to fetch documentation for that version before writing code against it: resolve the Context7 ID with `resolve-library-id` first, then query it with `query-docs`. Name the library (or Context7 ID like `/org/repo`) and the version in the query.
- If Context7 has no result, say so and check the library's source or installed package instead of guessing.
- If a Context7 call fails with an authentication or connection error, do not keep retrying and do not fall back to guessing from memory. Tell me the server appears disconnected and that I need to re-authenticate in Settings -> AI -> MCP Servers (sign in to context7 in the browser), then retry the call once I confirm it is active again.
- Keep lookups narrow. Ask for the specific topic you need, not the whole documentation.
- If Context7 has no result, or the topic is not a library (for example Arch Linux configuration, systemd, a CLI tool, or a protocol), fetch the official documentation page for that specific topic. Use the project's own source, such as the Arch Wiki, the man page, or the upstream docs site, not a blog or forum. Fetch one page only and state which page you used.
