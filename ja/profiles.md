---
title: Profiles（MIDI-CI Profile Configuration）
lang: ja
permalink: /ja/profiles/
---

# Profiles（MIDI-CI Profile Configuration / 実装者向け）

Profiles は、メッセージ意味を機器間で揃えるための契約です。  
実装では「どの Profile が現在有効か」を状態として管理することが中心になります。

## 1. 実装で扱う対象

最低限必要な管理項目:
- Profile ID
- 対象チャネル/スコープ
- 有効状態（on/off）
- 反映時刻
- 変更元（ローカル操作 / リモート通知）

Profile は単なる定数ではなく、接続中に変化するランタイム状態です。

## 2. 実装フロー（最小）

1. Discovery 後に Profile 対応可否を確認
2. 利用可能 Profile 一覧を取得
3. 自アプリが対応する Profile のみ候補化
4. 有効化/無効化要求を送信
5. 応答に応じてローカル状態を更新
6. 失敗時は標準動作へフォールバック

## 3. 状態管理モデル

推奨データ構造:

```text
ProfileState {
  profile_id
  scope            // global | channel | function-block
  enabled
  source           // local | remote
  updated_at
}
```

設計ポイント:
- 演奏イベント処理と Profile 状態更新を分離する
- Profile 切替中の一時状態（pending）を持つ
- 接続断後は再問い合わせで再構築し、キャッシュの盲信を避ける

## 4. Profile有効化時の実務処理

Profileを有効化したら、内部ルーティングとUI表示を同時更新します。

1. 送信前: 対応可否と競合状態を確認
2. 送信後: ACK/NAK を待機
3. 成功時: ProfileState を更新し、UI/エンジンへ通知
4. 失敗時: 旧状態に戻し、エラー理由をログ化

## 5. PE との連携

Profile切替と同時に PE を使うケースが多いです。

- Profile: 振る舞い契約
- PE: パラメータ/表示名/プリセット情報

典型例:
- Profile 有効化後に `ProgramList` / `ChannelList` を再取得
- 必要に応じて `CurrentMode` や `State` を更新

## 6. よくある実装バグ

1. Profile状態をUIだけ更新して実処理が追従しない  
2. 相手機器の拒否応答を無視して on 扱いにする  
3. 再接続時に古い ProfileState をそのまま適用する  
4. 非対応Profileを送信し続ける

## 7. テスト項目

1. 有効化/無効化の往復テスト
2. 同一Profileの多重要求（競合）テスト
3. 再接続時の再同期テスト
4. 非対応機器とのフォールバックテスト

## 8. 関連ページ
- [MIDI-CI と Profiles]({{ '/ja/ci-profiles/' | relative_url }})
- [Property Exchange（PE）]({{ '/ja/property-exchange/' | relative_url }})
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})

## 9. 参考リンク
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [Common Rules for MIDI-CI Profiles](https://midi.org/common-rules-for-midi-ci-profiles)
- [6 New Profile Specifications Adopted](https://midi.org/6-new-profile-specifications-adopted)
