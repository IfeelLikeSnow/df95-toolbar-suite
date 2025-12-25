#!/usr/bin/env bash
set -euo pipefail
BRANCH="${1:-main}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT="$ROOT/Reports/unresolved_script_targets.md"

if [[ ! -f "$REPORT" ]]; then
  echo "Missing report: $REPORT"
  echo "Run: python3 tools/generate_shims_from_toolbars.py"
  exit 1
fi

TARGETS=$(grep -E '^## Scripts/' "$REPORT" | sed -E 's/^## //')
if [[ -z "$TARGETS" ]]; then
  echo "No unresolved targets."
  exit 0
fi

UPSTREAMS=(
  "IfeelLikeSnow/df95-ifls-full"
  "IfeelLikeSnow/df95-ifls"
)

found=0
missing=0

while IFS= read -r rel; do
  rel="${rel//$'\r'/}"
  dst="$ROOT/$rel"
  [[ -f "$dst" ]] && continue
  mkdir -p "$(dirname "$dst")"
  ok=0
  for repo in "${UPSTREAMS[@]}"; do
    url="https://raw.githubusercontent.com/${repo}/${BRANCH}/${rel}"
    if curl -fsSL "$url" -o "$dst" ; then
      echo "Fetched: $rel <= $repo"
      ok=1
      found=$((found+1))
      break
    else
      rm -f "$dst"
    fi
  done
  if [[ $ok -eq 0 ]]; then
    echo "Still missing: $rel"
    missing=$((missing+1))
  fi
done <<< "$TARGETS"

echo "Done. fetched=$found missing=$missing"
