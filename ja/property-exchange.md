---
title: Property Exchange（PE）
lang: ja
permalink: /ja/property-exchange/
---

# Property Exchange（PE）

## 1. PE とは
Property Exchange（PE）は、**機器の情報・設定・メタデータを構造化して交換する仕組み**です。  
MIDI-CI の機能の1つで、データは主に JSON の key:value 形式で表現されます。

## 2. 何に使うか
PE では、次のような情報を読み書きできます。

- デバイス設定
- コントローラ一覧と解像度情報
- パッチ名などのメタデータ
- メーカー名、モデル名、バージョン情報

演奏メッセージ本体というより、**機器を理解・管理するための情報交換**に向いています。

## 3. 基本操作
MIDI Association の説明でよく出る基本操作は次です。

- `Inquire`（何が扱えるかを問い合わせ）
- `Get`（値を取得）
- `Set`（値を設定）

まずは `Get` 中心で導入し、安定後に `Set` を追加するのが実装しやすいです。

## 4. Profile との違い
- Profile: 演奏・制御メッセージの「使い方」を揃える
- PE: 設定や情報の「データ」を交換する

2つを組み合わせると、
- Profile で挙動を共通化し
- PE で表示や設定UIを自動同期
という運用がしやすくなります。

## 5. 典型フロー（最小）
1. Discovery 後に PE 対応可否を確認
2. 利用可能なプロパティを問い合わせ
3. `Get` で必要情報を取得
4. 受信JSONを内部モデルへ反映

## 6. 実装時の注意点
- 受信データのバリデーションを必ず行う
- 未知キーは破棄せず保持方針を決める
- タイムアウト・再送・部分失敗を設計する
- UI更新と通信処理を分離する

## 7. 最小実装チェックリスト
1. PE 能力問い合わせ
2. `Get` 1種類の実装
3. JSON デコード失敗時のハンドリング
4. 非対応機器でのフォールバック

## 8. 関連ページ
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
- [Profiles（MIDI-CI Profile Configuration）]({{ '/ja/profiles/' | relative_url }})

## 9. 参考リンク
- [MIDI 2.0 Property Exchange](https://midi.org/midi-2-0-property-exchange)
- [Common Rules for MIDI-CI Property Exchange](https://midi.org/common-rules-for-midi-ci-property-exchange)
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
