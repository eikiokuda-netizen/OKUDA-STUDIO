# STAR DROP（NES / NROM）

`projects/nes-falling-blocks/` は、Mapper 0 / NROM-128、CHR RAM構成のNES向けオリジナル落ちものブロックパズルです。既存のBLOCK BREAKERプロジェクトとは独立しています。

## 操作方法

- 十字キー 左/右: ミノを左右へ移動（押しっぱなし連続移動対応）
- 十字キー 下: ソフトドロップ（加点あり）
- A: 右回転
- B: 左回転
- START: ポーズ / ポーズ解除
- GAME OVER後 START: タイトル画面へ戻る

## ゲームルール

- 4マス構成のブロックが画面上部から落下します。
- 床または固定済みブロックに接触した状態が短時間続くと固定されます。
- 横一列が埋まるとライン消去演出後に消え、上のブロックが下へ詰まります。
- 複数ライン同時消去に対応しています。
- SCORE、LINES、LEVEL、NEXTをゲーム画面右側に表示します。
- ライン消去数に応じてレベルが上がり、落下速度が速くなります。
- 7種類の基本的な4マスブロックを使用します。
- 7バッグ方式で次ブロックを生成し、乱数の極端な偏りを抑えています。

## ビルド方法

```sh
make -C projects/nes-falling-blocks
```

生成物:

```text
projects/nes-falling-blocks/build/main.nes
```

クリーン後の再ビルド:

```sh
make -C projects/nes-falling-blocks clean
make -C projects/nes-falling-blocks
```

## 技術メモ

- 本物のClusterM/nesasmを使用します（既存の `projects/nes-block-breaker/tools/bin/nesasm` を自動セットアップして利用）。
- ゲーム状態は TITLE / PLAY / PAUSE / LINE CLEAR / GAME OVER に分離しています。
- VBlank/NMIでOAM DMAを行い、背景更新要求があるときだけPPU更新を行います。
- プレイフィールドはRAM上の10x20配列で管理しています。
- 衝突判定、回転、固定、ライン消去、落下処理はサブルーチン化しています。

## 未確認点

- FCEUX等の実機系エミュレータでの操作確認は、この非対話環境では未実施です。
- 音量バランスとDAS/ARRの細かな感触は、実機またはエミュレータでの追加調整を推奨します。
