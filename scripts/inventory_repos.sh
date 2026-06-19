#!/usr/bin/env bash
# inventory_repos.sh — enumerate every GitHub repo the authenticated user can administer.
#
# Output: JSONL at ${SCRUTATOR_DATA:-data}/inventory/repos.jsonl
# Requires: gh (authenticated), jq
# PAT scopes: repo, read:org

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--help]

Enumerates every GitHub repo the authenticated user can see, across:
  - viewer-affiliated repos (/user/repos with affiliation=owner,collaborator,organization_member)
  - per-org repos (/orgs/<org>/repos for every org membership)

Output: \${SCRUTATOR_DATA:-data}/inventory/repos.jsonl (one JSON object per line, deduped by full_name)

Environment:
  SCRUTATOR_DATA   Base data dir. Default: ./data

Requires: gh (authenticated), jq
PAT scopes needed: repo, read:org
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

OUT="${SCRUTATOR_DATA:-data}/inventory/repos.jsonl"
mkdir -p "$(dirname "$OUT")"
: > "$OUT"

command -v gh >/dev/null || { echo "error: gh CLI not installed" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq not installed" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "error: gh not authenticated; run 'gh auth login'" >&2; exit 1; }

JQ_MAP='.[] | {
  full_name,
  owner: .owner.login,
  owner_type: .owner.type,
  visibility,
  private,
  archived,
  fork,
  default_branch,
  pushed_at,
  size_kb: .size,
  has_pages,
  has_packages,
  parent: (.parent.full_name // null),
  open_issues: .open_issues_count,
  primary_language: .language,
  admin: (.permissions.admin // false),
  role_name
}'

echo "Enumerating viewer-affiliated repos..." >&2
gh api --paginate -X GET /user/repos \
  -f affiliation=owner,collaborator,organization_member \
  -f visibility=all \
  -f per_page=100 \
  | jq -c "$JQ_MAP" >> "$OUT"

echo "Enumerating per-org repos..." >&2
ORGS=$(gh api --paginate /user/orgs | jq -r '.[].login')
for org in $ORGS; do
  echo "  - $org" >&2
  gh api --paginate "/orgs/${org}/repos?type=all&per_page=100" \
    | jq -c "$JQ_MAP" >> "$OUT" || echo "  (warn: failed to list $org)" >&2
done

# Dedupe by full_name (user/repos and org/repos overlap for member orgs)
TMP="$(mktemp)"
jq -cs 'unique_by(.full_name) | .[]' "$OUT" > "$TMP"
mv "$TMP" "$OUT"

COUNT=$(wc -l < "$OUT" | tr -d ' ')
echo "Inventoried ${COUNT} repos -> $OUT" >&2
