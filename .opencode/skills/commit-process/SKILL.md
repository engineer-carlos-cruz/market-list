---
name: commit-process
description: >
  Creates well-structured commits from all pending changes (staged, unstaged,
  untracked) using Conventional Commits.
  Analyzes change intent, groups files into logical commits, and outputs results.
  Invoked via command only - no triggers.
license: MIT
metadata:
  author: carlos-cruz-longport
  version: "1.0"
---

## When to Use

Use this skill when the user wants to commit all pending changes (staged, unstaged, and untracked) intelligently.
This skill is invoked through a command, not by trigger keywords.

---

## Critical Rules

**NEVER** do any of the following:

- `git push`, `git pull`, `git merge`, `git rebase`, `git fetch`
- Ask for confirmation or ask questions
- Stage the entire working tree at once — stage files only as needed for each commit
- Modify any file contents
- Show any output other than the final commit list

**ALWAYS** do the following:

- Use Conventional Commits format
- Write commit messages in English
- Group changes by intent (not by file alphabetically)
- Output only the commits created

---

## Workflow

### Step 1: Parse Arguments

Read `$ARGUMENTS` to detect file inclusion/exclusion patterns.

Accept any of these patterns (case-insensitive):

| Pattern | Meaning |
|---------|---------|
| `include: <path>` | Only commit this file/directory |
| `exclude: <path>` | Skip this file/directory |
| `solo: <path>` | Same as include |
| `except: <path>` | Same as exclude |
| `no commit <path>` | Same as exclude |
| `only <path>` | Same as include |

Multiple patterns are allowed. If both include and exclude are present for the same path, exclude wins.

If no arguments are provided, process all pending changes (staged + unstaged + untracked).

### Step 2: Get All Changes

Run these commands to understand all pending changes:

```bash
git status --short
git ls-files --others --exclude-standard
git diff HEAD
git diff
git diff --cached
```

- `git status --short` lists all modified, staged, and untracked files.
- `git ls-files --others --exclude-standard` lists untracked files (respecting `.gitignore`).
- `git diff HEAD` shows the complete diff of all tracked-file changes (staged + unstaged).

This covers three kinds of pending changes: staged (in the index), unstaged (modified tracked files), and untracked (new files not yet tracked).

If there are no pending changes at all, terminate immediately with no output.

### Step 3: Apply File Filters

From the complete list of pending files (staged, unstaged, and untracked), apply include/exclude rules:

- If includes exist: keep only files matching include paths
- If excludes exist: remove files matching exclude paths
- After filtering, if no files remain, terminate with no output

### Step 4: Analyze Intent and Group Files

Analyze the complete diff (`git diff HEAD` plus the contents of untracked files) to understand the **purpose** of each change.

Group files by intent using these signals:

| Signal | Grouping Logic |
|--------|---------------|
| Same feature/feature area | Files in same directory tree or with related names → one commit |
| Model + Migration + Controller | A cohesive change across layers → one commit |
| New files | Newly created files → likely `feat` or `chore` |
| Modified files | Existing files changed → likely `fix`, `refactor`, `perf`, `style` |
| Test files | Files under `test/`, `spec/`, `*_test.*`, `*_spec.*` → `test` |
| Config/CI files | `.yml`, `.yaml`, `Dockerfile`, `Makefile`, CI configs → `ci` or `build` |
| Documentation | `*.md`, `*.mdx`, `README`, `CHANGELOG` → `docs` |
| Unrelated changes | Changes in completely different areas → separate commits |

**Grouping rules:**

- Changes that would break the build if only partially applied MUST be in the same commit
- A model change and its corresponding migration MUST be in the same commit
- Test files should be in a separate commit from the code they test, UNLESS the test is for a new feature (then include with the feature commit)
- If unsure whether changes belong together, split them into separate commits

### Step 5: Assign Conventional Commit Types

For each group, assign the appropriate type:

| Type | When to Use |
|------|-------------|
| `feat` | New functionality, new files, new endpoints, new models |
| `fix` | Bug fixes, corrected logic, error handling |
| `refactor` | Code restructuring without behavior change |
| `perf` | Performance improvements, query optimization |
| `style` | Formatting, whitespace, naming (no logic change) |
| `test` | Adding or updating tests only |
| `docs` | Documentation changes only |
| `build` | Build system, dependencies, Gemfile, package.json |
| `ci` | CI/CD configuration, pipelines, deployment |
| `chore` | Maintenance tasks, config changes, tooling |

### Step 6: Determine Scopes

The scope is the main directory or feature area the group of files belongs to.

Scope derivation rules:
- Use the deepest meaningful directory common to the group
- If files span multiple feature directories → use the common parent
- If no clear scope → omit scope parenthesis

### Step 7: Write Commit Messages

Format:

```
<type>(<scope>): <description>

[optional body explaining WHY, not WHAT]
```

**Description rules:**

- Imperative mood ("add", not "added" or "adds")
- No period at the end
- Maximum 72 characters for the subject line
- English only

**Body rules (optional):**

- Use when the change is non-obvious or needs context
- Explain WHY the change was made, not WHAT the code does
- Wrap at 72 characters

### Step 8: Create Commits

For each group, stage the files and commit:

```bash
git reset HEAD  # unstage everything first
git add <files for this group>
git commit -m "<type>(<scope>): <description>" -m "<optional body>"
```

**IMPORTANT:** Before starting commits, run `git reset HEAD` to unstage everything. Then for each group, only `git add` the files belonging to that group before committing (including any untracked files in the group — `git add` stages new files too). This ensures each commit contains exactly the right files, regardless of whether they were previously staged, unstaged, or untracked.

If a commit fails, skip it and continue with the next group. Report failed commits in the output.

### Step 9: Output Results

Display ONLY the commits that were created:

```
commits created:
  <short-hash> <type>(<scope>): <description>
  <short-hash> <type>(<scope>): <description>
```

If no commits were created, display nothing.

---

## Commit Type Decision Tree

```
Are files new?
├── Yes → Are they test files? → test
│         Are they docs? → docs
│         Are they config/CI? → chore or build
│         Otherwise → feat
└── No (modified)
    ├── Was it a bug fix? → fix
    ├── Was it performance? → perf
    ├── Was it just formatting/naming? → style
    ├── Was it restructuring? → refactor
    ├── Was it docs/config/tests only? → docs, build, test
    └── Otherwise → fix or refactor
```

---

## Example Output

```
commits created:
  a1b2c3d feat(auth): add JWT token refresh endpoint
  e4f5g6h fix(payroll): correct overtime calculation for night shifts
  i7j8k9l refactor(reports): simplify date filtering logic
  m0n1o2p chore: update Ruby to 3.2.2
```

---

## Commands Reference

```bash
git status --short                 # list all pending changes
git ls-files --others --exclude-standard   # list untracked files
git diff HEAD                     # full diff of tracked changes
git diff                          # unstaged changes
git diff --cached                 # staged changes
git reset HEAD                    # unstage all files
git add <path>                    # stage specific file (also stages new/untracked)
git commit -m "message"           # create commit
git log --oneline -5              # verify commits (for output only)
```