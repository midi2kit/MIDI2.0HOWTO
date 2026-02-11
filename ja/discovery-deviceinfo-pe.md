---
title: Discovery・DeviceInfo・PE 実装手順（Get/Set）
lang: ja
permalink: /ja/discovery-deviceinfo-pe/
---

# Discovery・DeviceInfo・PE 実装手順（Get/Set）

このページは、MIDI 2.0 機器間での `Discovery -> DeviceInfo 取得 -> Property Exchange (PE) 運用` を、実装順で整理したものです。

## 1. 前提（どの仕様を基準にするか）
- MIDI-CI は Core Collection 更新で **v1.2.1（2025-12-18 更新）**
- PE は MIDI-CI の一部で、SysEx の Header Data / Property Data を使って Resource をやり取りする
- 実際のプロパティ名や必須項目の厳密定義は、MIDI-CI本体と PE各仕様書（MIDI.orgログイン後の会員ダウンロード）で最終確認する

会員ダウンロードのリンク先:
- [MIDI.org Membership](https://midi.org/membership)
- [MIDI 2.0 Core Specification Collection](https://midi.org/midi-2-0-core-specification-collection)
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI 2.0 Property Exchange](https://midi.org/midi-2-0-property-exchange)

## 2. 実装の全体フロー（最短）
1. UMP Endpoint / Function Block の把握（利用可能GroupとMIDI-CI可否を確認）
2. MIDI-CI Discovery 送信
3. Reply to Discovery 受信（MUID確定）
4. Profile / PE / Process Inquiry の各 Capability 確認
5. PEで DeviceInfo を `Get`
6. 必要Resourceを `Inquire -> Get`
7. 必要なものだけ `Set`（書き込み）
8. 失敗時は MIDI 1.0 相当へフォールバック

## 3. Step-by-step 詳細

### Step A: Endpoint 側の事前把握
`UMP Endpoint` の Discovery で最低限以下を掴みます。
- Device Identifiers（Name / Manufacturer / Model / Version / Product Instance Id）
- 対応データ形式（UMPバージョン、MIDI Protocol、JR Timestamp可否）
- Topology（有効Group、MIDI-CIに使うGroup）

### Step B: MIDI-CI Discovery
- Initiator が Discovery を送る
- Responder が Reply to Discovery を返す
- Discoveryは単発Transactionとして扱えるため、必ずしもセッション常駐は不要

実装ポイント:
- 応答の宛先MUID処理を厳密にする
- 複数Initiator環境では、Responder側のメモリ戦略を先に決める

### Step C: Capability 問い合わせ
Discovery成功後、順に確認します。
1. Profile Inquiry
2. PE Capability Inquiry
3. Process Inquiry Capability

ここで「共通対応している機能」だけを有効化します。

### Step D: DeviceInfo の取得（PE）
PE Foundational Resources の `DeviceInfo` は、機器識別の基礎です。

最低限そろえる対象（Device design mappingに基づく）:
- `manufacturerId`
- `familyId`
- `modelId`
- `versionId`
- 人間可読名（manufacturer / family / model など）
- `serial`（Product Instance Id との対応）

推奨:
- Discoveryで得た識別子と DeviceInfo の値を突き合わせる
- 不一致時はログに出して、UI表示名の優先順位ルールを固定する

### Step E: PE Resource の利用
PE は `Inquire / Get / Set` で扱います。

- `Inquire`: そのResourceを扱えるか、使える形を確認
- `Get`: 現在値を読む
- `Set`: 値を更新

## 4. Get / Set 可能情報（実務向け整理）
以下は MIDI.org 公開説明から整理した一覧です。実際の可否は各Resource仕様で最終確認してください。

### 4.1 Foundational
- `DeviceInfo`: 主に **Get**（機器識別情報）
- `ChannelList`: 主に **Get**（現在使用中Channel/Group/MPE状態など）
- `JSONSchema`: 主に **Get**（メーカー拡張Resourceのschema参照）

### 4.2 Mode
- `ModeList`: **Get**（利用可能Mode一覧）
- `CurrentMode`: **Get / Set**（現在Modeの参照・変更）

### 4.3 Program
- `ProgramList`: 主に **Get**（プログラム一覧）

### 4.4 Channel
- `ChannelMode`: **Get / Set**
- `BasicChannelRx`: **Get / Set**
- `BasicChannelTx`: **Get / Set**

### 4.5 Local / Sync / Transport系
- `LocalOn`: **Get / Set**（Local On/Off）
- `MaxSysex8Streams`: 主に **Get**（同時SysEx8サポート数の把握）
- `ExternalSync`: 実装依存（外部同期可能機器向け）

### 4.6 Device State
- `Get and Set Device State`: **Get / Set**

主用途:
- DAW終了時に状態を `Get` して保存
- 再オープン時に `Set` で復元

代表的な状態（公開説明ベース）:
- Current Program
- Program Parameters
- Mode
- Active MIDI Channels
- Controller Mappings
- Samples / Binary data
- Effects
- Output Assignments

### 4.7 Controller Resources
- `AllCtrlList` / `ChCtrlList` / `CtrlMapList`（Controller Resources）
- どこまでSet可能かは実装と仕様書に依存

## 5. 最小実装の推奨順
1. Discovery / Reply to Discovery
2. PE Capability Inquiry
3. DeviceInfo の Get
4. ChannelList / ProgramList の Get
5. CurrentMode / LocalOn の Set
6. Device State の Get/Set

## 6. 失敗しやすい点
- Discovery成功前にPEを開始してしまう
- MUID管理が曖昧で返信相手を取り違える
- Set成功をUIへ反映しない（実機値と表示が乖離）
- メーカー拡張JSONの未知キーを捨てて将来互換を壊す

## 7. 参考リンク
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI 2.0 Core Specification Collection](https://midi.org/midi-2-0-core-specification-collection)
- [Details about MIDI 2.0, MIDI-CI, Profiles and Property Exchange](https://midi.org/details-about-midi-2-0-midi-ci-profiles-and-property-exchange-updated-june-2023)
- [MIDI 2.0 Device Design: Property Names and Mapping](https://midi.org/midi-2-0-device-design-property-names-and-mapping)
- [MIDI-CI: Handling Multiple Initiators and Responders](https://midi.org/midi-ci-handling-multiple-initiators-and-responders)
- [Property Exchange Overview](https://midi.org/midi-2-0-property-exchange)
- [Property Exchange Foundational Resources](https://midi.org/property-exchange-foundational-resources)
- [The MMA adopts 8 new MIDI 2.0 specifications](https://midi.org/the-mma-adopts-8-new-midi-2-0-specifications)
