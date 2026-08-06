# NES Pseudo 3D Racer

`projects/nes-pseudo3d-racer/` は Mapper 0 / NROM を前提にした、NES 向けのオリジナル擬似 3D レースゲーム試作です。既存の BLOCK BREAKER などのプロジェクトとは独立した新規プロジェクトです。

## 操作方法

- **START**: タイトルから開始、プレイ中は PAUSE、CLEAR / GAME OVER 後はタイトルへ戻る
- **十字キー 左右**: ステアリング
- **A**: アクセル
- **B**: ブレーキ

## ルール

画面下部の自車を操作し、制限時間内にゴール距離へ到達すると **CLEAR** です。時間が 0 になると **GAME OVER** です。道路外へ大きく外れると減速し、敵車に近い距離で接触すると減速とスピン用タイマーが入り、ノイズ効果音が鳴ります。

## 擬似 3D 表現の仕組み

- 地平線より下の背景タイルを VBlank 中に描き直し、奥の行ほど細く、手前の行ほど太い道路幅になるようにしています。
- コース進行度 `DistanceHi` から `CourseCurve` 配列を参照し、直線、右カーブ、左カーブ、強めの右カーブを切り替えます。
- 道路中心 `RoadCenter` と行ごとの幅テーブル `RoadWidths` / `RoadOffsets` により、道路全体が左右へずれて見える簡易カーブを作っています。
- 中央線は `FrameCounter` に連動して点滅し、速度が上がるほど距離と敵車 Z が速く進むため、道路が手前へ流れてくる感覚を出します。
- 複雑なスキャンライン割り込みに依存せず、背景タイル更新と OAM DMA を中心にした安定性優先の構成です。

## 技術メモ

- アセンブラ: 本物の ClusterM/nesasm を `tools/setup_nesasm.sh` で取得・ビルドします。
- Mapper: 0 / NROM
- CHR: CHR RAM (`.ineschr 0`)
- ゲーム状態: `TITLE`, `PLAY`, `PAUSE`, `CLEAR`, `GAME OVER`
- OAM: `$0200` から NMI 内で OAM DMA を実行します。
- RAM 状態: 速度、道路中心、曲率、距離、残り時間、敵車 Z / レーン、自車 X をゼロページ中心に管理します。

## ビルド方法

```sh
make -C projects/nes-pseudo3d-racer
```

生成物:

```text
projects/nes-pseudo3d-racer/build/main.nes
```

クリーンビルド:

```sh
make -C projects/nes-pseudo3d-racer clean
make -C projects/nes-pseudo3d-racer
```

## 未確認点・既知の制限

- この環境では FCEUX などのエミュレータによる実操作確認は行っていません。入力遅延や難易度の最終感触は未確認です。
- 敵車のスケーリングは NES スプライト制約を優先し、遠近でタイルと Y 座標を変える簡易表現です。
- HUD の数値は最小実装の 16 進風表示で、今後 10 進表示タイルを追加すると読みやすくできます。
- BGM は入れず、速度に応じた簡易エンジン音とイベント効果音を中心にしています。
