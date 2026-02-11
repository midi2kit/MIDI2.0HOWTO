---
title: MIDI 2.0 対応状況 月次更新テンプレート
lang: ja
permalink: /ja/midi2-support-monthly-template/
published: false
---

# MIDI 2.0 対応状況 月次更新テンプレート

このページは、`OS / ハードウェア / ソフトウェア・DAW / Linux実験系 / GitHub動向` を毎月同じ形式で更新するためのテンプレートです。

## 1. 更新メタ情報
- 更新日: `YYYY-MM-DD`
- 対象期間: `YYYY-MM-DD .. YYYY-MM-DD`
- 前回レポート: `リンク`
- 更新担当: `name`
- データ取得日時（UTC）: `YYYY-MM-DDTHH:MM:SSZ`
- 備考: `任意`

## 2. 差分サマリー（前回比）

| 領域 | 前回 | 今回 | 差分 | 影響度 |
|---|---|---|---|---|
| OS |  |  |  | 高/中/低 |
| ハードウェア |  |  |  | 高/中/低 |
| ソフトウェア/DAW |  |  |  | 高/中/低 |
| Linux実験系 |  |  |  | 高/中/低 |
| GitHub動向 |  |  |  | 高/中/低 |

## 3. 要確認項目（翌月までに確認）

| 優先度 | 項目 | 根拠リンク | 担当 | 期限 | 状態 |
|---|---|---|---|---|---|
| P0/P1/P2 |  |  |  | YYYY-MM-DD | Open/In Progress/Done |

## 4. 領域別アップデート

### 4.1 OS
- Windows:
  - 変更点:
  - 影響:
  - 参照:
- Apple:
  - 変更点:
  - 影響:
  - 参照:
- Android:
  - 変更点:
  - 影響:
  - 参照:
- Linux:
  - 変更点:
  - 影響:
  - 参照:

### 4.2 ハードウェア
- 変更点:
- 新規対応機種/FW:
- 参照:

### 4.3 ソフトウェア / DAW
- DAW別（Logic/Cubase/他）:
- 一部対応と全面対応の区別:
- 参照:

### 4.4 Linux等の実験的プロジェクト
- kernel / ALSA:
- Dev tools / libraries:
- 参照:

### 4.5 GitHub動向

| Repository | Stars(prev) | Stars(now) | Delta | Updated (UTC) | URL |
|---|---:|---:|---:|---|---|
| microsoft/MIDI |  |  |  |  |  |
| celtera/libremidi |  |  |  |  |  |
| orchetect/MIDIKit |  |  |  |  |  |
| alsa-project/alsa-lib |  |  |  |  |  |
| midi2-dev/MIDI2.0Workbench |  |  |  |  |  |
| midi2-dev/ni-midi2 |  |  |  |  |  |
| midi2-dev/AM_MIDI2.0Lib |  |  |  |  |  |

## 5. 収集コマンド例

```sh
gh repo view microsoft/MIDI --json stargazerCount,updatedAt,url
gh repo view celtera/libremidi --json stargazerCount,updatedAt,url
gh repo view orchetect/MIDIKit --json stargazerCount,updatedAt,url
gh repo view alsa-project/alsa-lib --json stargazerCount,updatedAt,url
gh repo view midi2-dev/MIDI2.0Workbench --json stargazerCount,updatedAt,url
gh repo view midi2-dev/ni-midi2 --json stargazerCount,updatedAt,url
gh repo view midi2-dev/AM_MIDI2.0Lib --json stargazerCount,updatedAt,url
```

## 6. 公開前チェックリスト
- [ ] 更新日と対象期間が正しい
- [ ] 差分が「前回比」で埋まっている
- [ ] 要確認項目に担当と期限がある
- [ ] すべての主張にリンクがある
- [ ] 日付は絶対日付（YYYY-MM-DD）で記載

## 7. 関連ページ
- [MIDI 2.0 対応状況（2026-02-11 スナップショット）]({{ '/ja/midi2-support-status-2026/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
