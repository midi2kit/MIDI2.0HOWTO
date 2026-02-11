---
title: UMP（Universal MIDI Packet）とは？
lang: ja
permalink: /ja/ump/
---

# UMP（Universal MIDI Packet）とは？（実装者向け）

UMP は、MIDIメッセージを 32-bit ワード単位で運ぶための共通バイナリ形式です。  
実装では「仕様知識」より、**壊れないパーサ/ビルダ設計**が重要です。

## 1. UMP を実装単位で理解する
- UMP は 1メッセージを `1〜4ワード` で表現する
- 先頭ワードから `Message Type (MT)` と `Group` を取り出し、長さを確定する
- 長さ確定後に、残りワードをまとめて同一メッセージとして扱う

## 2. 先頭ワードで最初に読む情報
実装の基本は次の2つです。

1. `MT`（Message Type）
- どのカテゴリのメッセージか
- メッセージ長（ワード数）を決めるキー

2. `Group`
- 論理ポート番号
- ルーティング・フィルタ・状態管理のキー

サンプル（概念）:
```c
uint8_t mt = (word0 >> 28) & 0x0F;
uint8_t group = (word0 >> 24) & 0x0F;
size_t words = word_count_for_mt(mt); // 仕様テーブル準拠
```

## 3. パーサ実装の定石
MT から必要ワード数を引くストリーミングパーサにします。

```text
while (buffer has >= 1 word) {
  peek word0
  mt = extract_mt(word0)
  n  = word_count_for_mt(mt)
  if (buffer has < n words) break

  msg_words = pop n words
  dispatch(msg_words)
}
```

実装ポイント:
- `word_count_for_mt` は仕様表をハードコードし、未定義MTは明示エラー
- 部分受信は次回入力まで保持（破棄しない）
- Group ごとに独立した状態を持てるようにする

## 4. ビルダ実装の定石
送信側は「構造体 -> UMPワード列」の一方向変換として実装します。

1. 内部イベントを検証
2. 対応 MT を決定
3. ワード配列を生成
4. 送信前に再検証（長さ・範囲・Group）

推奨:
- `encode_midi1()` と `encode_midi2()` を分離
- 送信直前で共通 `validate_ump(words)` を通す

## 5. SysEx と分割メッセージ
SysEx系は分割受信を前提に、再構築バッファを持ちます。

- Complete / Start / Continue / End を状態機械で処理
- Group と Stream識別子（ある場合）で再構築コンテキストを分ける
- タイムアウト時は中断してログ化

## 6. JR Timestamp の扱い
JR Timestamp を使う場合は「到着時刻」と切り分けます。

- 受信: JR値を内部時刻へマッピング
- 送信: スケジューラ時刻からJR値を計算
- 非対応経路: 到着時刻ベースへフォールバック

## 7. MIDI 1.0 / 2.0 混在時の注意
- UMP上に MIDI 1.0 相当メッセージを載せる経路を用意する
- 分解能変換は不可逆になり得るので、`origin_protocol` を保持
- 双方向変換は「同値」ではなく「実用同等」を目標にする

## 8. 性能・品質の実践ポイント
1. アロケーション抑制
- パース時は固定長バッファ + スライス参照を優先

2. スレッド分離
- I/Oスレッドでデコード、音源/UIへはキューで渡す

3. 観測性
- 不正MT、長さ不一致、再構築失敗をメトリクス化

4. 回帰テスト
- 既知ワード列のゴールデンテスト
- 境界値（最短/最長、未知MT、分割途切れ）

## 9. まず作る最小セット
1. MT->長さテーブル
2. ストリーミングパーサ
3. Group 付きディスパッチ
4. SysEx 再構築
5. エンコード + バリデーション

## 10. 関連ページ
- [MIDI 2.0 基礎概念（実装者向け）]({{ '/ja/fundamentals/' | relative_url }})
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
