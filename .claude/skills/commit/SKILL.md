---
name: commit
description: Build, version bump, commit, and push changes following project conventions. Use when the user asks to commit changes, create a commit, or wants to save work to git.
allowed-tools: Bash(xcodebuild:*), Bash(git:*), Read, Edit, Grep
user-invocable: true
---

# Commit Workflow Skill

This skill automates the complete commit workflow for the FromTo project following established conventions.

## Workflow Steps

### 1. Build the Project First

**ALWAYS** build before committing to ensure code compiles:

```bash
xcodebuild -project "FromTo/FromTo.xcodeproj" \
  -scheme "FromTo" \
  -configuration Debug \
  build
```

**If build fails:**
- STOP immediately
- Report errors to user
- Do NOT proceed with commit

### 2. Update Version and Build Numbers

**Only if build succeeds**, update version numbers in `FromTo/FromTo.xcodeproj/project.pbxproj`:

**Version number format:**
- `MARKETING_VERSION`: Semantic version (e.g., `1.0.0`, `1.1.0`, `2.0.0`)
- `CURRENT_PROJECT_VERSION`: Version + timestamp (e.g., `1.0.1.20260113_143022`)

**Increment rules:**
- **Patch** (X.Y.Z+1): Bug fixes, small refactors, chores
- **Minor** (X.Y+1.0): New features, significant enhancements
- **Major** (X+1.0.0): Breaking changes, major rewrites

**Build number format:** `{VERSION}.{YYYYMMDD}_{HHMMSS}`
- Example: `1.0.1.20260113_143022`
- Always use current timestamp

**How to update:**
1. Read `FromTo/FromTo.xcodeproj/project.pbxproj`
2. Determine new version number based on changes
3. Generate build number with current timestamp: `{NEW_VERSION}.{YYYYMMDD}_{HHMMSS}`
4. Use Edit tool to replace **ALL occurrences** (there are 2 of each):
   - Find: `MARKETING_VERSION = 1.0.0;`
   - Replace with: `MARKETING_VERSION = {NEW_VERSION};`
   - Find: `CURRENT_PROJECT_VERSION = 1.0.0.20250112_2023;`
   - Replace with: `CURRENT_PROJECT_VERSION = {NEW_BUILD_NUMBER};`

### 3. Check Git Status

Run git commands to understand changes:

```bash
# See unstaged changes
git status

# See diff of changes
git diff

# See recent commits for message style
git log --oneline -10
```

### 4. Add Changes to Staging

**Add all unstaged changes:**

```bash
git add .
```

**Verify staging:**

```bash
git status
```

### 5. Create Commit Message

**Commit message format:**

```
{type}: {description}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Commit types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring (no behavior change)
- `chore:` - Maintenance (version bumps, config, cleanup)
- `docs:` - Documentation only
- `style:` - Code style/formatting
- `test:` - Adding or updating tests
- `perf:` - Performance improvements

**Description guidelines:**
- Concise (50-72 characters preferred)
- Imperative mood ("Add feature" not "Added feature")
- Focus on "what" and "why", not "how"
- Specific and meaningful

**Special case - Version bump commit:**

When ONLY version/build numbers changed:

```
chore: Bump version to {VERSION} (build {BUILD_NUMBER})

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Examples:**
- `feat: Add automatic currency rate setting when currencies match`
- `fix: Prevent keyboard dismissal when typing in settings`
- `refactor: Extract currency validation into reusable helper`
- `chore: Bump version to 1.0.1 (build 1.0.1.20260113_143022)`

### 6. Create the Commit

**Use HEREDOC format for proper formatting:**

```bash
git commit -m "$(cat <<'EOF'
{type}: {description}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**Verify commit:**

```bash
git log -1 --format='%h %s'
```

### 7. Push to Remote

**Push directly to main branch:**

```bash
git push origin main
```

**Verify push:**

```bash
git status
```

**Report to user:**
- Commit hash and message
- New version and build numbers
- Branch pushed to

## Two-Step Process

This skill creates **TWO commits**:

### Commit 1: Version Bump (if needed)
```
chore: Bump version to X.Y.Z (build X.Y.Z.YYYYMMDD_HHMMSS)
```

This commit **ONLY** contains changes to `project.pbxproj` for version numbers.

### Commit 2: Actual Changes
```
{type}: {description of user's changes}
```

This commit contains all other staged changes.

**Why two commits?**
- Separates version metadata from functional changes
- Makes history cleaner and easier to review
- Follows best practices for version management

## Error Handling

**Build failures:**
- Display xcodebuild error output
- Explain what failed
- Do NOT proceed with version bump or commit
- Ask user to fix errors first

**Git conflicts:**
- Display conflict messages
- Suggest resolution steps
- Do NOT force push

**No changes to commit:**
- Check if version bump is the only change
- If so, create version bump commit only
- If no changes at all, inform user and exit

## Important Notes

1. **ALWAYS build first** - Never skip this step
2. **Two separate commits** - Version bump separate from changes
3. **Use HEREDOC** - Ensures proper commit message formatting
4. **Push to main** - Direct push to main branch
5. **Never use --force** - Respect git safety
6. **Never skip hooks** - No --no-verify flags

## Quick Reference

**Full command sequence:**

1. Build: `xcodebuild -project FromTo/FromTo.xcodeproj -scheme FromTo build`
2. Update: Edit `FromTo/FromTo.xcodeproj/project.pbxproj` (2 occurrences each)
3. Status: `git status && git diff`
4. Stage version: `git add FromTo/FromTo.xcodeproj/project.pbxproj`
5. Commit version: `git commit -m "chore: Bump version to..."`
6. Stage all: `git add .`
7. Commit changes: `git commit -m "type: description..."`
8. Push: `git push origin main`
