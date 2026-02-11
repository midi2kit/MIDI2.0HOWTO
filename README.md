# MIDI2.0 HOWTO

このプロジェクトは MIDI 2.0 の理解を深めるためのドキュメント集です。  
GitHub Pages で公開できるようにし、将来の多言語化を前提とした構成にしています。

## 目的
- MIDI 2.0 の仕様を段階的に理解する
- 実装時に迷いやすいポイントを整理する
- 実験メモやサンプルへの導線を残す

## サイト構成
- `index.md`: 言語選択トップ
- `ja/`: 日本語ドキュメント
- `en/`: 英語ドキュメント（翻訳用ひな形）
- `_layouts/default.html`: 共通レイアウト
- `_config.yml`: Jekyll 設定
- `.github/workflows/pages.yml`: GitHub Pages デプロイ

## GitHub Pages 公開手順
1. GitHub リポジトリの `Settings` を開く
2. `Pages` で `Build and deployment` の `Source` を `GitHub Actions` に設定
3. `main` または `master` に push すると workflow が実行され、公開される
4. リポジトリ名を変更した場合は `_config.yml` の `baseurl` も同じ値に更新する

## 多言語運用ルール
- 言語ごとにディレクトリを分ける（例: `ja/`, `en/`）
- URL は固定で運用する（例: `/ja/ump/`, `/en/ump/`）
- 新規ページは原則 `ja` と `en` の両方に作成し、未翻訳時は英語側にステータスを明記する
- ルートアクセス時はブラウザ言語に合わせて `ja/en` を自動選択し、手動切替結果を保持する

## 執筆ルール
- 1トピック1ファイルで追加する
- 仕様を参照した場合は出典 URL を併記する
- 未確定事項は `TODO:` を付けて残す
