---
title: Initiator / Responder 詳解（MIDI-CI 実装）
lang: ja
permalink: /ja/initiator-responder/
---

# Initiator / Responder 詳解（MIDI-CI 実装）

このページは、MIDI-CI 実装で必ず出てくる `Initiator` / `Responder` を、  
実装者向けに「状態管理」と「MIDI2Kit のコード例」まで踏み込んで整理したものです。

## 1. まず定義を固定する

- `Initiator`: 問い合わせを開始する側（Request を送る側）
- `Responder`: 問い合わせに応答する側（Reply を返す側）

重要点:
- 役割は「機器固定」ではなく「トランザクション単位」
- 同じ2台でも、処理Aでは A が Initiator、処理Bでは B が Initiator になり得る

## 2. 実装で混同しやすいポイント

### 2.1 役割は接続単位ではない

`USB/BLE でつながっているから常にこちらが Initiator` とは限りません。  
`Discovery`、`Profile`、`PE Get/Set` ごとに request/reply の向きが決まります。

### 2.2 1トランザクションに相関キーが必要

最低限、次の情報で request/reply を紐付けます。

- local MUID
- remote MUID
- Request ID（PE）
- resource 名（PE）
- timeout 情報

この紐付けが弱いと、返信取り違えや再送ループが発生します。

## 3. どの場面で誰が Initiator になるか

| フェーズ | Initiator | Responder | 主な結果 |
|---|---|---|---|
| Discovery | 検出開始側 | 検出される側 | MUID確定 |
| Capability 照会 | 問い合わせ側 | 応答側 | Profile/PE/PI 可否確定 |
| PE `Get` | 取得要求側 | リソース提供側 | JSON/バイナリ応答 |
| PE `Set` | 設定変更側 | 設定適用側 | 成功/失敗応答 |
| Subscribe/Notify | Subscribe開始側 | 通知発行側 | 変更通知ストリーム |

## 4. 最小ステートマシン

### 4.1 Initiator 側

```text
EndpointDetected
  -> DiscoverySent
  -> MUIDKnown
  -> CapabilityKnown
  -> PEReady
  -> Operational
  -> Recovering (timeout/reconnect)
```

### 4.2 Responder 側

```text
Idle
  -> DiscoveryReceived
  -> MUIDAssigned
  -> CapabilityReplyReady
  -> ServingPE
  -> Idle
```

## 5. MIDI2Kit 実装例

### 5.1 Initiator（高レベル API: `MIDI2Client`）

```swift
import Foundation
import MIDI2Kit

let client = try MIDI2Client(name: "CI-Initiator")
try await client.start()

Task {
    for await event in await client.makeEventStream() {
        switch event {
        case .deviceDiscovered(let device):
            guard device.supportsPropertyExchange else { continue }

            let info = try await client.getDeviceInfo(from: device.muid)
            print("Product: \(info.productName ?? "Unknown")")

            let resources = try await client.getResourceList(from: device.muid)

            if resources.contains(where: { $0.resource == "DeviceInfo" && $0.canGet }) {
                _ = try await client.get("DeviceInfo", from: device.muid)
            }

            if resources.contains(where: { $0.resource == "State" && $0.canSet }) {
                let body: [String: Any] = ["note": "initiator example"]
                let data = try JSONSerialization.data(withJSONObject: body)
                _ = try await client.set("State", data: data, to: device.muid)
            }

        default:
            break
        }
    }
}
```

ポイント:
- `ResourceList` の `canGet/canSet` 判定で `Get/Set` を必ずゲート
- `supportsPropertyExchange == false` の場合は PE をスキップ

### 5.2 Responder を含むローカル検証（`MockDevice + LoopbackTransport`）

```swift
import MIDI2Kit

let (initiatorTransport, responderTransport) = LoopbackTransport.createPair()

let mock = MockDevice(
    transport: responderTransport,
    preset: .korgModulePro
)
try await mock.start()

// 低レベル実装例（初期化パラメータはSDKバージョンで変わる）
let ciManager = CIManager(transport: initiatorTransport /* ... */)
let peManager = PEManager(transport: initiatorTransport /* ... */)

await ciManager.startDiscovery()
let _ = try await peManager.get("DeviceInfo", from: mock.handle)
```

用途:
- 実機なしで Initiator / Responder 両役割を再現
- timeout、再送、resource 可否判定のテストを自動化しやすい

## 6. Get/Set 可能情報の扱い方（実装規約）

「この resource は Set できるはず」と決め打ちしないで、接続ごとに判定します。

| Resource 例 | 典型用途 | 判定 |
|---|---|---|
| `DeviceInfo` | 機器識別 | `canGet` |
| `ResourceList` | 機能表取得 | `canGet` |
| `CurrentMode` | モード取得/変更 | `canGet` / `canSet` |
| `LocalOn` | ローカル制御 | `canGet` / `canSet` |
| `State` | 状態保存/復元 | `canGet` / `canSet` |
| `X-ParameterList` | ベンダー拡張パラメータ一覧 | `canGet` |
| `X-ProgramEdit` | ベンダー拡張編集値 | `canGet` / `canSet`（機器依存） |

## 7. 複数 Initiator / Responder の設計注意

1. `remoteMUID` ごとに inflight request を分離  
2. timeout と retry を request 単位で管理  
3. reconnect 時は古い MUID セッションを破棄  
4. 通知（Subscribe）は request/reply 系と別キューで処理

MIDI-CI は複数 peer が同時に関与し得るため、単一相手前提の実装は壊れやすくなります。

## 8. よくある不具合と対策

1. Discovery完了前に PE 開始  
対策: `MUIDKnown` になるまで PE API を呼ばない

2. `canSet` 未確認で Set 実行  
対策: `ResourceList` を capability table として保持

3. 再接続後も旧 MUID を使い続ける  
対策: endpoint 再検出時にセッション全破棄して再Discovery

4. request/reply の相関不足  
対策: `MUID + requestId + resource` を最低キーにする

## 9. 関連ページ
- [MUID（MIDI Unique Identifier）とは]({{ '/ja/muid/' | relative_url }})
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
- [Property Exchange（PE）]({{ '/ja/property-exchange/' | relative_url }})
- [MIDI2Kit とは？できること・まだできないこと]({{ '/ja/midi2kit/' | relative_url }})

## 10. 参考リンク
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI-CI: Handling Multiple Initiators and Responders](https://midi.org/midi-ci-handling-multiple-initiators-and-responders)
- [MIDI 2.0 Property Exchange](https://midi.org/midi-2-0-property-exchange)
- [MIDI2Kit-SDK README](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/README.md)
- [MIDI2Kit Guide: Inter-App MIDI-CI Limitations](https://midi2kit.dev/guides/inter-app-midi-ci.html)
