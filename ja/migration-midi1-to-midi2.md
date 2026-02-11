---
title: MIDI 1.0 から MIDI 2.0 への移行観点
lang: ja
permalink: /ja/migration-midi1-to-midi2/
---

# MIDI 1.0 から MIDI 2.0 への移行観点（実装者向け）

このページは、既存 MIDI 1.0 実装を壊さずに MIDI 2.0 対応へ移行するための設計メモです。

## 1. 移行の基本方針

1. いきなり全面移行しない
2. 先に内部モデルを MIDI 2.0 対応化する
3. 外部I/Oは MIDI 1.0 と MIDI 2.0 を共存させる

実装的には「プロトコル切替」より「内部抽象化の整理」が先です。

## 2. 先にやるべき設計変更

### 2.1 イベント内部表現の拡張

- 値解像度（7/14/32bit）の共存
- `origin_protocol`（midi1/midi2）を保持
- Group と Channel を明確分離

### 2.2 ルーティング設計

- Group を論理ポートとして管理
- MIDI 1.0 経路では Group->Port マッピングを固定化
- 変換が必要な経路は明示的なトランスレータ層を挟む

### 2.3 接続管理設計

- Discovery/Capability 結果で動作モードを決める
- 非対応時は自動で MIDI 1.0 相当へ降格
- 降格理由をログへ残す

## 3. 実装フェーズ例

### Phase 1: 内部基盤
- UMP パーサ/ビルダを追加
- 内部イベントモデルを拡張
- 既存 MIDI 1.0 ルートと共存

### Phase 2: CI/PE 導入
- Discovery + Capability の実装
- DeviceInfo / ResourceList を Get
- 機能ゲート（canGet/canSet）を導入

### Phase 3: 運用機能
- Mode/State/Program などの Set 対応
- Profile 有効化/無効化
- 再接続時の状態再同期

## 4. 変換で注意すべき点

1. 32bit -> 7/14bit は不可逆
2. CC/RPN/NRPN の意味差を吸収しないと挙動差が出る
3. SysEx/UMP SysEx7 の分割処理を共通化しないとバグ化しやすい

## 5. テスト戦略

1. 互換性
- MIDI 1.0 only 機器
- MIDI 2.0 対応機器
- 混在接続

2. 回帰
- UMP ゴールデンベクタ
- CI ステート遷移
- PE Get/Set と復旧

3. 非機能
- 高負荷時遅延
- 長時間接続
- 再接続時の状態一致

## 6. 移行チェックリスト

- 内部イベントモデルが解像度差を吸収できる
- UMP パース失敗時の安全処理がある
- Discovery/Capability に基づく機能ゲートがある
- canSet 判定なしに Set していない
- MIDI 1.0 フォールバックの経路が常に生きている

## 7. 関連ページ
- [MIDI 2.0 基礎概念]({{ '/ja/fundamentals/' | relative_url }})
- [UMP（Universal MIDI Packet）とは？]({{ '/ja/ump/' | relative_url }})
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
