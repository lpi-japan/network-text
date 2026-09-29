# network-text

Linuxネットワーク標準教科書の開発用リポジトリ。

原稿（`Chapter*.md` と `image/`）はリポジトリ直下にある。日英・ディストリビューション別のバリアントはまだ無い。後から増やすときは server-text と同様、バリアント用ディレクトリを足して `pandoc.yaml` の `working-directory` を切り替える。

## ローカルビルド

```bash
docker build -t ghcr.io/lpi-japan/network-text:local build
./build/build-pdf.sh    # tmp/networktext_<ver>.pdf と _no_cover.pdf
./build/build-epub.sh   # tmp/networktext_<ver>.epub
```

ホストに pandoc / lualatex が無い場合、スクリプトが上記イメージ内で再実行する。

ビルド時に Git の先頭コミット（12 文字、`git=<sha>`、未コミット変更時は `-dirty`）をメタデータに載せる。版面には出ない。

- PDF: `Keywords`（例: `pdfinfo tmp/networktext_1.0.0.pdf | grep Keywords` / `exiftool -Keywords tmp/networktext_1.0.0.pdf`）
- EPUB: `Description`（例: `exiftool -Description tmp/networktext_1.0.0.epub`）
