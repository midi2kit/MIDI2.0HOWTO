---
title: MIDI2Kit 競合比較（実装者向け）
lang: ja
permalink: /ja/midi2kit-competitive-comparison/
---

# MIDI2Kit 競合比較（実装者向け）

最終確認日: `2026-02-11`  
対象: MIDI 2.0 実装に使う主要OSS/SDKの比較

## 1. 先に結論（用途別）

1. Appleアプリで `MIDI-CI + PE` を最短で実装したい  
`MIDI2Kit-SDK` が第一候補。

2. Appleで CoreMIDI I/O を中心に柔軟に組みたい  
`MIDIKit` が有力。

3. C++ でクロスプラットフォーム（Windows/macOS/Linux）を狙う  
`libremidi` か `ni-midi2` を中心に設計。

4. 組み込み機器や小フットプリント重視  
`AM_MIDI2.0Lib` を検討。

5. Windows OS ネイティブ基盤に寄せたい  
`Windows MIDI Services` を採用。

## 2. 比較表

| プロジェクト | 主対象 | MIDI 2.0 範囲（公開情報） | 抽象度 | 向いているケース |
|---|---|---|---|---|
| [MIDI2Kit-SDK](https://github.com/midi2kit/MIDI2Kit-SDK) | Swift / Apple | UMP, MIDI-CI, PE, `Get/Set`, 高レベル `MIDI2Client` | 高 | Appleアプリで CI/PE をすぐ使いたい |
| [MIDIKit](https://github.com/orchetect/MIDIKit) | Swift / CoreMIDI | MIDI 1.0 / 2.0 対応 CoreMIDI wrapper | 中 | CoreMIDI中心で柔軟に組みたい |
| [libremidi](https://github.com/celtera/libremidi) | C++20 / Cross-platform | MIDI 1/2 リアルタイム&ファイルI/O、MIDI2対応、CI相互運用例あり | 中 | 複数OSで共通MIDI層を作りたい |
| [ni-midi2](https://github.com/midi2-dev/ni-midi2) | C++17 | UMP 1.1 + MIDI-CI 1.2 の型/ファクトリ/ビュー | 低〜中 | プロトコル層を厳密に実装したい |
| [AM_MIDI2.0Lib](https://github.com/midi2-dev/AM_MIDI2.0Lib) | C++ / Embedded〜App | MIDI1<->UMP変換、UMP処理、MIDI-CI処理（開発中） | 低〜中 | 組み込み寄りで軽量に組みたい |
| [Windows MIDI Services](https://github.com/microsoft/MIDI) | Windows API/Driver | MIDI 1.0 + MIDI 2.0（CI, UMP）, USB class driver など | OS基盤 | Windowsネイティブ実装を行う |

## 3. MIDI2Kit から見た差分

### 3.1 MIDI2Kit の強み
- CI/PE まで含めた高レベルAPIが最初からある
- `Get/Set`、診断、KORG向け最適化など実運用寄り機能がある
- Swift Concurrency 前提で Apple アプリに馴染む

### 3.2 MIDI2Kit の注意点
- 実質 Apple プラットフォーム中心
- Windows/Linux/Android 向けを1つのコードベースで統一する用途には不向き

## 4. 実装観点での選定軸

1. 対応OS  
Apple限定か、クロスプラットフォームか

2. 必要機能  
I/Oのみか、CI/PEまで必要か

3. 抽象度  
高レベルAPI重視か、低レベル制御重視か

4. 保守性  
仕様追従を自前で持つか、ライブラリへ寄せるか

## 5. 使い分け例

- `MIDI2Kit-SDK + ni-midi2`  
Appleクライアントは高速実装、テスト/検証側で低レベル検査を強化。

- `libremidi + Windows MIDI Services`  
アプリ共通層は libremidi、Windows固有機能は WMS で最適化。

- `AM_MIDI2.0Lib`（組み込み） + 上位アプリ側SDK  
機器側を軽量実装し、アプリ側で高レベルUI同期を実現。

## 6. 事実と推定の境界

このページの比較は、各プロジェクトの README / 公式説明に基づきます。  
「抽象度」や「向いているケース」は、それらの記述からの実装者視点の推定です。

## 7. 参照元（一次情報）

- [MIDI2Kit-SDK README](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/README.md)
- [MIDIKit README](https://github.com/orchetect/MIDIKit/blob/main/README.md)
- [libremidi README](https://github.com/celtera/libremidi/blob/master/README.md)
- [ni-midi2 README](https://github.com/midi2-dev/ni-midi2/blob/main/README.md)
- [AM_MIDI2.0Lib README](https://github.com/midi2-dev/AM_MIDI2.0Lib/blob/main/README.md)
- [Windows MIDI Services README](https://github.com/microsoft/MIDI/blob/main/README.md)
