---
title: MIDI-CI と Profiles
lang: ja
permalink: /ja/ci-profiles/
---

# MIDI-CI と Profiles

## 1. MIDI-CI とは
MIDI-CI（MIDI Capability Inquiry）は、**機器同士が双方向で能力を問い合わせて、共通で使える機能を自動選択する仕組み**です。  
MIDI 1.0 を壊さずに新機能を拡張するための中核アーキテクチャとして定義されています。

ポイント:
- 「相手が何をできるか」を通信で確認できる
- 共通機能だけを選んで安全に動作できる
- 非対応機器とは MIDI 1.0 相当へフォールバックできる

## 2. なぜ必要か（MIDI 1.0時代の課題）
MIDI 1.0では、次のような調整を手作業で行うことが多くありました。
- どのコントローラを何に割り当てるか
- その機器がどの解像度や拡張機能に対応しているか
- 複数機器間で設定の意味をどう揃えるか

MIDI-CI はこの「事前に分からない問題」を減らすため、機器同士の対話を標準化します。

## 3. MIDI-CI の前提
- **双方向通信**が必要
- Capability の照会・応答で構成される
- Profile や Property Exchange などの拡張機能を扱う土台になる

## 4. MIDI-CI の3本柱
MIDI Association の説明では、MIDI-CI の主要領域は次の3つです。

1. Profile Configuration  
特定用途（例: 楽器種別や操作目的）向けに、メッセージの使い方を共通化する仕組み。

2. Property Exchange  
機器情報や設定値などのプロパティを問い合わせ・取得・設定する仕組み。  
JSON の key:value 形式でやり取りされます。

3. Process Inquiry  
MIDIメッセージで制御可能な値の現在状態を照会する仕組み。

## 5. Discovery から利用開始までの流れ（概念）
実装で最初に押さえるとよい、典型的な流れです。

1. 相手機器を検出し、MIDI-CI対応の有無を確認する  
2. 対応機能（Profile / Property Exchange / Process Inquiry）を確認する  
3. 共通対応している機能だけを有効にする  
4. 非対応なら MIDI 1.0 互換の動作へ切り替える

## 6. Profile と Property Exchange の違い
混同しやすいので、役割を分離して理解すると実装が楽になります。

- Profile: 「どう演奏・制御メッセージを解釈するか」の共通ルール
- Property Exchange: 「機器の情報や設定値」を読む/書くための仕組み

例:
- Profile で「この用途ではこの操作をこの意味で扱う」を揃える
- Property Exchange で「現在のモード」「パッチ一覧」「対応コントローラ」を取得する

## 7. 実装時の注意点（初心者向け）
- 最初は「すべてを実装」ではなく Discovery + 最小機能で始める
- Profile と Property Exchange を別モジュールとして実装する
- 未対応機能に遭遇したときのフォールバック動作を先に決める
- 版差分を明示してログに残す

## 8. まず作ると良い最小実装
1. MIDI-CI Discovery の送受信
2. 対応機能フラグの保持
3. 非対応時の MIDI 1.0 フォールバック
4. Property Exchange の `Get` 1種類（読み取り専用）から開始

## 9. 深掘りページ
- [Discovery・DeviceInfo・PE 実装手順（Get/Set）]({{ '/ja/discovery-deviceinfo-pe/' | relative_url }})
- [Profiles（MIDI-CI Profile Configuration）]({{ '/ja/profiles/' | relative_url }})
- [Property Exchange（PE）]({{ '/ja/property-exchange/' | relative_url }})

## 10. 参考リンク
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI 2.0 詳説（MIDI-CI/Profiles/Property Exchange）](https://midi.org/details-about-midi-2-0-midi-ci-profiles-and-property-exchange-updated-june-2023)
- [Property Exchange](https://midi.org/midi-2-0-property-exchange)
- [Common Rules for MIDI-CI Profiles](https://midi.org/common-rules-for-midi-ci-profiles)
- [Common Rules for MIDI-CI Property Exchange](https://midi.org/common-rules-for-midi-ci-property-exchange)
- [MIDI 2.0 Core Specification Collection](https://midi.org/midi-2-0-core-specification-collection)
