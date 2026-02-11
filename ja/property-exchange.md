---
title: Property Exchange（PE）
lang: ja
permalink: /ja/property-exchange/
---

# Property Exchange（PE / 実装者向け）

PE は、MIDI-CI 上で設定・状態・メタデータを交換する仕組みです。  
実装上は「Resource の `canGet/canSet/canSubscribe` を見て安全に運用する」ことが重要です。

## 1. PE の責務

PE で扱う対象:
- DeviceInfo（機器識別）
- ResourceList（利用可能リソース一覧）
- ChannelList / ProgramList（演奏対象の構成情報）
- CurrentMode / LocalOn / State などの設定・状態
- ベンダー拡張（`X-*`）

演奏イベント本体ではなく、アプリの設定UI・同期・状態復元を支える層です。

## 2. 基本操作

- `Inquire`: その Resource が存在し利用可能か確認
- `Get`: 現在値を取得
- `Set`: 値を書き込み
- `Subscribe`: 更新通知を購読（対応時）

導入順は `Get -> Set -> Subscribe` が安全です。

## 3. 実装の基本原則

1. ResourceList を単なる表示用にせず、権限テーブルとして使う
2. `canSet == false` の Resource へ Set しない
3. JSON は未知キーを保持できる設計にする
4. multi-chunk 応答（例: ResourceList）を前提にタイムアウト設計する

## 4. Get/Set 可能判定の実装例

```swift
let resources = try await client.getResourceList(from: device.muid)

func capability(_ name: String) -> (canGet: Bool, canSet: Bool, canSubscribe: Bool)? {
    guard let r = resources.first(where: { $0.resource == name }) else { return nil }
    return (r.canGet, r.canSet, r.canSubscribe)
}

if let c = capability("ProgramList"), c.canGet {
    _ = try await client.get("ProgramList", from: device.muid)
}
```

## 5. X-Parameter / X-ProgramEdit の実務解説

`X-*` はベンダー拡張 Resource です。  
MIDI2Kit-SDK の公開情報では、KORG 系で次が実用的です。

### 5.1 X-ParameterList（主に Get）

`X-ParameterList` は、CC と意味の対応表です。

主な取得項目:
- `controlcc`: CC番号
- `name`: パラメータ名
- `default`: 既定値
- `min` / `max`: 値域
- `category`: 分類（機器依存）

用途:
- `CC11` を「Inst Level」のような名称で UI 表示
- Set 前に値域チェックして不正値送信を防止

### 5.2 X-ProgramEdit（Get、機器により Set）

`X-ProgramEdit` は、現在プログラムの編集状態を表します。

主な取得項目:
- プログラム情報: `name`, `category`, `bankMSB`, `bankLSB`, `programNumber`
- 現在値: `currentValues` / `params`
  - 例: `{"controlcc": 11, "current": 100}`

送信可能かどうか:
- 固定で決め打ちせず、`ResourceList` の `canSet` で判定
- `canSet == true` の場合のみ `X-ProgramEdit` または `ProgramEdit` に Set を試す

### 5.3 Set 送信例（機器依存）

```swift
let resources = try await client.getResourceList(from: device.muid)
let canSetXProgramEdit = resources.contains { $0.resource == "X-ProgramEdit" && $0.canSet }

if canSetXProgramEdit {
    let payload: [String: Any] = [
        "currentValues": [
            ["controlcc": 11, "current": 100],
            ["controlcc": 74, "current": 64]
        ]
    ]
    let data = try JSONSerialization.data(withJSONObject: payload)
    _ = try await client.set("X-ProgramEdit", data: data, to: device.muid)
}
```

注意:
- 受理されるキー構造は機器依存
- `X-ParameterList` の min/max を超える値は送らない
- 失敗時は再取得（Get）で実機状態を同期し直す

## 6. 代表 Resource と運用方針

| Resource | 典型操作 | 実装メモ |
|---|---|---|
| `DeviceInfo` | Get | 接続直後に取得して機種判定 |
| `ResourceList` | Get | canGet/canSet/canSubscribe を機能ゲートに使用 |
| `ChannelList` / `ProgramList` | Get | UI初期化に利用、大きい応答はタイムアウト調整 |
| `CurrentMode` / `LocalOn` | Get/Set | Set後に再Getして反映確認 |
| `State` | Get/Set | アプリ終了時保存と再開時復元 |
| `X-ParameterList` | Get | CC名・値域の辞書化 |
| `X-ProgramEdit` | Get(+Set) | canSet 判定後のみ更新送信 |

## 7. 失敗時の基本処理

1. timeout: 再送回数を制限しつつリトライ
2. schema mismatch: 未知キーを保持してデコード互換を維持
3. Set失敗: optimistic update をロールバック
4. 連続失敗: PE機能を一時停止し MIDI 1.0 運用へ降格

## 8. 関連ページ
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
- [Profiles（MIDI-CI Profile Configuration）]({{ '/ja/profiles/' | relative_url }})

## 9. 参考リンク
- [MIDI 2.0 Property Exchange](https://midi.org/midi-2-0-property-exchange)
- [Common Rules for MIDI-CI Property Exchange](https://midi.org/common-rules-for-midi-ci-property-exchange)
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI2Kit-SDK README](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/README.md)
- [MIDI2Kit-SDK API Reference](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/docs/API-Reference.md)
