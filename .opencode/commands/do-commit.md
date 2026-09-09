---
description: Create atomic commits from all pending changes using Conventional Commits
---

Use the `commit-process` skill to commit the current pending changes.

Run the full workflow defined in the skill:

1. Parse the arguments below for include/exclude file patterns.
2. Inspect all pending changes (`git status`, `git diff`, `git diff HEAD`, untracked files).
3. Group files by intent and assign Conventional Commit types/scopes.
4. Create each commit separately with an English Conventional Commits message.
5. Output ONLY the list of commits created.

Never push, pull, merge, rebase, or ask for confirmation.

Arguments: $ARGUMENTS