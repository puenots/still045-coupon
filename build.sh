#!/bin/bash
# STILL 045 パスページを生成する。
# - ディスカウント / イエロー (¥2,500→¥2,000)          : _template_discount.html → ${slug}/
# - スペシャル / オレンジ (¥2,500→¥1,500)                : _template_special.html  → ${slug}-1500/
# - 音楽関係者 / ブルー (¥2,500→¥1,000・UEのみ発行)  : _template_artist.html   → ${slug}-sp/
# - フリー / ピンク (FREE・音楽関係者のみ・UEのみ発行)  : _template_free.html     → ${slug}-free/
# - ルート (イベント案内のみ・クーポンなし) : _template_discount.html から生成 → index.html
# URLは読めるスラッグ固定（例: /ue/ と /ue-sp/）。独自ドメイン 045.djue.me で公開。
# チケットの地色は受付で渡すリストバンドの色と同じ（イエロー/オレンジ/ブルー/ピンク。当日客=グリーンはバンドのみ）。
# _template_special.html / _template_artist.html / _template_free.html は _template_discount.html から派生生成する（正本は discount 側）。

set -euo pipefail

cd "$(dirname "$0")"

BASE_URL="https://045.djue.me"

# GA4 測定ID。digtracks プロパティ (319283938) に相乗り。
# レポート時は hostname = 045.djue.me で絞る（page_title に DJ 名とクーポン種別が入る）。
GA4_ID="G-4N9ENSKWVH"

# "表示名|スラッグ"
DJS=("DJ Garnet|garnet" "UE|ue" "KEIGO|keigo" "AMARI|amari" "鍋奉行|nabe" "BAPE|bape" "Yuuki|yuuki" "TAKEDA|takeda" "BOOGIE54|boogie54")
# 音楽関係者パス (¥1,000) を発行する人
ARTIST_DJS=("UE|ue")
# フリーパスを発行する人
FREE_DJS=("UE|ue")

# _template_artist.html を discount 版から派生させる
sed \
 -e 's|DISCOUNT PASS{{TITLE_SUFFIX}}|GUEST PASS{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">Guest Pass</div>|' \
 -e 's|--ticket-a: #f7d21e;|--ticket-a: #47b6f0;|' \
 -e 's|--ticket-b: #e6b900;|--ticket-b: #2391d6;|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">¥1,000</div>|' \
 -e 's|aria-label="ディスカウントパス">|aria-label="関係者パス">|' \
 -e 's|<div class="coupon-tag"></div>|<div class="coupon-tag">音楽関係者専用</div>|' \
 -e 's@STILL 045 | DISCOUNT PASS ¥2,500 → ¥2,000@STILL 045 | GUEST PASS ¥2,500 → ¥1,000@' \
 _template_discount.html > _template_artist.html
echo "wrote  _template_artist.html"

# _template_special.html を discount 版から派生させる
sed \
 -e 's|DISCOUNT PASS{{TITLE_SUFFIX}}|SPECIAL PASS{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">Special Pass</div>|' \
 -e 's|--ticket-a: #f7d21e;|--ticket-a: #e07a35;|' \
 -e 's|--ticket-b: #e6b900;|--ticket-b: #c9631f;|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">¥1,500</div>|' \
 -e 's|aria-label="ディスカウントパス">|aria-label="スペシャルパス">|' \
 -e 's@STILL 045 | DISCOUNT PASS ¥2,500 → ¥2,000@STILL 045 | SPECIAL PASS ¥2,500 → ¥1,500@' \
 _template_discount.html > _template_special.html
echo "wrote  _template_special.html"

# _template_free.html を discount 版から派生させる
sed \
 -e 's|DISCOUNT PASS{{TITLE_SUFFIX}}|FREE PASS{{TITLE_SUFFIX}}|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">Free Pass</div>|' \
 -e 's|--ticket-a: #f7d21e;|--ticket-a: #ff6ab5;|' \
 -e 's|--ticket-b: #e6b900;|--ticket-b: #ef3f90;|' \
 -e 's|<div class="coupon-value">¥2,000</div>|<div class="coupon-value">FREE</div>|' \
 -e 's|aria-label="ディスカウントパス">|aria-label="フリーパス">|' \
 -e 's|<div class="coupon-tag"></div>|<div class="coupon-tag">フリーゲスト（音楽関係者のみ）</div>|' \
 -e 's@STILL 045 | DISCOUNT PASS ¥2,500 → ¥2,000@STILL 045 | FREE PASS（音楽関係者のみ）@' \
 _template_discount.html > _template_free.html
echo "wrote  _template_free.html"

# ルートページ: クーポン・招待セクションを除いたイベント案内（カウントダウンは残す）
sed \
 -e 's|<title>STILL 045 — DISCOUNT PASS{{TITLE_SUFFIX}}</title>|<title>STILL 045 — 10/24 (SAT) @ BOOGIE 54</title>|' \
 -e 's|<div class="subtitle">Discount Pass</div>|<div class="subtitle">The Sound of Those Days</div>|' \
 -e 's#STILL 045 | DISCOUNT PASS ¥2,500 → ¥2,000#STILL 045 | 10/24 (SAT) @ BOOGIE 54#' \
 -e '/<section class="invited"/,/<\/section>/d' \
 -e '/<section class="coupon"/,/<\/section>/d' \
 -e "s|{{GA4_ID}}|${GA4_ID}|g" \
 -e "s|{{BASE_URL}}|${BASE_URL}|g" \
 -e "s|{{OG_IMAGE}}|${BASE_URL}/ogp.jpg|g" \
 -e 's|{{LOGO_SRC}}|logo.png|g' \
 -e 's|{{GROUP_NOTE}}||g' \
 -e 's|{{BAND_NOTE}}||g' \
 _template_discount.html > index.html
echo "wrote  index.html"

# (dj, slug) を1行ずつ書く一時ファイル
disc_map=$(mktemp)
special_map=$(mktemp)
artist_map=$(mktemp)
free_map=$(mktemp)
trap 'rm -f "$disc_map" "$special_map" "$artist_map" "$free_map"' EXIT

# 人数注記。空文字なら .coupon-group:empty で非表示になる。
GROUP_NOTE_DISCOUNT=""
GROUP_NOTE_SPECIAL=""
GROUP_NOTE_ARTIST="1枚で3名まで有効"
GROUP_NOTE_FREE="1枚で3名まで有効"

# リストバンド注記（チケット地色と同じ色のバンドを受付で渡す）。空文字なら .coupon-band:empty で非表示。
BAND_NOTE_DISCOUNT="受付でイエローのリストバンドをお渡しします"
BAND_NOTE_SPECIAL="受付でオレンジのリストバンドをお渡しします"
BAND_NOTE_ARTIST="受付でブルーのリストバンドをお渡しします"
BAND_NOTE_FREE="受付でピンクのリストバンドをお渡しします"

generate() {
  local dj="$1"
  local dir="$2"
  local template="$3"
  local map_file="$4"
  local group_note="$5"
  local band_note="$6"

  printf '%s\t%s\n' "$dj" "$dir" >> "$map_file"

  mkdir -p "$dir"
  sed -e "s|{{DJ_NAME}}|${dj}|g" \
      -e "s|{{TITLE_SUFFIX}}| (${dj})|g" \
      -e "s|{{GA4_ID}}|${GA4_ID}|g" \
      -e "s|{{BASE_URL}}|${BASE_URL}|g" \
      -e "s|{{OG_IMAGE}}|${BASE_URL}/og/${dir}.jpg|g" \
      -e 's|{{LOGO_SRC}}|../logo.png|g' \
      -e "s|{{GROUP_NOTE}}|${group_note}|g" \
      -e "s|{{BAND_NOTE}}|${band_note}|g" \
      "$template" > "${dir}/index.html"
  echo "wrote  ${dir}/index.html"
}

for entry in "${DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "$slug" "_template_discount.html" "$disc_map" "$GROUP_NOTE_DISCOUNT" "$BAND_NOTE_DISCOUNT"
  generate "$dj" "${slug}-1500" "_template_special.html" "$special_map" "$GROUP_NOTE_SPECIAL" "$BAND_NOTE_SPECIAL"
done

for entry in "${ARTIST_DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "${slug}-sp" "_template_artist.html" "$artist_map" "$GROUP_NOTE_ARTIST" "$BAND_NOTE_ARTIST"
done

for entry in "${FREE_DJS[@]}"; do
  dj="${entry%%|*}"
  slug="${entry##*|}"
  generate "$dj" "${slug}-free" "_template_free.html" "$free_map" "$GROUP_NOTE_FREE" "$BAND_NOTE_FREE"
done

{
  echo "# STILL 045 — パスURL一覧"
  echo
  echo "10/24 (SAT) @ BOOGIE 54。DJ別のパスURL。ルートはイベント案内のみ（パスなし）。"
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
  echo "**DJ別 スペシャル（¥2,500 → ¥1,500）:**"
  echo
  echo "| DJ | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$special_map"
  echo
  echo "**音楽関係者（¥2,500 → ¥1,000・UEのみ発行）:**"
  echo
  echo "| DJ | URL |"
  echo "|----|-----|"
  while IFS=$'\t' read -r dj dir; do
    echo "| ${dj} | ${BASE_URL}/${dir}/ |"
  done < "$artist_map"
  echo
  echo "**フリーパス（FREE・音楽関係者のみ・UEのみ発行）:**"
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
