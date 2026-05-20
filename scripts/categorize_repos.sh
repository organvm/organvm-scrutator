#!/usr/bin/env bash
# categorize_repos.sh — assign an `action` to each repo in the inventory.
#
# Reads:  ${SCRUTATOR_DATA:-data}/inventory/repos.jsonl
# Writes: ${SCRUTATOR_DATA:-data}/inventory/repos.categorized.jsonl

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--help]

Reads the raw inventory and assigns an action bucket to each row.

Buckets (first match wins):
  skip_already_target   - owner == "meta-organvm"
  skip_no_admin         - admin != true
  keep_on_profile       - personal repo matching profile-keep heuristic
  defer_fork            - fork == true
  rename_then_transfer  - basename collides with an existing meta-organvm/* repo
  transfer_archived     - archived
  transfer_private      - private, not archived
  transfer_public       - public, not archived

Environment:
  SCRUTATOR_DATA          Base data dir. Default: ./data
  SCRUTATOR_PROFILE_KEEP  Profile-keep allowlist file. Default: scripts/profile_keep.txt
  SCRUTATOR_TARGET_ORG    Target org for collision detection. Default: meta-organvm

Requires: gh (authenticated, for /user lookup), jq
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

DATA_DIR="${SCRUTATOR_DATA:-data}/inventory"
IN="${DATA_DIR}/repos.jsonl"
OUT="${DATA_DIR}/repos.categorized.jsonl"
KEEP_FILE="${SCRUTATOR_PROFILE_KEEP:-scripts/profile_keep.txt}"
TARGET="${SCRUTATOR_TARGET_ORG:-meta-organvm}"

[[ -f "$IN" ]] || { echo "error: $IN not found; run scripts/inventory_repos.sh first" >&2; exit 1; }
[[ -f "$KEEP_FILE" ]] || { echo "error: $KEEP_FILE not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq not installed" >&2; exit 1; }

# Allow overriding the viewer login via env (handy for tests). Otherwise gh /user.
if [[ -z "${SCRUTATOR_VIEWER:-}" ]]; then
  command -v gh >/dev/null || { echo "error: gh CLI not installed; set SCRUTATOR_VIEWER to bypass" >&2; exit 1; }
  VIEWER=$(gh api /user --jq .login)
else
  VIEWER="${SCRUTATOR_VIEWER}"
fi

# Load profile-keep allowlist (newline-delimited basenames; ignore # comments and blanks).
# awk (not grep) so an all-comments/all-blank file doesn't trip `set -e` with exit 1.
KEEP_BASENAMES=$(awk '!/^[[:space:]]*#/ && !/^[[:space:]]*$/' "$KEEP_FILE" | tr '\n' ',' | sed 's/,$//')

# Build the set of basenames already in the target org (collision detection).
COLLIDE_SET=$(jq -rs --arg t "$TARGET" '[.[] | select(.owner == $t) | .full_name | split("/")[1]] | unique | join(",")' "$IN")

jq -c \
  --arg viewer "$VIEWER" \
  --arg target "$TARGET" \
  --arg keep_csv "$KEEP_BASENAMES" \
  --arg collide_csv "$COLLIDE_SET" \
  '
  ($keep_csv | split(",") | map(select(length>0))) as $keep
  | ($collide_csv | split(",") | map(select(length>0))) as $collide
  | (.full_name | split("/")[1]) as $base
  | . + {
      action: (
        if .owner == $target then "skip_already_target"
        elif (.admin // false) != true then "skip_no_admin"
        elif (.owner == $viewer)
             and (
               ($base == $viewer)
               or ($base == ($viewer + ".github.io"))
               or ($keep | index($base))
             )
          then "keep_on_profile"
        elif .fork == true then "defer_fork"
        elif ($collide | index($base)) then "rename_then_transfer"
        elif .archived == true then "transfer_archived"
        elif .private == true then "transfer_private"
        else "transfer_public"
        end
      )
    }
  ' "$IN" > "$OUT"

echo "Categorized $(wc -l < "$OUT" | tr -d ' ') repos -> $OUT" >&2
echo "" >&2
echo "Bucket counts:" >&2
jq -r '.action' "$OUT" | sort | uniq -c | sort -rn >&2
