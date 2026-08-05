# SNS Operation Workflow

GitHub上でInstagramとXの投稿を企画し、原稿化し、公開準備まで進めるための手順です。

## 1. idea

投稿候補を集める段階です。

- 作品画像、制作ログ、完成報告、告知などの素材をメモする。
- `content-calendar.md` に行を追加する。
- 情報が不足していてもよいが、`Theme / Work` と `Goal` は可能な範囲で書く。

## 2. drafting

投稿案を作る段階です。

- `post-template.md` を使ってInput Briefを作る。
- Instagram案とX案を分けて作成する。
- 画像がある場合は、画像代替テキストも作る。
- `Draft / PR` に原稿やレビュー場所への参照を記録する。

## 3. review

公開前確認の段階です。

- `brand-guidelines.md` に沿ってトーンを確認する。
- 誤字、リンク、日付、固有名詞、権利、未公開情報を確認する。
- InstagramとXで文量、CTA、ハッシュタグが適切か確認する。
- 修正が必要な場合は `drafting` に戻す。

## 4. approved

手動投稿できる状態です。

- 投稿本文、画像、ハッシュタグ、投稿日が確定している。
- 公開担当者が外部SNSへ手動投稿する。
- このリポジトリから外部SNSへ自動投稿しない。

## 5. published

投稿後の記録段階です。

- `content-calendar.md` のステータスを `published` にする。
- `Published URL` に投稿URLを記録する。
- `Notes` に反応、学び、次回改善点を追記する。

## Definition of Done

投稿を `published` とみなす条件は次の通りです。

- 外部SNSに投稿済みである。
- 投稿URLが記録されている。
- 実際の投稿日が確認できる。
- 次回に活かすメモが残っている。
