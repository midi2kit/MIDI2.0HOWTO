---
title: Profiles（MIDI-CI Profile Configuration）
lang: ja
permalink: /ja/profiles/
---

# Profiles（MIDI-CI Profile Configuration）

## 1. Profiles とは
Profiles は、**特定用途での MIDI メッセージの使い方を共通化するルールセット**です。  
同じ Profile に対応した機器どうしは、解釈のズレが減り、接続してすぐ使える可能性が高くなります。

## 2. 何が解決されるか
MIDI 1.0/2.0 どちらでも、機器ごとの設定差が大きいと相互運用で手作業が増えます。  
Profiles は「この用途ではこのメッセージをこの意味で扱う」という共通前提を作り、次を改善します。

- 初期設定にかかる時間
- 機器間の挙動差による混乱
- マッピング調整の手戻り

## 3. MIDI-CI 上での位置づけ
Profiles は MIDI-CI の主要機能の1つです。  
一般的には次の順で使います。

1. Discovery で相手の対応状況を確認
2. Profile 機能の対応を確認
3. 共通対応している Profile を有効化
4. 非対応時は標準動作へフォールバック

## 4. Profile の運用イメージ
- 楽器や用途に合った Profile を選ぶ
- 機器間で有効化状態を合わせる
- 必要に応じて無効化して従来動作へ戻す

この「有効化/無効化」を通信で明示的に扱えるのが実装上の利点です。

## 5. 導入時の実装ポイント
- `Profile管理` を `演奏処理` から分離する
- どの Profile が有効かを状態として保持する
- 切り替え時に関連パラメータを再初期化する
- 未対応 Profile を受けたときの応答方針（無視/拒否）を決める

## 6. つまずきやすい点
- Profile を有効化したのに、アプリ側の表示が追従しない
- 機器A/Bで「同名機能」の意味が微妙に異なる
- セッション再接続時に Profile 状態がずれる

対策:
- 状態同期イベントをログに残す
- 再接続時に必ず再問い合わせする
- フォールバック経路（Profile無効時）を常時維持する

## 7. 最小実装チェックリスト
1. Profile 対応可否の問い合わせ
2. 有効化/無効化の送受信
3. 有効Profile状態の永続化または再同期
4. 非対応時のフォールバック

## 8. 関連ページ
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Property Exchange（PE）]({{ '/ja/property-exchange/' | relative_url }})

## 9. 参考リンク
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [Common Rules for MIDI-CI Profiles](https://midi.org/common-rules-for-midi-ci-profiles)
- [6 New Profile Specifications Adopted](https://midi.org/6-new-profile-specifications-adopted)
