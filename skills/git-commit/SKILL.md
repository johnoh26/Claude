---
name: git-commit
description: Security-aware git commit — scans changes for secrets/vulnerabilities, then stages and commits with an AI-generated message. Optional arg: target branch name.
argument-hint: "[branch]"
---

Perform a security-conscious git commit. Follow these steps precisely:

## Step 1: Branch check
Run `git branch --show-current`.

If `$ARGUMENTS` is provided, compare it to the current branch.
- If they don't match → STOP and tell the user: "You are on branch '<current>' but specified '<arg>'. Aborting."
- If they match, or no argument was given, continue.

## Step 2: Gather all changes
Run:
- `git status --short`
- `git diff HEAD` (all unstaged changes against last commit)
- `git diff --cached` (already-staged changes)

Note any untracked files shown in `git status` that may need to be included.

## Step 3: Security scan
Carefully review ALL diff output for:

**Sensitive information:**
- Hardcoded passwords, secrets, API keys, tokens (e.g. `password="abc123"`, `API_KEY=xyz...`)
- Private keys or certificates (`-----BEGIN ... KEY-----`)
- Real credentials (not placeholder text) in any `.env`-style file
- Personal email addresses embedded in code or config (not docs/comments)
- AWS/GCP/Azure access keys or secrets
- OAuth tokens or bearer tokens with real values
- Database connection strings containing credentials
- Queue names, UUIDs, or identifiers that appear personally tied to the user

**Security vulnerabilities:**
- SQL injection risk (string-concatenated queries)
- Hardcoded internal IPs or hostnames
- Debug backdoors (e.g. `if user == 'admin' and pass == 'hardcoded'`)
- Secrets in test files

## Step 4: Report findings and confirm
**If issues are found:**
- List each finding with filename and the offending line/pattern
- Use `AskUserQuestion` to ask: "Found potential sensitive info or vulnerabilities (listed above). Proceed with commit anyway?"
  - If user says no → STOP
  - If user says yes → continue to Step 5

**If no issues found:** proceed directly to Step 5.

## Step 5: Stage changes
Run `git add -A` to stage all changes (tracked + untracked).

Do NOT stage files covered by `.gitignore`.

## Step 6: Generate commit message
Based on the diff, write a concise commit message in Conventional Commits format:
- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — code restructuring without behavior change
- `docs:` — documentation only
- `chore:` — dependencies, config, tooling
- `style:` — UI/CSS/formatting

One-line subject (≤72 chars) describing WHAT changed and WHY. Add a short body if the change spans multiple concerns.

Do NOT add the `Co-Authored-By` trailer unless the user asks.

## Step 7: Commit
Run: `git commit -m "<generated message>"`

## Step 8: Push
Run: `git push`

If the branch has no upstream yet, run: `git push -u origin <branch>`

Report back:
- Commit hash (short)
- Commit message used
- Files changed summary
- Push result (remote URL and branch)
