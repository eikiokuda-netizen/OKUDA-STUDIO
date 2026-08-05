# SNS Operation

OKUDA STUDIOのInstagramとX向け投稿企画・原稿・進捗管理をGitHub上で運用するための最小環境です。

このフォルダでは、外部SNSへの自動投稿やAPI接続は扱いません。AIが担当する範囲は、投稿案の作成、原稿化、レビュー補助、進捗管理用ドキュメントの更新までです。

## ファイル構成

- `content-calendar.md`: 投稿候補、制作状況、公開結果を管理するカレンダー。
- `brand-guidelines.md`: OKUDA STUDIOらしい投稿表現を保つための基準。
- `post-template.md`: 作品画像や制作内容から投稿案を作るためのテンプレート。
- `workflow.md`: `idea` から `published` までの運用手順。

## ステータス

投稿は次のステータスで管理します。

| Status | 意味 | 主な作業 |
| --- | --- | --- |
| `idea` | 投稿候補 | 素材、目的、投稿日候補をメモする |
| `drafting` | 原稿作成中 | Instagram/X向けの本文、CTA、ハッシュタグを作る |
| `review` | 確認中 | ブランド、権利、誤字、公開可否を確認する |
| `approved` | 承認済み | 手動投稿できる状態にする |
| `published` | 公開済み | 投稿URL、投稿日、結果メモを残す |

## 最小運用

1. `post-template.md` をコピーして投稿ブリーフを作成する。
2. AIにInstagram案とX案の作成を依頼する。
3. `brand-guidelines.md` に沿って確認する。
4. `content-calendar.md` に投稿行を追加し、ステータスを更新する。
5. `approved` になった投稿を担当者が手動で外部SNSへ公開する。
6. 公開後、ステータスを `published` にして投稿URLと振り返りを記録する。
