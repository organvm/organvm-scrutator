# SOP-2026-05-09: meta-organvm Repo Consolidation Protocol

**SOP ID:** SOP-CONSOLIDATE-001
**Effective Date:** 2026-05-09
**Status:** ACTIVE
**Version:** 1.0

---

## Purpose

This SOP establishes the protocol for consolidating every GitHub repo the operator owns or administers — across personal account and all orgs, regardless of public/private or archived status — into the `meta-organvm` enterprise org.

The consolidation is split into two phases:

- **Phase A — Inventory & Plan** (this SOP, sections 4.1–4.3): produce a complete repo inventory and a row-by-row transfer plan. No GitHub state changes.
- **Phase B — Execute Transfers** (sections 4.4–4.7): act on the signed-off plan.

Phase A is fully automated. Phase B is gated by human sign-off on the generated `transfer-plan.md`.

## Scope

Applies to every repo where the operator has admin permission, including repos owned by the operator's personal account and repos owned by any org the operator belongs to.

Out of scope:

- Repos in `meta-organvm` (already at the target).
- Repos where the operator is collaborator/member without admin (cannot transfer).
- Personal-profile repos surfaced as `keep_on_profile` (persona README, resume/cv, user-site `*.github.io`, contribution-tracking, dotfiles, plus anything in `scripts/profile_keep.txt`).
- Forks (deferred — transferring a fork detaches its upstream relationship; decision is per-row).

## Preconditions

1. **Tooling installed locally:** `gh` CLI (authenticated), `jq`, `bash`.
2. **GitHub PAT scopes:**
   - Phase A (inventory only): `repo`, `read:org`
   - Phase B (transfers): add `admin:org`
3. **Operator is admin of `meta-organvm`** (verify: `gh api /user/memberships/orgs/meta-organvm --jq .role` returns `admin`).
4. **Two-factor auth enabled** on the operator account (GitHub blocks transfers between certain org configurations otherwise).

## Procedure

### Phase A — Inventory & Plan

#### 4.1 Run inventory

```bash
bash scripts/inventory_repos.sh
```

Outputs `data/inventory/repos.jsonl` (one repo per line). The script paginates `/user/repos` and `/orgs/{org}/repos` then dedupes by `full_name`.

Verify:

```bash
wc -l data/inventory/repos.jsonl
jq -s 'group_by(.full_name) | map(select(length > 1))' data/inventory/repos.jsonl  # must be []
jq -c 'select(.admin == null)' data/inventory/repos.jsonl                          # must be empty
```

If any row has a null `admin` field, the PAT lacks the `repo` scope.

#### 4.2 Categorize

Edit `scripts/profile_keep.txt` if any personal repo not already in the default seed should stay on your profile, then:

```bash
bash scripts/categorize_repos.sh
```

Outputs `data/inventory/repos.categorized.jsonl`. Each row gains an `action` field. The script prints bucket counts to stderr.

Bucket evaluation order (first match wins):

1. `skip_already_target` — owner is `meta-organvm`
2. `skip_no_admin` — operator lacks admin
3. `keep_on_profile` — personal repo matching profile-keep heuristic
4. `defer_fork` — repo is a fork
5. `rename_then_transfer` — basename collides with an existing `meta-organvm/<basename>`
6. `transfer_archived` — archived
7. `transfer_private` — private, not archived
8. `transfer_public` — public, not archived

#### 4.3 Render transfer plan & sign off

```bash
bash scripts/render_transfer_plan.sh
```

Outputs `data/inventory/transfer-plan.md`. Open it and fill the **decision** column per row (e.g. `transfer`, `rename-then-transfer`, `delete`, `keep`, `defer`).

Commit `transfer-plan.md` with the decisions filled in before proceeding to Phase B.

### Phase B — Execute Transfers

#### 4.4 Per-repo pre-flight (manual)

For each row marked `transfer*` in the signed-off plan, verify before transferring:

| Check | Why |
|---|---|
| Collaborators reviewed | Direct-collaborator perms don't carry across orgs identically |
| GitHub Pages custom domain | DNS CNAME breaks at transfer; coordinate or temporarily remove |
| Packages | Published versions remain reachable via redirect, but new pushes need updated registry config |
| Actions secrets / variables | Org-level secrets do not carry; copy to target org first |
| Branch protection rules | Migrate cleanly but verify post-transfer |
| Webhooks | Carry, but verify endpoints still trust the new URL |
| Deploy keys | Carry, but rotate if compromised in transit |
| Submodule URLs in dependent repos | Old URL serves a 301 redirect, but pin to new URL on next bump |

#### 4.5 Execute transfers (`scripts/execute_transfers.sh`)

```bash
# Dry run first — prints planned actions, writes log entries with outcome="dry_run".
bash scripts/execute_transfers.sh

# Iterate by bucket, lowest blast radius first.
bash scripts/execute_transfers.sh --only rename_then_transfer --execute
bash scripts/execute_transfers.sh --only transfer_archived    --execute
bash scripts/execute_transfers.sh --only transfer_private     --execute
bash scripts/execute_transfers.sh --only transfer_public      --execute
```

Defaults / guarantees:

- Dry-run unless `--execute` is passed. No `gh` mutation without it.
- Skips `keep_on_profile`, `defer_fork`, `skip_*` automatically.
- Logs every attempt to `data/inventory/transfer-log.jsonl` (appended, not truncated).
- Lowest blast radius first: archived → private → public. `rename_then_transfer` runs first because the rename must precede transfer of the colliding name.
- Forks are deferred indefinitely; decide per row (delete / transfer-and-detach / leave).

#### 4.6 Name-conflict resolution (handled in 4.5)

`execute_transfers.sh` handles `rename_then_transfer` rows by issuing:

```
gh repo rename <basename>-legacy --repo <current_owner>/<basename>
gh repo transfer <current_owner>/<basename>-legacy meta-organvm
```

Document the rename in the row's decision cell in `transfer-plan.md`.

#### 4.7 Post-transfer verification

For each transferred repo:

```bash
# Old URL serves 301 to new URL
curl -sI https://github.com/<old_owner>/<repo> | grep -i location

# Repo is now under meta-organvm
gh repo view meta-organvm/<repo> --json owner,name

# Default branch CI is green on next push
gh run list --repo meta-organvm/<repo> --limit 1
```

Submodule consumers: pin `.gitmodules` to the new URL on the next dependent-repo bump.

## Rollback

GitHub allows the original owner to reverse a repo transfer within 7 days (the rollback window is enforced by GitHub, not this SOP). Beyond that, a transfer-back is required.

If a transfer breaks something (Pages, packages, CI), the fastest reversion is to transfer the repo back to its original owner from `meta-organvm/<repo>` settings.

## Metrics Collected

Recorded as atoms in `data/raw/atoms.jsonl` per the `SOP-SCRUTATOR-001` convention:

| Metric | Description |
|--------|-------------|
| Repos inventoried | Total count from `repos.jsonl` |
| Bucket counts | Counts per `action` value |
| Transfers attempted | Count of `gh repo transfer` invocations |
| Transfers succeeded | Count where post-transfer verification passed |
| Renames performed | Count of `gh repo rename` invocations during 4.6 |
| Rollbacks | Count of reverse transfers within the 7-day window |

## Quality Standards

- **Completeness:** Every admin'd repo appears in the inventory exactly once.
- **Auditability:** `transfer-plan.md` is committed with decisions filled in *before* Phase B begins.
- **Reversibility:** No transfer proceeds without verifying the 7-day rollback path is available.
- **Idempotency:** Re-running Phase A produces the same bucket counts modulo new/deleted repos.

## Exceptions

- **Forks** — deferred; transferring detaches upstream. Decide per-row whether to delete, transfer-and-detach, or leave.
- **GitHub Pages with custom CNAMEs** — require DNS coordination; flag explicitly in the decision column.
- **Personal-profile repos** — kept on the user account via `scripts/profile_keep.txt` (persona README, resume/cv, user-site `*.github.io`, contribution-tracking, dotfiles by default; user-editable).
- **Repos with active GitHub Apps installed at the org level** — verify the app is also installed on `meta-organvm` first.

## Related SOPs

- SOP-SCRUTATOR-001: Session Metrics Collection Protocol
- SOP-SCRUTATOR-002: Gap Analysis Protocol
- SOP-SCRUTATOR-003: Inquiry Dispatch Protocol

## Follow-up Atoms (post-consolidation)

- Rename `SCRUTATOR_GITHUB_ORG` from `organvm` to `meta-organvm` in `.env.example`
- Update org references in `CLAUDE.md` and `AGENTS.md`
- Audit `.github/workflows/daily-scan.yml` for hard-coded org names
- Update sibling-repo URLs in any submodules or CI config

---

**Author:** Claude (Hokage)
**Review Cycle:** Post-consolidation only
**Next Review:** After Phase B completes
