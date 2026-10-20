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
