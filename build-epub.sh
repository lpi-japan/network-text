#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT_DIR}/tmp"
HL_CSS_KINDLE="${OUT_DIR}/.highlighting-kindle.css"
VER="$(grep -oP 'Ver\.\d+\.\d+\.\d+' "${ROOT_DIR}/config-epub.yaml" | head -1 | sed 's/^Ver\.//')"
OUTPUT="${OUT_DIR}/networktext_${VER}.epub"
BUILD_DIR="${ROOT_DIR}/.epub-build"

if ! command -v pandoc >/dev/null 2>&1 || ! command -v pandoc-crossref >/dev/null 2>&1; then
  exec "${ROOT_DIR}/scripts/with-build-image.sh" "./build-epub.sh"
fi

mkdir -p "${OUT_DIR}" "${BUILD_DIR}"
rm -rf "${BUILD_DIR:?}/"*

# PDF と同様、原稿を結合せず複数入力で渡す。
inputs=()
for f in $(ls -1 "${ROOT_DIR}"/Chapter*.md | LC_ALL=C sort -V); do
  base="$(basename "${f}")"
  sed 's/^####.*/#& {-}/' "${f}" > "${BUILD_DIR}/${base}"
  inputs+=("${BUILD_DIR}/${base}")
done

if ((${#inputs[@]} == 0)); then
  echo "no chapter markdown files found" >&2
  exit 1
fi

# Kindle Previewer doubles skylighting lines when display:inline-block (pandoc#8528).
prepare_kindle_highlighting_css() {
  local sample_md hl_tpl hl_default
  sample_md="${OUT_DIR}/.hl-sample.md"
  hl_tpl="${OUT_DIR}/.hl-extract.tpl"
  hl_default="${OUT_DIR}/.highlighting-default.css"
  printf '%s\n' '```bash' 'x' '```' > "${sample_md}"
  printf '%s\n' '$highlighting-css$' > "${hl_tpl}"
  pandoc "${sample_md}" --template="${hl_tpl}" -t html -o "${hl_default}"
  python3 - "${hl_default}" "${HL_CSS_KINDLE}" <<'PY'
import sys
from pathlib import Path

src, dst = Path(sys.argv[1]), Path(sys.argv[2])
old = "pre > code.sourceCode > span { display: inline-block; line-height: 1.25; }"
new = "pre > code.sourceCode > span { display: inline; line-height: 1.25; }"
text = src.read_text(encoding="utf-8")
if old not in text:
    raise SystemExit(f"expected skylighting rule not found in {src}")
dst.write_text(text.replace(old, new), encoding="utf-8")
print(f"Prepared Kindle-safe highlighting CSS: {dst}")
PY
}

prepare_kindle_highlighting_css

(
  cd "${ROOT_DIR}"
  pandoc "${inputs[@]}" \
    -t epub3 \
    -F pandoc-crossref \
    -o "${OUTPUT}" \
    -N \
    -M "crossrefYaml=crossref.yaml" \
    --metadata-file=config-epub.yaml \
    --epub-cover-image=image/Cover/電子版表紙_300dpi_2480x3508.png \
    --css=epub.css \
    -V highlighting-css="$(cat "${HL_CSS_KINDLE}")"
)

echo "Output: ${OUTPUT}"
ls -lh "${OUTPUT}"
