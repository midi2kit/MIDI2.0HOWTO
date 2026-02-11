---
title: MIDI2Kit とは？できること・まだできないこと
lang: ja
permalink: /ja/midi2kit/
---

# MIDI2Kit とは？できること・まだできないこと

`MIDI2Kit` は、Apple プラットフォーム向けの Swift 製 MIDI 2.0 ライブラリです。  
公開情報では、`UMP`、`MIDI-CI`、`Property Exchange (PE)` を実装するための SDK として案内されています。

更新日: `2026-02-11`

## 1. MIDI2Kit の位置づけ
- 対象: `iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+ / visionOS 1+`
- 言語・実装スタイル: Swift 6 + async/await + actor ベース
- 想定ユースケース: MIDI 2.0 対応アプリの Discovery / DeviceInfo / PE 実装

## 2. できること

### 2.1 MIDI-CI Discovery と接続管理
- MIDI-CI 対応デバイスの検出
- Capability 交渉
- デバイスの発見・更新・ロスト通知のストリーム処理

### 2.2 Property Exchange（PE）
- DeviceInfo 取得
- ResourceList 取得
- 任意リソースへの `Get` / `Set`
- `Subscribe`（通知）対応
- バッチ Set・パイプライン処理・ペイロード検証（公開ドキュメント記載）

補足（X-Parameter系）:
- `X-ParameterList` の取得で、`controlcc/name/default/min/max/category` を取得可能
- `X-ProgramEdit` の取得で、現在プログラム名・カテゴリ・CC現在値を取得可能
- 送信可能かは固定ではなく、`ResourceList` の `canSet` 判定で確認する運用が推奨

### 2.3 UMP / 変換系
- MIDI 1.0 SysEx <-> UMP SysEx7(Data64) 変換
- 分割された SysEx7 の再構成（アセンブラ）
- UMP RPN/NRPN -> MIDI 1.0 CC 近似変換

### 2.4 高レベル API とデバッグ支援
- `MIDI2Client` による高レベル操作
- ログ制御、診断情報、通信トレース
- MockDevice / CI Responder を使ったテスト運用

## 3. まだできないこと・制約

### 3.1 プラットフォーム制約
- 現状は Apple プラットフォーム向けが中心です。
- Windows / Linux / Android 向けの公式 SDK としては案内されていません。

### 3.2 同一 iOS 端末内の他社アプリ連携
- 公式ガイドでは、同一端末内の「他社アプリ」との MIDI-CI/PE は一般に難しいと説明されています。
- 主因は、相手側アプリが Virtual Port で MIDI-CI を受けない実装であるケースです。

### 3.3 一部機器での PE 信頼性課題（既知）
- KORG Module Pro との組み合わせでは、`ResourceList` のような multi-chunk 応答が不安定になる既知問題があります。
- MIDI2Kit 側は warm-up、リトライ、フォールバックなどの回避策を提供しています。

### 3.4 変換の精度上の注意
- RPN/NRPN -> MIDI 1.0 CC 変換は「近似」です。
- 32bit 分解能を MIDI 1.0 側へ落とすため、情報圧縮が発生します。

### 3.5 Profile 領域の扱い
- 公開 README の高レベル API 一覧は Discovery / DeviceInfo / PE 操作が中心です。
- Profile の有効化/無効化を主軸にした運用では、要件に応じて追加実装の確認が必要です。

## 4. こういう用途に向いている
- Apple アプリで MIDI 2.0 対応を実装したい
- Discovery / DeviceInfo / PE を実装の主軸にしたい
- MockDevice を使ってハードなしで CI/PE テストを回したい
- SysEx と UMP の相互変換をアプリ内で扱いたい

## 5. 関連ページ
- [MIDI 2.0 基礎概念]({{ '/ja/fundamentals/' | relative_url }})
- [MIDI2Kit 競合比較]({{ '/ja/midi2kit-competitive-comparison/' | relative_url }})
- [Initiator / Responder 詳解（MIDI-CI 実装）]({{ '/ja/initiator-responder/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
- [Property Exchange（PE）]({{ '/ja/property-exchange/' | relative_url }})

## 6. 参考リンク（公式）
- [midi2kit.dev](https://midi2kit.dev/)
- [MIDI2Kit-SDK (GitHub)](https://github.com/midi2kit/MIDI2Kit-SDK)
- [README: MIDI2Kit-SDK](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/README.md)
- [Guide: Inter-App MIDI-CI Limitations](https://midi2kit.dev/guides/inter-app-midi-ci.html)
- [Known Limitations: KORG Module Pro](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/docs/KORG-Module-Pro-Limitations.md)
