#!/bin/bash
# STILL 045 クーポンページを生成する。
# - ディスカウント (¥2,500→¥2,000)         : _template_discount.html → x-${token}/
# - 関係者ディスカウント (¥2,500→¥1,000): _template_artist.html   → xa-${token}/
# - ルート (イベント案内のみ・クーポンなし)   : _template_discount.html から生成 → index.html
# 既存トークンは README.md から再利用し、URLを固定保持する（冪等）。
# _template_artist.html は _template_discount.html から派生生成する（正本は discount 側）。

set -euo pipefail

cd "$(dirname "$0")"

# GA4 測定ID。digtracks プロパティ (319283938) に相乗り。
# レポート時は hostname = puenots.github.io で絞る（page_title に DJ 名とクーポン種別が入る）。
GA4_ID="G-4N9ENSKWVH"

DJS=("DJ TAC" "UE" "KEIGO" "鍋奉行" "BAPE" "Yuuki" "TAKEDA")

# _template_artist.html を discount 版から派生させる
sed \
 -e 's|ディスカウントクーポン{{TITLE_SUFFIX}}|関係者ディスカウントクーポン{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">ディスカウントクーポン</div>|<div class="subtitle">関係者ディスカウントクーポン</div>|' \
 -e 's|linear-gradient(135deg, var(--orange) 0%, #c9631f 100%)|linear-gradient(135deg, #f0e4c8 0%, #d9c69a 100%)|' \
 -e 's|box-shadow: 0 6px 24px rgba(224, 122, 53, 0.35);|box-shadow: 0 6px 24px rgba(233, 216, 180, 0.25);|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">¥1,000</div>|' \
 -e 's|aria-label="ディスカウントクーポン">|aria-label="関係者ディスカウントクーポン">|' \
 -e 's|<div class="coupon-tag"></div>|<div class="coupon-tag">関係者専用</div>|' \
 _template_discount.html > _template_artist.html
echo "wrote  _template_artist.html"

# ルートページ: クーポン・招待セクションを除いたイベント案内（カウントダウンは残す）
sed \
 -e 's|<title>STILL 045 — ディスカウントクーポン{{TITLE_SUFFIX}}</title>|<title>STILL 045 — 8/22 (SAT) @ BOOGIE 54</title>|' \
 -e 's|<div class="subtitle">ディスカウントクーポン</div>|<div class="subtitle">The Sound of Those Days</div>|' \
 -e '/<section class="invited"/,/<\/section>/d' \
 -e '/<section class="coupon"/,/<\/section>/d' \
 -e "s|{{GA4_ID}}|${GA4_ID}|g" \
 -e 's|{{LOGO_SRC}}|logo.png|g' \
 _template_discount.html > index.html
echo "wrote  index.html"

# README.md から token を再利用する。prefix でディスカウント(x) / アーティスト(xa)を区別。
readme_lookup_token() {
  local dj="$1"
  local prefix="$2"
  if [[ ! -f README.md ]]; then
    return 1
  fi
  local token
  token=$(awk -F'|' -v dj=" ${dj} " -v p="/${prefix}-" '
    $2 == dj && index($4, p) {
      gsub(/[ \t]/, "", $3)
      print $3
      exit
    }
  ' README.md)
  if [[ -n "$token" ]]; then
    echo "$token"
    return 0
  fi
  return 1
}

# (dj, token) を1行ずつ書く一時ファイル（macOS bash 3.2 で連想配列が使えないため）
disc_map=$(mktemp)
artist_map=$(mktemp)
trap 'rm -f "$disc_map" "$artist_map"' EXIT

generate() {
  local dj="$1"
  local prefix="$2"
  local template="$3"
  local map_file="$4"

  local token
  if token=$(readme_lookup_token "$dj" "$prefix"); then
    echo "reuse  ${dj}  ->  ${prefix}-${token}"
  else
    token=$(openssl rand -hex 3)
    echo "new    ${dj}  ->  ${prefix}-${token}"
  fi
  printf '%s\t%s\n' "$dj" "$token" >> "$map_file"

  local dir="${prefix}-${token}"
  mkdir -p "$dir"
  sed -e "s|{{DJ_NAME}}|${dj}|g" \
      -e "s|{{TITLE_SUFFIX}}| (${dj})|g" \
      -e "s|{{GA4_ID}}|${GA4_ID}|g" \
      -e 's|{{LOGO_SRC}}|../logo.png|g' \
      "$template" > "${dir}/index.html"
  echo "wrote  ${dir}/index.html"
}

for dj in "${DJS[@]}"; do
  generate "$dj" "x" "_template_discount.html" "$disc_map"
done

for dj in "${DJS[@]}"; do
  generate "$dj" "xa" "_template_artist.html" "$artist_map"
done

{
  echo "# STILL 045 — 関係者専用URL一覧"
  echo
  echo "8/22 (SAT) @ BOOGIE 54。DJ別の関係者専用クーポンURL。ルートはイベント案内のみ（クーポンなし）。"
  echo
  echo "## URL一覧"
  echo
  echo "**ルート（イベント案内のみ）:** https://puenots.github.io/still045-coupon/"
  echo
  echo "**DJ別 ディスカウント（¥2,500 → ¥2,000）:**"
  echo
  echo "| DJ | トークン | URL |"
  echo "|----|---------|-----|"
  while IFS=$'\t' read -r dj token; do
    echo "| ${dj} | ${token} | https://puenots.github.io/still045-coupon/x-${token}/ |"
  done < "$disc_map"
  echo
  echo "**DJ別 関係者ディスカウント（¥2,500 → ¥1,000）:**"
  echo
  echo "| DJ | トークン | URL |"
  echo "|----|---------|-----|"
  while IFS=$'\t' read -r dj token; do
    echo "| ${dj} | ${token} | https://puenots.github.io/still045-coupon/xa-${token}/ |"
  done < "$artist_map"
  echo
  echo "## ビルド"
  echo
  echo '```bash'
  echo "./build.sh"
  echo '```'
  echo
  echo "既存トークンは README.md から再利用されるため、再ビルドしてもURLは変わらない。"
  echo "GA4 測定IDは build.sh 冒頭の GA4_ID を設定して再ビルドすると全ページに入る。"
} > README.md

echo "wrote  README.md"
