---
title: Discovery・DeviceInfo・PE 実装手順（Get/Set）
lang: ja
permalink: /ja/discovery-deviceinfo-pe/
---

# Discovery・DeviceInfo・PE 実装手順（Get/Set）

このページは、`Discovery -> DeviceInfo -> ResourceList -> Get/Set` を実装順で示す実務ガイドです。  
目標は「どの情報を取得でき、どの情報を送信できるか」をコードで判定できる状態にすることです。

## 1. 実装対象の境界

このページが扱う範囲:
- UMP Endpoint 判定
- MIDI-CI Discovery / Capability
- PE での DeviceInfo / ResourceList / 各 Resource 操作
- ベンダー拡張（`X-*`）の扱い

## 2. 全体フロー（実装順）

1. Endpoint/Function Block から CI 利用可能 Group を確定
2. Discovery を送信し MUID を確定
3. Capability（Profile / PE / Process Inquiry）を照会
4. PE `Get("DeviceInfo")`
5. PE `Get("ResourceList")`
6. Resourceごとの `canGet/canSet/canSubscribe` を保持
7. `Get` 中心で運用開始
8. 対応確認できた Resource だけ `Set`

## 3. 実装ステップ詳細

### Step A: Discovery 前の準備

取得しておく情報:
- Endpoint名、Manufacturer、Model
- 使用Group（CI 通信用）
- 接続種別（USB/BLE/仮想）

BLE/仮想接続は timeout 設計に影響するため、先に保持します。

### Step B: Discovery と MUID 確定

最低限の実装要件:
- Discovery送信時に request context を保存
- Reply to Discovery 受信時に `MUID <-> endpoint` を結び付け
- timeout/再送を管理

### Step C: Capability 問い合わせ

確認対象:
1. Profile
2. Property Exchange
3. Process Inquiry

`supportsPE == false` なら、この後の PE 操作を全部スキップします。

### Step D: DeviceInfo 取得

最低限見る項目:
- `manufacturerId`, `familyId`, `modelId`, `versionId`
- `manufacturer`, `family`, `model`, `version`
- `serial` または Product Instance ID 相当

推奨:
- Discoveryで得た識別子と突き合わせ
- 不一致時にログ警告を残す

### Step E: ResourceList 取得と権限テーブル化

ResourceList は「UIに並べる一覧」ではなく機能許可表として使います。

保持例:

```text
ResourceCapability {
  resourceName
  canGet
  canSet
  canSubscribe
  schema
}
```

## 4. 取得可能/送信可能を判定する実装

```swift
let resources = try await client.getResourceList(from: device.muid)

func canGet(_ resource: String) -> Bool {
    resources.first(where: { $0.resource == resource })?.canGet == true
}

func canSet(_ resource: String) -> Bool {
    resources.first(where: { $0.resource == resource })?.canSet == true
}
```

この判定結果で API 実行をゲートします。

## 5. よく使う Resource と操作方針

| Resource | 主用途 | 操作方針 |
|---|---|---|
| `DeviceInfo` | 機器識別 | `canGet` なら必ず取得 |
| `ResourceList` | 機能判定 | `canGet` なら取得しキャッシュ |
| `ChannelList` | チャネル状態表示 | `canGet` 時のみ取得 |
| `ProgramList` | プログラム一覧 | `canGet` 時のみ取得 |
| `CurrentMode` | モード切替 | `canSet` が true の時のみ更新 |
| `LocalOn` | ローカル制御 | Set 後に再Getで検証 |
| `State` | 状態保存/復元 | セッション終了時に取得、再開時に送信 |

## 6. X-Parameter / X-ProgramEdit の実務手順

### 6.1 X-ParameterList を取得

主な取得項目:
- `controlcc`
- `name`
- `default`
- `min`
- `max`
- `category`

これを UI 表示名辞書とバリデーション辞書に使います。

### 6.2 X-ProgramEdit を取得

主な取得項目:
- `name`, `category`, `bankMSB`, `bankLSB`, `programNumber`
- `currentValues` / `params`（`controlcc` と `current`）

### 6.3 X-ProgramEdit を送信（機器依存）

送信前条件:
- ResourceList に `X-ProgramEdit` が存在
- `canSet == true`

例（機器依存のため要検証）:

```swift
if canSet("X-ProgramEdit") {
    let body: [String: Any] = [
        "currentValues": [
            ["controlcc": 11, "current": 100],
            ["controlcc": 74, "current": 64]
        ]
    ]
    let data = try JSONSerialization.data(withJSONObject: body)
    _ = try await client.set("X-ProgramEdit", data: data, to: device.muid)
}
```

値の検証:
- `X-ParameterList` の `min/max` 内に収める
- 送信後は必ず再Getして反映を確認

## 7. 最小実装の推奨順

1. Discovery / MUID 管理
2. PE Capability 判定
3. DeviceInfo `Get`
4. ResourceList `Get`
5. ChannelList / ProgramList `Get`
6. CurrentMode / LocalOn / State の `Set`（canSet確認後）
7. X-ParameterList / X-ProgramEdit（対応機器のみ）

## 8. 失敗しやすい点

1. MUID確定前に PE を始める
2. canSet 判定なしで Set する
3. Set 成功時にUIを更新しない
4. multi-chunk 応答の timeout が短すぎる
5. ベンダー拡張 JSON の未知キーを破棄して将来互換を壊す

## 9. 仕様参照（会員ダウンロード）

- [MIDI.org Membership](https://midi.org/membership)
- [MIDI 2.0 Core Specification Collection](https://midi.org/midi-2-0-core-specification-collection)
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI 2.0 Property Exchange](https://midi.org/midi-2-0-property-exchange)

## 10. 参考リンク
- [Initiator / Responder 詳解（MIDI-CI 実装）]({{ '/ja/initiator-responder/' | relative_url }})
- [Details about MIDI 2.0, MIDI-CI, Profiles and Property Exchange](https://midi.org/details-about-midi-2-0-midi-ci-profiles-and-property-exchange-updated-june-2023)
- [MIDI 2.0 Device Design: Property Names and Mapping](https://midi.org/midi-2-0-device-design-property-names-and-mapping)
- [MIDI-CI: Handling Multiple Initiators and Responders](https://midi.org/midi-ci-handling-multiple-initiators-and-responders)
- [Property Exchange Overview](https://midi.org/midi-2-0-property-exchange)
- [Property Exchange Foundational Resources](https://midi.org/property-exchange-foundational-resources)
- [MIDI2Kit-SDK README](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/README.md)
- [MIDI2Kit-SDK API Reference](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/docs/API-Reference.md)
