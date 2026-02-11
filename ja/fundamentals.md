---
title: MIDI 2.0 基礎概念
lang: ja
permalink: /ja/fundamentals/
---

# MIDI 2.0 基礎概念（実装者向け）

このページは、MIDI 2.0 を「仕様の要約」ではなく、**実装設計の土台**として理解するための内容です。

## 1. 実装者視点での全体像
MIDI 2.0 実装は、次の層に分けて設計すると破綻しにくくなります。

1. Transport 層
USB/BLE/ネットワークなど、バイト列を運ぶ層。

2. Packet 層
UMP（Universal MIDI Packet）のデコード/エンコードを行う層。

3. Semantic 層
ノート、CC、Per-Note などをアプリ内部イベントへ正規化する層。

4. Capability 層
MIDI-CI で Profile/PE/Process Inquiry の可否を交渉する層。

5. Policy 層
非対応機器へのフォールバック、UI表示、ログ戦略を決める層。

## 2. MIDI 1.0 との本質的な差分
- 値解像度が高く、演奏情報の表現幅が増える
- 双方向通信（CI/PE）を前提にした機器連携が可能
- UMP によって、MIDI 1.0/2.0 混在系を同一パイプラインで扱える

実務上は「新機能を使うか」より先に、**混在環境で壊れない構造**を優先します。

## 3. 最初に決める設計項目
1. Group 設計
- Group を論理ポートとしてどう割り当てるか
- 入出力の Group 変換を許可するか

2. Protocol 運用方針
- 端末ごとに MIDI 1.0 / MIDI 2.0 を切り替えるか
- 同一セッション内で混在を許すか

3. CI の責務分離
- Discovery/Capability を接続管理に寄せるか
- Profile/PE を機能モジュールに分けるか

4. フォールバック規則
- CI 失敗時、PE 非対応時、Set 失敗時の動作を固定する
- 「自動降格」と「ユーザー確認」の境界を決める

## 4. 推奨データモデル（内部表現）
パケット形式に依存しない内部イベントを定義しておくと、移植とテストが楽になります。

```text
NormalizedMidiEvent {
  timestamp_ns
  group
  channel
  message_kind
  note
  controller
  value_u32
  attribute
  origin_protocol   // midi1 | midi2
  source_endpoint
}
```

ポイント:
- 7bit/14bit/32bit を内部では可能な限り共通レンジへ正規化
- `origin_protocol` を保持して逆変換の情報を失わない
- UI 層に生バイトを漏らさない

## 5. MIDI-CI を含む接続ステート
接続管理は状態機械として実装するのが安全です。

```text
Disconnected
  -> EndpointDetected
  -> CiDiscoveryDone
  -> CapabilityKnown
  -> Operational
  -> FallbackOperational
```

最低限ログに残すべき情報:
- MUID
- 対応機能（Profile/PE/Process Inquiry）
- 適用されたプロトコル（MIDI 1.0 / 2.0）
- フォールバック理由

## 6. 実装で起きやすい失敗
- Group と Channel の責務が混ざる
- CI 成功前に PE を開始する
- Set 成功/失敗をUIへ反映しない
- 変換時に分解能を落として戻せなくなる

## 7. テスト観点（最低限）
1. 互換性テスト
- MIDI 1.0 only 機器との接続
- MIDI 2.0 対応機器との接続
- 混在環境での経路切替

2. 回帰テスト
- UMP パースのゴールデンベクタ
- CI フローのステート遷移
- PE `Get/Set` 成否と復旧処理

3. 非機能テスト
- 高頻度イベント時の遅延
- 長時間接続時のメモリ増加
- 再接続時の状態同期

## 8. 関連ページ
- [UMP（Universal MIDI Packet）とは？]({{ '/ja/ump/' | relative_url }})
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [MUID（MIDI Unique Identifier）とは]({{ '/ja/muid/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
