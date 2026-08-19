#!/bin/bash
# STILL 045 クーポンページを生成する。
# - ディスカウント (¥2,500→¥2,000)       : _template_discount.html → ${slug}/
# - 関係者ディスカウント (¥2,500→¥1,000) : _template_artist.html   → ${slug}-sp/
# - ルート (イベント案内のみ・クーポンなし) : _template_discount.html から生成 → index.html
# URLは読めるスラッグ固定（例: /ue/ と /ue-sp/）。独自ドメイン 045.djue.me で公開。
# _template_artist.html は _template_discount.html から派生生成する（正本は discount 側）。

set -euo pipefail

cd "$(dirname "$0")"

BASE_URL="https://045.djue.me"

# GA4 測定ID。digtracks プロパティ (319283938) に相乗り。
# レポート時は hostname = 045.djue.me で絞る（page_title に DJ 名とクーポン種別が入る）。
GA4_ID="G-4N9ENSKWVH"

# "表示名|スラッグ"
DJS=("DJ TAC|tac" "UE|ue" "KEIGO|keigo" "鍋奉行|nabe" "BAPE|bape" "Yuuki|yuuki" "TAKEDA|takeda")
FREE_DJS=("UE|ue")

# _template_artist.html を discount 版から派生させる
sed \
 -e 's|DISCOUNT PASS{{TITLE_SUFFIX}}|GUEST PASS{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">Guest Pass</div>|' \
 -e 's|--ticket-a: #e07a35;|--ticket-a: #f0e4c8;|' \
 -e 's|--ticket-b: #c9631f;|--ticket-b: #d9c69a;|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">¥1,000</div>|' \
 -e 's|aria-label="ディスカウントパス">|aria-label="関係者パス">|' \
 -e 's|<div class="coupon-tag"></div>|<div class="coupon-tag">関係者専用</div>|' \
 _template_discount.html > _template_artist.html
echo "wrote  _template_artist.html"

# _template_free.html を discount 版から派生させる
sed \
 -e 's|DISCOUNT PASS{{TITLE_SUFFIX}}|FREE PASS{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">Free Pass</div>|' \
 -e 's|--ticket-a: #e07a35;|--ticket-a: #8dbbdd;|' \
 -e 's|--ticket-b: #c9631f;|--ticket-b: #5e93bd;|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">FREE</div>|' \
 -e 's|aria-label="ディスカウントパス">|aria-label="フリーパス">|' \
 -e 's|<div class="coupon-tag"></div>|<div class="coupon-tag">音楽関係者のみ</div>|' \
 _template_discount.html > _template_free.html
echo "wrote  _template_free.html"

# ルートページ: クーポン・招待セクションを除いたイベント案内（カウントダウンは残す）
sed \
 -e 's|<title>STILL 045 — DISCOUNT PASS{{TITLE_SUFFIX}}</title>|<title>STILL 045 — 8/22 (SAT) @ BOOGIE 54</title>|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">The Sound of Those Days</div>|' \
 -e '/<section class="invited"/,/<\/section>/d' \
 -e '/<section class="coupon"/,/<\/section>/d' \
 -e "s|{{GA4_ID}}|${GA4_ID}|g" \
 -e "s|{{BASE_URL}}|${BASE_URL}|g" \
 -e 's|{{LOGO_SRC}}|logo.png|g' \
 _template_discount.html > index.html
echo "wrote  index.html"

# (dj, slug) を1行ずつ書く一時ファイル
disc_map=$(mktemp)
artist_map=$(mktemp)
free_map=$(mktemp)
trap 'rm -f "$disc_map" "$artist_map" "$free_map"' EXIT

generate() {
  local dj="$1"
  local dir="$2"
  local template="$3"
  local map_file="$4"

  printf '%s\t%s\n' "$dj" "$dir" >> "$map_file"

  mkdir -p "$dir"
  sed -e "s|{{DJ_NAME}}|${dj}|g" \
      -e "s|{{TITLE_SUFFIX}}| (${dj})|g" \
      -e "s|{{GA4_ID}}|${GA4_ID}|g" \
      -e "s|{{BASE_URL}}|${BASE_URL}|g" \
      -e 's|{{LOGO_SRC}}|../logo.png|g' \
      "$template" > "${dir}/index.html"
  echo "wrote  ${dir}/index.html"
}

for entry in "${DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "$slug" "_template_discount.html" "$disc_map"
  generate "$dj" "${slug}-sp" "_template_artist.html" "$artist_map"
done

for entry in "${FREE_DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "${slug}-free" "_template_free.html" "$free_map"
done

{
  echo "# STILL 045 — クーポンURL一覧"
  echo
  echo "8/22 (SAT) @ BOOGIE 54。DJ別のクーポンURL。ルートはイベント案内のみ（クーポンなし）。"
  echo
  echo "## URL一覧"
  echo
  echo "**ルート（イベント案内のみ）:** ${BASE_URL}/"
  echo
  echo "**DJ別 ディスカウント（¥2,500 → ¥2,000）:**"
  echo
  echo "| DJ | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$disc_map"
  echo
  echo "**DJ別 関係者ディスカウント（¥2,500 → ¥1,000）:**"
  echo
  echo "| DJ | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$artist_map"
  echo
  echo "**DJ別 フリーパス（FREE）:**"
  echo
  echo "| DJ | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$free_map"
  echo
  echo "## ビルド"
  echo
  echo '```bash'
  echo "./build.sh"
  echo '```'
  echo
  echo "独自ドメイン: 045.djue.me（GoDaddy DNS で CNAME 045 → puenots.github.io）。"
  echo "GA4 測定IDは build.sh 冒頭の GA4_ID。"
} > README.md

echo "wrote  README.md"
