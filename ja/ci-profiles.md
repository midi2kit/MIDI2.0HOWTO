---
title: MIDI-CI と Profiles
lang: ja
permalink: /ja/ci-profiles/
---

# MIDI-CI と Profiles（実装者向け）

このページは、MIDI-CI を「概念」ではなく実装タスクとして整理したものです。  
主眼は `Discovery -> Capability確定 -> Profile/PE運用` の設計です。

## 1. MIDI-CI の実装上の役割

MIDI-CI は、接続先デバイスの能力をランタイムで確定するプロトコルです。

- Discovery で MUID を確定する
- 各 Capability（Profile / Property Exchange / Process Inquiry）を照会する
- 共通対応機能だけを有効化する
- 非対応時は MIDI 1.0 相当へ安全にフォールバックする

実装的には「起動時に1回やる処理」ではなく、再接続時にも繰り返す状態遷移です。

## 2. 先に分離すべき責務

実装を壊れにくくするには、次の3層を分離します。

1. `CI Transport/Parser`  
SysExメッセージ送受信、MUID、タイムアウト管理。

2. `Capability Registry`  
デバイス単位で `supportsProfile` / `supportsPE` / `supportsPI` を保持。

3. `Feature Modules`  
Profile管理、PE、Process Inquiry を独立モジュール化。

この分離をしないと、Profile有効化や PE Set が接続管理ロジックに混ざり、再接続時の不具合を招きます。

## 3. 最小ステートマシン

実装の起点は状態機械です。

```text
Disconnected
  -> EndpointDetected
  -> CiDiscoveryDone
  -> CapabilityKnown
  -> Operational
  -> FallbackOperational
```

遷移条件の最低要件:
- `CiDiscoveryDone`: Reply to Discovery を受信し、MUIDが確定
- `CapabilityKnown`: 問い合わせが完了し機能フラグが確定
- `FallbackOperational`: CI失敗または必須機能非対応

## 4. Capability の扱い方

「対応しているはず」を前提にせず、Capability結果で機能をゲートします。

- Profile未対応: Profile有効化UIを出さない
- PE未対応: DeviceInfo/ResourceList取得をスキップ
- PI未対応: 状態照会系の機能を無効化

推奨実装:
- すべての機能フラグを `DeviceSession` に保存
- UI層は `DeviceSession` を参照してボタン有効/無効を切替
- 再接続時にフラグを再計算しキャッシュを更新

## 5. Profile と PE の役割分担（実装観点）

- Profile: 演奏/制御メッセージ解釈の契約
- PE: 設定値・メタデータ・状態のデータ交換

実装での使い分け:
- Profile: 有効/無効の状態管理と通知
- PE: JSONデータの取得/設定、スキーマ検証、永続化

## 6. 失敗パターンと回避

1. Discovery完了前に PE を始める  
MUID未確定でレスポンス紐付けが崩れる。

2. Profile状態を再接続で引き継ぎすぎる  
接続先が変わったのに旧状態を適用してしまう。

3. 未対応機能を UI に表示し続ける  
失敗リトライが過剰になり UX が悪化する。

4. ログに最小情報がない  
原因追跡不能になる。MUID、resource、timeout、fallback理由は必須。

## 7. 最小実装チェックリスト（実戦向け）

1. Discovery送受信と MUID 管理
2. Capability照会と機能フラグ保持
3. Profile有効化/無効化の状態管理
4. PE `Get` 1種（DeviceInfo 推奨）
5. CI失敗時のフォールバック経路
6. 再接続時の再問い合わせ

## 8. 関連ページ
- [MUID（MIDI Unique Identifier）とは]({{ '/ja/muid/' | relative_url }})
- [Initiator / Responder 詳解（MIDI-CI 実装）]({{ '/ja/initiator-responder/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
- [Profiles（MIDI-CI Profile Configuration）]({{ '/ja/profiles/' | relative_url }})
- [Property Exchange（PE）]({{ '/ja/property-exchange/' | relative_url }})

## 9. 参考リンク
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI 2.0 詳説（MIDI-CI/Profiles/Property Exchange）](https://midi.org/details-about-midi-2-0-midi-ci-profiles-and-property-exchange-updated-june-2023)
- [Property Exchange](https://midi.org/midi-2-0-property-exchange)
- [Common Rules for MIDI-CI Profiles](https://midi.org/common-rules-for-midi-ci-profiles)
- [Common Rules for MIDI-CI Property Exchange](https://midi.org/common-rules-for-midi-ci-property-exchange)
- [MIDI 2.0 Core Specification Collection](https://midi.org/midi-2-0-core-specification-collection)
