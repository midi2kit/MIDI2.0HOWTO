#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd jq
require_cmd date

ALLOW_NETWORK_FAILURE="${ALLOW_NETWORK_FAILURE:-0}"
if [[ "${1:-}" == "--allow-network-failure" ]]; then
  ALLOW_NETWORK_FAILURE="1"
fi

TODAY_UTC="$(date -u +%Y-%m-%d)"
YEAR_MONTH="$(date -u +%Y-%m)"
REPORT_SLUG="midi2-support-status-${YEAR_MONTH}"
JA_REPORT_PATH="ja/${REPORT_SLUG}.md"
EN_REPORT_PATH="en/${REPORT_SLUG}.md"

REPOS=(
  "microsoft/MIDI"
  "celtera/libremidi"
  "orchetect/MIDIKit"
  "alsa-project/alsa-lib"
  "midi2-dev/MIDI2.0Workbench"
  "midi2-dev/ni-midi2"
  "midi2-dev/AM_MIDI2.0Lib"
)

log() {
  printf '%s\n' "$*"
}

github_api() {
  local endpoint="$1"
  if command -v gh >/dev/null 2>&1; then
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
      GH_TOKEN="${GITHUB_TOKEN}" gh api "${endpoint}"
    else
      gh api "${endpoint}"
    fi
    return
  fi

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl -fsSL \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      "https://api.github.com/${endpoint}"
  else
    curl -fsSL \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/${endpoint}"
  fi
}

fetch_repo_metrics() {
  local repo="$1"
  local json stars updated url

  if command -v gh >/dev/null 2>&1; then
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
      if ! json="$(GH_TOKEN="${GITHUB_TOKEN}" gh repo view "$repo" --json stargazerCount,updatedAt,url)"; then
        return 1
      fi
    else
      if ! json="$(gh repo view "$repo" --json stargazerCount,updatedAt,url)"; then
        return 1
      fi
    fi
    stars="$(jq -r '.stargazerCount // empty' <<<"$json")"
    updated="$(jq -r '.updatedAt // empty' <<<"$json")"
    url="$(jq -r '.url // empty' <<<"$json")"
  else
    if ! json="$(github_api "repos/${repo}")"; then
      return 1
    fi
    stars="$(jq -r '.stargazers_count // empty' <<<"$json")"
    updated="$(jq -r '.updated_at // empty' <<<"$json")"
    url="$(jq -r '.html_url // empty' <<<"$json")"
  fi

  printf '%s|%s|%s\n' "$stars" "$updated" "$url"
}

find_previous_report() {
  local current="$1"
  local best_path=""
  local best_key=""
  local path base suffix key

  shopt -s nullglob
  for path in ja/midi2-support-status-*.md; do
    [[ "$path" == "ja/midi2-support-monthly-template.md" ]] && continue
    [[ "$path" == "$current" ]] && continue

    base="${path##*/}"
    suffix="${base#midi2-support-status-}"
    suffix="${suffix%.md}"

    if [[ "$suffix" =~ ^([0-9]{4})-([0-9]{2})$ ]]; then
      key="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    elif [[ "$suffix" =~ ^([0-9]{4})$ ]]; then
      key="${BASH_REMATCH[1]}00"
    else
      continue
    fi

    if [[ -z "$best_key" || "$key" > "$best_key" ]]; then
      best_key="$key"
      best_path="$path"
    fi
  done
  shopt -u nullglob

  printf '%s' "$best_path"
}

replace_line_contains() {
  local file="$1"
  local contains1="$2"
  local contains2="$3"
  local replacement="$4"

  local tmp
  local replaced=0
  tmp="$(mktemp)"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == *"$contains1"* ]] && { [[ -z "$contains2" ]] || [[ "$line" == *"$contains2"* ]]; }; then
      printf '%s\n' "$replacement" >>"$tmp"
      replaced=1
    else
      printf '%s\n' "$line" >>"$tmp"
    fi
  done <"$file"

  mv "$tmp" "$file"

  if [[ "$replaced" -eq 0 ]]; then
    log "warning: pattern not found in ${file}: ${contains1}"
  fi
}

PREV_REPORT_PATH="$(find_previous_report "$JA_REPORT_PATH")"
PREV_REPORT_SLUG=""
PREV_REPORT_LINK="初回作成（比較対象なし）"

if [[ -n "$PREV_REPORT_PATH" ]]; then
  PREV_REPORT_SLUG="${PREV_REPORT_PATH#ja/}"
  PREV_REPORT_SLUG="${PREV_REPORT_SLUG%.md}"
  PREV_REPORT_LINK="[${PREV_REPORT_SLUG}]({{ '/ja/${PREV_REPORT_SLUG}/' | relative_url }})"
fi

PREV_STAR_COL=3
if [[ -n "$PREV_REPORT_PATH" ]]; then
  PREV_HEADER="$(grep -m1 '^| Repository |' "$PREV_REPORT_PATH" || true)"
  if [[ "$PREV_HEADER" == *"Stars(prev)"* ]]; then
    PREV_STAR_COL=4
  fi
fi

get_previous_star() {
  local repo="$1"
  local line value

  [[ -z "$PREV_REPORT_PATH" ]] && {
    printf ''
    return
  }

  line="$(grep -F "| ${repo} |" "$PREV_REPORT_PATH" | head -n1 || true)"
  [[ -z "$line" ]] && {
    printf ''
    return
  }

  value="$(echo "$line" | awk -F'|' -v col="$PREV_STAR_COL" '{gsub(/^[ \t]+|[ \t]+$/, "", $col); print $col}')"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s' "$value"
  else
    printf ''
  fi
}

GITHUB_TABLE_ROWS=""
for repo in "${REPOS[@]}"; do
  if metrics="$(fetch_repo_metrics "$repo" 2>/tmp/midi2_status_api_error.log)"; then
    IFS='|' read -r stars_raw updated_raw url_raw <<<"$metrics"
  elif [[ "$ALLOW_NETWORK_FAILURE" == "1" ]]; then
    log "warning: failed to fetch ${repo}; using N/A placeholders"
    stars_raw=""
    updated_raw=""
    url_raw=""
  else
    cat /tmp/midi2_status_api_error.log >&2 || true
    rm -f /tmp/midi2_status_api_error.log
    exit 1
  fi

  rm -f /tmp/midi2_status_api_error.log

  if [[ "$stars_raw" =~ ^[0-9]+$ ]]; then
    stars_now="$stars_raw"
  else
    stars_now="N/A"
  fi

  if [[ -n "$updated_raw" ]]; then
    updated="${updated_raw%%T*}"
  else
    updated="N/A"
  fi

  if [[ -n "$url_raw" ]]; then
    url="$url_raw"
  else
    url="https://github.com/${repo}"
  fi

  prev_star="$(get_previous_star "$repo")"
  if [[ "$stars_now" == "N/A" ]]; then
    prev_display="${prev_star:-N/A}"
    delta_display="N/A"
  elif [[ -z "$prev_star" ]]; then
    prev_display="N/A"
    delta_display="N/A"
  else
    prev_display="$prev_star"
    delta=$((stars_now - prev_star))
    if (( delta > 0 )); then
      delta_display="+${delta}"
    elif (( delta < 0 )); then
      delta_display="${delta}"
    else
      delta_display="0"
    fi
  fi

  GITHUB_TABLE_ROWS+="| ${repo} | ${prev_display} | ${stars_now} | ${delta_display} | ${updated} | ${url} |"$'\n'
done

PERIOD_START="${YEAR_MONTH}-01"

cat >"${JA_REPORT_PATH}" <<EOF
---
title: MIDI 2.0 対応状況（${YEAR_MONTH} 月次更新）
lang: ja
permalink: /ja/${REPORT_SLUG}/
---

# MIDI 2.0 対応状況（${YEAR_MONTH} 月次更新）

このページは月次フォーマットに基づいて自動生成されています。

## 更新情報
- 更新日: \`${TODAY_UTC}\`
- 対象期間: \`${PERIOD_START} .. ${TODAY_UTC}\`
- 前回レポート: ${PREV_REPORT_LINK}
- データ取得日時（UTC）: \`${TODAY_UTC}\`

## 差分サマリー（前回比）

| 領域 | 前回 | 今回 | 差分 | 影響度 |
|---|---|---|---|---|
| OS | 要確認 | 要確認 | 手動確認 | 中 |
| ハードウェア | 要確認 | 要確認 | 手動確認 | 中 |
| ソフトウェア/DAW | 要確認 | 要確認 | 手動確認 | 中 |
| Linux実験系 | 要確認 | 要確認 | 手動確認 | 中 |
| GitHub動向 | 自動採取 | 自動採取 | 自動計算 | 中 |

## 要確認項目（次回更新まで）
- [ ] Windows MIDI Services の一般提供範囲を再確認
- [ ] DAW別の MIDI 2.0 実装範囲（CVM/PE/Profile）を再確認
- [ ] Linux kernel / ALSA の MIDI 2.0 関連更新を再確認
- [ ] ハードウェア各社のファーム更新有無を再確認

## GitHub動向（${TODAY_UTC} 取得）

| Repository | Stars(prev) | Stars(now) | Delta | Updated (UTC) | URL |
|---|---:|---:|---:|---|---|
EOF

printf '%s' "$GITHUB_TABLE_ROWS" >>"${JA_REPORT_PATH}"

cat >>"${JA_REPORT_PATH}" <<EOF

## 領域別アップデート（手動追記）

### OS
- Windows:
- Apple:
- Android:
- Linux:

### ハードウェア
- 新規対応機種/ファーム:

### ソフトウェア / DAW
- DAW別対応状況:

### Linux等の実験的プロジェクト
- kernel / ALSA:
- Dev tools / libraries:

## 主要参照リンク
- [Windows MIDI Services](https://github.com/microsoft/MIDI)
- [Apple CoreMIDI MIDI 2 guide](https://developer.apple.com/documentation/coremidi/incorporating-midi-2-into-your-apps)
- [Android MIDI API](https://developer.android.com/reference/android/media/midi/package-summary)
- [Kernel docs: MIDI 2.0 on Linux](https://www.kernel.org/doc/html/v6.12/sound/designs/midi-2.0.html)
- [MIDI DAW WG update](https://midi.org/midi-daw-working-group-releases-developer-tools-and-profiles-at-2026-namm-show)
EOF

cat >"${EN_REPORT_PATH}" <<EOF
---
title: MIDI 2.0 Support Status (${YEAR_MONTH} Monthly Update)
lang: en
permalink: /en/${REPORT_SLUG}/
---

# MIDI 2.0 Support Status (${YEAR_MONTH} Monthly Update)

This page is reserved for the English translation.

## Current status
- Source language: Japanese
- Translation state: Planned

## Source page
- [日本語版: MIDI 2.0 対応状況（${YEAR_MONTH} 月次更新）]({{ '/ja/${REPORT_SLUG}/' | relative_url }})
EOF

replace_line_contains \
  "ja/index.md" \
  "MIDI 2.0 対応状況（" \
  "/ja/midi2-support-status-" \
  "5. [MIDI 2.0 対応状況（${YEAR_MONTH}）]({{ '/ja/${REPORT_SLUG}/' | relative_url }})"

replace_line_contains \
  "ja/index.md" \
  "midi2-support-status-" \
  "調査スナップショット" \
  "- \`${REPORT_SLUG}.md\`: 詳細化済み（調査スナップショット）"

replace_line_contains \
  "en/index.md" \
  "MIDI 2.0 Support Status (" \
  "/en/midi2-support-status-" \
  "5. [MIDI 2.0 Support Status (${YEAR_MONTH})]({{ '/en/${REPORT_SLUG}/' | relative_url }})"

replace_line_contains \
  "en/index.md" \
  "midi2-support-status-" \
  "research snapshot" \
  "- \`${REPORT_SLUG}.md\`: added (research snapshot, translation pending)"

replace_line_contains \
  "_layouts/default.html" \
  "/ja/midi2-support-status-" \
  "MIDI 2.0 対応状況" \
  "              <li><a href=\"{{ '/ja/${REPORT_SLUG}/' | relative_url }}\" {% if page.url == '/ja/${REPORT_SLUG}/' %}class=\"is-active\"{% endif %}>MIDI 2.0 対応状況</a></li>"

replace_line_contains \
  "_layouts/default.html" \
  "/en/midi2-support-status-" \
  "MIDI 2.0 Support Status" \
  "              <li><a href=\"{{ '/en/${REPORT_SLUG}/' | relative_url }}\" {% if page.url == '/en/${REPORT_SLUG}/' %}class=\"is-active\"{% endif %}>MIDI 2.0 Support Status</a></li>"

log "generated: ${JA_REPORT_PATH}"
log "generated: ${EN_REPORT_PATH}"
log "updated links in ja/index.md, en/index.md, _layouts/default.html"
