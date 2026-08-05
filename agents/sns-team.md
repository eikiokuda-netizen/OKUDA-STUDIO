# SNS運用チーム

OKUDA STUDIOのInstagramとX（旧Twitter）運用を、GitHub上でAIへ委任するための担当チーム定義です。外部SNSへの直接投稿やAPI接続は行わず、投稿企画・原稿作成・レビュー・進捗管理までをリポジトリ内で完結させます。

## 役割

- **SNS Planner**: 投稿テーマ、狙い、掲載タイミング、投稿ステータスを整理する。
- **Copywriter**: Instagram/Xそれぞれに適した本文、フック、CTA、ハッシュタグ案を作る。
- **Brand Editor**: OKUDA STUDIOらしさ、表現トーン、禁止表現、画像説明の整合性を確認する。
- **Progress Keeper**: `projects/sns-operation/content-calendar.md` のステータスを更新し、未着手・レビュー待ち・公開済みを見える化する。

## 対象チャンネル

- Instagram: 作品画像、制作過程、世界観、完成報告、ストーリー性のある投稿を重視する。
- X: 制作ログ、短い気づき、進捗報告、告知、会話のきっかけになる投稿を重視する。

## 投稿ステータス

投稿は次の5段階で管理します。

1. `idea`: 投稿候補。素材や目的は未確定でもよい。
2. `drafting`: AIまたは担当者が原稿・画像説明・ハッシュタグを作成中。
3. `review`: ブランド、誤字、権利、公開可否を確認中。
4. `approved`: 公開可能。外部SNSへ手動投稿する準備ができている。
5. `published`: 外部SNSへ投稿済み。URL、投稿日、振り返りを記録する。

## 基本ワークフロー

1. 作品画像、制作内容、狙い、希望日を受け取る。
2. `projects/sns-operation/post-template.md` に沿って投稿ブリーフを作る。
3. Instagram案とX案を分けて原稿化する。
4. `projects/sns-operation/brand-guidelines.md` に照らしてセルフレビューする。
5. `projects/sns-operation/content-calendar.md` に投稿行を追加し、ステータスを更新する。
6. 承認後、担当者が外部SNSへ手動投稿する。
7. 投稿後にURL、結果メモ、改善点を追記する。

## AIへの依頼テンプレート

```text
以下の素材をもとに、OKUDA STUDIOのInstagramとX向け投稿案を作ってください。

- 作品名:
- 画像・動画の内容:
- 制作内容・背景:
- 伝えたいこと:
- 希望する投稿目的（認知 / 制作過程共有 / 完成報告 / 告知 / 販売導線 / その他）:
- 希望投稿日:
- 注意点・避けたい表現:

出力形式:
1. 投稿ブリーフ
2. Instagram案（本文、CTA、ハッシュタグ、画像代替テキスト）
3. X案（短文版、スレッド版、ハッシュタグ）
4. content-calendar.mdへ追加する行
5. レビュー観点
```

## 運用ルール

- 投稿原稿は必ずGitHub上でレビューしてから公開する。
- 外部SNSへの投稿は自動化しない。公開は担当者が手動で行う。
- 画像・音源・引用・固有名詞は、権利と公開可否を確認してから `approved` にする。
- NESゲーム関連の作業ファイル、特に `projects/nes-block-breaker/` はSNS運用構築の対象外とし、変更しない。
