---
title: MIDI 2.0 対応状況（2026-02-11 スナップショット）
lang: ja
permalink: /ja/midi2-support-status-2026/
---

# MIDI 2.0 対応状況（2026-02-11 スナップショット）

このページは、2026-02-11 時点で公開情報から確認できる MIDI 2.0 対応状況を整理したものです。

注意:
- 「対応」は **OS API/ドライバ対応** と **DAW/アプリの実装対応** が別です。
- DAWは「一部機能対応（例: CVM, PE, Profile）」と「全面対応」を分けて見る必要があります。

## 更新情報
- 更新日: `2026-02-11`
- 対象期間: `2026-01-12 .. 2026-02-11`
- 前回レポート: `初回作成（比較対象なし）`
- データ取得日時（UTC）: `2026-02-11`

## 差分サマリー（前回比）
初回作成のため、前回差分は `N/A` です。  
次回更新から、月次テンプレートの「前回/今回/差分」を埋めて運用します。

## 要確認項目（次回更新まで）
- [ ] Windows MIDI Services の一般提供範囲（24H2/25H2）を再確認
- [ ] DAW別の MIDI 2.0 実装範囲（CVM/PE/Profile）を製品単位で再確認
- [ ] Linux kernel / ALSA の関連更新（MIDI 2.0, UMP, gadget）を再確認
- [ ] GitHub主要リポジトリのスター数と更新日を再採取

## 1. OS 対応状況

### Windows
- Windows MIDI Services が公開され、USB MIDI 2.0 Class Driver / UMP / MIDI-CI / Virtual Devices / Network MIDI 2.0 を提供。
- Insider Preview での in-box 配布開始（2025-02-05）以降、一般リリースの段階移行が進行。
- 2026-02-07 時点の更新では、Windows 11 24H2/25H2 向けに順次配布中と説明。

参照:
- [Windows MIDI Services](https://github.com/microsoft/MIDI)
- [Windows MIDI Services Website](https://microsoft.github.io/MIDI/)
- [Windows Insider: MIDI 2.0 and more](https://blogs.windows.com/windows-insider/2025/02/05/announcing-windows-11-insider-preview-build-27788-canary-channel/)

### Apple（macOS / iOS / iPadOS）
- CoreMIDI に MIDI 2.0 関連API（UMP系）が用意され、MIDI 2.0 の実装ガイドが公開されている。
- 業界団体側の公開情報では、Apple 側での MIDI 2.0 実装が進んでいると説明されている。

参照:
- [Apple: Incorporating MIDI 2 into your apps](https://developer.apple.com/documentation/coremidi/incorporating-midi-2-into-your-apps)
- [Apple: MIDIUniversalMessage](https://developer.apple.com/documentation/coremidi/midiuniversalmessage)
- [Apple: MIDIUMPEndpoint](https://developer.apple.com/documentation/coremidi/midiumpendpoint)
- [MIDI.org DAW WG update (2026-02-10)](https://midi.org/midi-daw-working-group-releases-developer-tools-and-profiles-at-2026-namm-show)

### Android
- Android 13（API 33）以降で USB経由の MIDI 2.0 / UMP を扱うAPIが導入。
- Android V では仮想MIDI 2.0サービスにも言及。

参照:
- [Android MIDI API](https://developer.android.com/reference/android/media/midi/package-summary)

### Linux
- Linux kernel docs によると、MIDI 2.0 / UMP / legacy translation は v6.5 以降でサポート。
- v6.10 では USB MIDI 2.0 gadget driver の記載あり。
- OpenWrt 側でも 2025-11 に USB MIDI 2.0 関連モジュール追加のコミットあり（実験・先行導入系）。

参照:
- [Kernel docs: MIDI 2.0 on Linux](https://www.kernel.org/doc/html/v6.12/sound/designs/midi-2.0.html)
- [Kernel docs: USB MIDI 2.0 gadget driver](https://docs.kernel.org/6.10/usb/gadget-testing.html)
- [OpenWrt commit thread: add USB MIDI 2.0 modules](https://lists.openwrt.org/pipermail/openwrt-devel/2025-November/043908.html)

## 2. ハードウェア対応状況

業界団体（MIDI.org）の公開情報では、次の製品群が MIDI 2.0 実装例として継続的に挙げられています。
- Yamaha MONTAGE M
- Roland A-88MKII（v2.10）
- Native Instruments Kontrol S MK3
- Korg Keystage
- Studiologic SL mk2 series
- Waldorf Iridium Core

参照:
- [MIDI Innovation Awards 2024 - Product Examples](https://midi.org/midi-innovation-awards-2024)
- [Latest MIDI 2.0 developments in hardware (MIDI.org)](https://midi.org/latest-midi2-developments-in-hardware)
- [Yamaha MONTAGE M MIDI 2.0 features](https://asia-oceania.yamaha.com/en/products/contents/music_production/midi-2-0/index.html)
- [Roland A-88MKII v2.10 preview notes](https://www.roland.com/global/support/by_product/a-88mk2/updates_drivers/f5f554ce-f304-48bf-8152-2f008ad8d6fd/)

## 3. ソフトウェア / DAW 対応状況

### DAW（公表ベース）
- MIDI.org の公開資料・発表では、Logic Pro / Cubase / MultitrackStudio などで MIDI 2.0 機能の実装実績が報告。
- ただし実際は「MIDI 2.0 の一部機能対応」が中心で、機能範囲は DAW とOS依存。

参照:
- [MIDI DAW Working Group update (2026-02-10)](https://midi.org/midi-daw-working-group-releases-developer-tools-and-profiles-at-2026-namm-show)
- [MIDI Innovation Awards 2024 (DAW column)](https://midi.org/midi-innovation-awards-2024)

### 実装詳細が公開されている例
- MultitrackStudio は MIDI 2.0 protocol / per-note control / MIDI Clip File(.midi2) / PE を明示。
- ただし同ページ内で「WindowsのMIDI device関連機能は現時点で未利用」と注記（Windows MIDI Services待ち）。

参照:
- [MultitrackStudio Manual: MIDI 2.0 Overview](https://www.multitrackstudio.com/midi2.php)

### Windows DAW 周辺
- Steinberg の公開記事では Cubase 14 で WinRT MIDI をサポート（Bluetooth MIDIなど）と説明。
- これは「Windowsトランスポート対応」の話であり、MIDI 2.0 全機能対応とは別に評価が必要。

参照:
- [Steinberg: WinRT MIDI support in Cubase 14](https://blog.ultimateoutsider.com/2024/11/coming-soon-winrt-midi-support-in.html)

## 4. Linux等の実験的プロジェクト

### MIDI 2.0 Workbench / Dev tooling
- MIDI 2.0 Workbench は CI/UMP 検証用ツールとして公開。
- 2026-01-27 更新の v1.5.0 では CI 1.2、PE 1.2 などへの追随が見える。
- Linux要件として `kernel 6.5+` と `ALSA 1.2.10+` が記載。

参照:
- [midi2-dev/MIDI2.0Workbench](https://github.com/midi2-dev/MIDI2.0Workbench)
- [MIDI2Workbench v1.5.0 release note](https://github.com/midi2-dev/MIDI2.0Workbench/releases/tag/v1.5.0)

### 組み込み/ライブラリ系
- `midi2-dev/tusb_ump`: TinyUSB ベースの USB MIDI 2.0 device driver
- `midi2-dev/ni-midi2`: UMP 1.1 / MIDI-CI 1.2 実装ライブラリ
- `midi2-dev/AM_MIDI2.0Lib`: C++ MIDI 2.0 ライブラリ

参照:
- [midi2-dev/tusb_ump](https://github.com/midi2-dev/tusb_ump)
- [midi2-dev/ni-midi2](https://github.com/midi2-dev/ni-midi2)
- [midi2-dev/AM_MIDI2.0Lib](https://github.com/midi2-dev/AM_MIDI2.0Lib)

## 5. GitHub 動向（2026-02-11 取得）

主要リポジトリの観測値（スター数/最終更新日）:

| Repository | Stars | Updated (UTC) | URL |
|---|---:|---|---|
| microsoft/MIDI | 509 | 2026-02-10 | https://github.com/microsoft/MIDI |
| celtera/libremidi | 648 | 2026-02-11 | https://github.com/celtera/libremidi |
| orchetect/MIDIKit | 322 | 2026-02-03 | https://github.com/orchetect/MIDIKit |
| alsa-project/alsa-lib | 453 | 2026-02-10 | https://github.com/alsa-project/alsa-lib |
| midi2-dev/MIDI2.0Workbench | 83 | 2026-01-27 | https://github.com/midi2-dev/MIDI2.0Workbench |
| midi2-dev/ni-midi2 | 52 | 2026-01-31 | https://github.com/midi2-dev/ni-midi2 |
| midi2-dev/AM_MIDI2.0Lib | 59 | 2026-02-09 | https://github.com/midi2-dev/AM_MIDI2.0Lib |

## 6. 実装者向けの読み方
- OS API対応とDAW機能対応を混同しない
- 「Get/Set可能プロパティ」はPE仕様バージョンで差分が出る
- 2026時点では、**OS先行 -> ライブラリ/ツール追随 -> DAW機能拡張** の流れが明確

関連ページ:
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
- [Property Exchange（PE）]({{ '/ja/property-exchange/' | relative_url }})
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
