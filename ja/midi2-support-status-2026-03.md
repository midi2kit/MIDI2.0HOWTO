---
title: MIDI 2.0 対応状況（2026-03 月次更新）
lang: ja
permalink: /ja/midi2-support-status-2026-03/
---

# MIDI 2.0 対応状況（2026-03 月次更新）

このページは月次フォーマットに基づいて自動生成されています。

## 更新情報
- 更新日: `2026-03-01`
- 対象期間: `2026-03-01 .. 2026-03-01`
- 前回レポート: [midi2-support-status-2026-02]({{ '/ja/midi2-support-status-2026-02/' | relative_url }})
- データ取得日時（UTC）: `2026-03-01`

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

## GitHub動向（2026-03-01 取得）

| Repository | Stars(prev) | Stars(now) | Delta | Updated (UTC) | URL |
|---|---:|---:|---:|---|---|
| microsoft/MIDI | 509 | 553 | +44 | 2026-02-28 | https://github.com/microsoft/MIDI |
| celtera/libremidi | 648 | 656 | +8 | 2026-02-24 | https://github.com/celtera/libremidi |
| orchetect/MIDIKit | 322 | 325 | +3 | 2026-03-01 | https://github.com/orchetect/MIDIKit |
| alsa-project/alsa-lib | 453 | 456 | +3 | 2026-02-28 | https://github.com/alsa-project/alsa-lib |
| midi2-dev/MIDI2.0Workbench | 83 | 83 | 0 | 2026-01-27 | https://github.com/midi2-dev/MIDI2.0Workbench |
| midi2-dev/ni-midi2 | 52 | 53 | +1 | 2026-02-16 | https://github.com/midi2-dev/ni-midi2 |
| midi2-dev/AM_MIDI2.0Lib | 59 | 62 | +3 | 2026-02-22 | https://github.com/midi2-dev/AM_MIDI2.0Lib |

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
