---
title: MUID（MIDI Unique Identifier）とは
lang: ja
permalink: /ja/muid/
---

# MUID（MIDI Unique Identifier）とは

`MUID` は、MIDI-CI 通信で相手を識別するための ID です。  
実装では「device名」や「endpoint名」よりも、`MUID` を主キーにして request/reply を追跡します。

## 1. MUID の役割

MIDI-CI メッセージには `sourceMUID` と `destinationMUID` が含まれます。  
これにより、同じバス上に複数デバイスがいても、どの相手への問い合わせかを識別できます。

実装的な用途:
- Discovery 後の接続相手確定
- PE の request/reply 相関
- timeout/retry の対象特定
- 再接続時のセッション破棄判定

## 2. ビット幅と値域

MUID は 28bit の識別子です（7bit x 4 バイト表現）。

| 範囲 | 意味 |
|---|---|
| `0x0000000` - `0x0FFFFEFF` | Dynamic MUID（通常割り当て） |
| `0x0FFFFF00` - `0x0FFFFFFE` | Reserved（予約） |
| `0x0FFFFFFF` | Broadcast MUID（全体宛て） |

補足:
- Broadcast は SysEx 上で `7F 7F 7F 7F` として現れます。
- 実装では reserved 領域を生成しないようにします。

## 3. ライフサイクル（実装者向け）

1. ローカル起動時に Dynamic MUID を生成  
2. Discovery を Broadcast 宛てに送信  
3. Reply を受けて `remoteMUID <-> endpoint` を記録  
4. 通信中はその MUID をセッションキーとして利用  
5. 衝突/無効化/再接続で再採番し、再Discovery

## 4. 衝突（Collision）時の扱い

MUID は動的割り当てのため、衝突を前提に実装します。

最低限必要な処理:
1. 競合を検出（重複 MUID、Invalidate MUID 受信など）
2. 古い MUID セッションを破棄
3. 新しい Dynamic MUID を生成
4. Discovery を再実行

「MUID は一意のはずだから衝突しない」という前提は置かない方が安全です。

## 5. 実装パターン（Swift）

```swift
struct DeviceSession {
    let endpointID: String
    let remoteMUID: UInt32
    var lastSeenAt: UInt64
}

actor MUIDRegistry {
    private var byMUID: [UInt32: DeviceSession] = [:]

    func upsert(_ session: DeviceSession) {
        byMUID[session.remoteMUID] = session
    }

    func session(for muid: UInt32) -> DeviceSession? {
        byMUID[muid]
    }

    func invalidate(_ muid: UInt32) {
        byMUID.removeValue(forKey: muid)
    }
}
```

運用ポイント:
- PE request は `remoteMUID` をキーに inflight 管理
- reconnect 時は endpoint 名一致でも MUID 再確定を優先
- stale セッションをタイマーで掃除

## 6. よくある不具合

1. endpoint 名だけで相手を特定している  
対策: 通信相関は常に `MUID` 主キーで管理

2. Discovery 前に PE を始める  
対策: `MUIDKnown` まで PE API をブロック

3. MUID 無効化後に旧 request を継続  
対策: MUID 更新時に inflight request を全キャンセル

4. Broadcast と単一宛先を混同する  
対策: `0x0FFFFFFF` は Discovery など必要箇所に限定

## 7. 関連ページ
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Initiator / Responder 詳解（MIDI-CI 実装）]({{ '/ja/initiator-responder/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})

## 8. 参考リンク
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI-CI: Handling Multiple Initiators and Responders](https://midi.org/midi-ci-handling-multiple-initiators-and-responders)
- [MIDI 2.0 Core Specification Collection](https://midi.org/midi-2-0-core-specification-collection)
