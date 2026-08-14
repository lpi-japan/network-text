# network-text

Linuxネットワーク標準教科書の開発用リポジトリ。

原稿（`Chapter*.md` と `image/`）はリポジトリ直下にある。日英・ディストリビューション別のバリアントはまだ無い。後から増やすときは server-text と同様、バリアント用ディレクトリを足して `pandoc.yaml` の `working-directory` を切り替える。

## ローカルビルド

```bash
docker build -t ghcr.io/lpi-japan/network-text:local .
./build-pdf.sh          # tmp/networktext_<ver>.pdf と _no_cover.pdf
./build-epub.sh         # tmp/networktext_<ver>.epub
```

ホストに pandoc / lualatex が無い場合、スクリプトが上記イメージ内で再実行する。
