#!/usr/bin/env bash
# render_transfer_plan.sh — render a human-reviewable Markdown transfer plan
# from the categorized inventory.
#
# Reads:  ${SCRUTATOR_DATA:-data}/inventory/repos.categorized.jsonl
# Writes: ${SCRUTATOR_DATA:-data}/inventory/transfer-plan.md

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [--help]

Renders the categorized inventory as a Markdown plan with one table per
non-empty bucket. Each row has an empty 'decision' column for sign-off.

Environment:
  SCRUTATOR_DATA       Base data dir. Default: ./data
  SCRUTATOR_TARGET_ORG Target org. Default: meta-organvm

Requires: jq
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

DATA_DIR="${SCRUTATOR_DATA:-data}/inventory"
IN="${DATA_DIR}/repos.categorized.jsonl"
OUT="${DATA_DIR}/transfer-plan.md"
TARGET="${SCRUTATOR_TARGET_ORG:-meta-organvm}"

[[ -f "$IN" ]] || { echo "error: $IN not found; run scripts/categorize_repos.sh first" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq not installed" >&2; exit 1; }

GENERATED_AT=$(date -Iseconds)
TOTAL=$(wc -l < "$IN" | tr -d ' ')

{
  echo "# Repo Consolidation — Transfer Plan"
  echo ""
  echo "**Target org:** \`${TARGET}\`"
  echo "**Generated:** ${GENERATED_AT}"
  echo "**Total repos inventoried:** ${TOTAL}"
  echo ""
  echo "## Bucket Summary"
  echo ""
  echo "| Action | Count |"
  echo "|---|---|"
  jq -r '.action' "$IN" | sort | uniq -c | sort -rn \
    | awk '{count=$1; $1=""; sub(/^ /,""); printf "| %s | %d |\n", $0, count}'
  echo ""
} > "$OUT"

emit_bucket() {
  local action="$1"
  local heading="$2"
  local count
  count=$(jq -c --arg a "$action" 'select(.action == $a)' "$IN" | wc -l | tr -d ' ')
  [[ "$count" == "0" ]] && return 0

  {
    echo "## ${heading} (${count})"
    echo ""
    echo "| current full_name | target | risk_flags | decision |"
    echo "|---|---|---|---|"
    jq -r --arg a "$action" --arg target "$TARGET" '
      select(.action == $a)
      | (
          [
            (if .has_pages then "pages" else empty end),
            (if .has_packages then "packages" else empty end),
            (if (.open_issues // 0) > 0 then "issues=\(.open_issues)" else empty end),
            (if (.size_kb // 0) > 500000 then "large=\(.size_kb)kb" else empty end),
            (if .fork then "fork-of=\(.parent // "?")" else empty end),
            (if .archived then "archived" else empty end),
            (if .private then "private" else "public" end)
          ] | join(", ")
        ) as $flags
      | "| \(.full_name) | \($target)/\(.full_name | split("/")[1]) | \($flags) |  |"
      ' "$IN"
    echo ""
  } >> "$OUT"
}

emit_bucket "rename_then_transfer" "Rename-then-transfer (name collision in target)"
emit_bucket "transfer_archived"     "Transfer — archived"
emit_bucket "transfer_private"      "Transfer — private"
emit_bucket "transfer_public"       "Transfer — public"
emit_bucket "defer_fork"            "Deferred — forks (handle manually)"
emit_bucket "keep_on_profile"       "Keep on personal profile"
emit_bucket "skip_no_admin"         "Skip — not admin"
emit_bucket "skip_already_target"   "Skip — already in target org"

{
  echo "## Notes"
  echo ""
  echo "- Fill the **decision** column per row before any transfer is executed."
  echo "- Rename source to \`<repo>-legacy\` *before* transferring when the basename collides with an existing \`${TARGET}/<repo>\`."
  echo "- Repos flagged \`pages\` may have a custom-domain CNAME — coordinate DNS before transfer."
  echo "- Repos flagged \`packages\` publish to a registry namespaced by owner; published versions stay reachable via redirect, but new pushes need updated registry config."
  echo "- Forks are deferred: transferring a fork detaches its upstream link. Decide per row whether to delete, transfer-and-detach, or leave."
  echo "- Personal-profile repos are surfaced via \`scripts/profile_keep.txt\`. Edit that file and re-run \`categorize_repos.sh\` if any row is misclassified."
} >> "$OUT"

echo "Wrote $OUT" >&2
