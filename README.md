# aviutl2-scene-lighting

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

AviUtl2 用のシーンライティング アニメーション効果です。
背景レイヤーの環境光を前景オブジェクト（キャラクターイラスト等）のエッジに動的に適応させ、
合成映像のリアリティを向上させます。

## 機能

- **環境色サンプリング & ブレンド** — 背景を低密度サンプリングして代表色を抽出し、乗算・スクリーン・オーバーレイ・加算の 4 種のブレンドモードで前景に合成
- **ライトラップ** — アルファ境界の内側エッジ領域に背景色を加算合成し、背景光の回り込み（回折）をシミュレート
- **疑似法線リムライト** — エッジマスクの勾配から疑似法線を生成し、エッジ領域のみにリムハイライトを付加（全画素 Sobel によるピローシェーディングを回避）

## 必要環境

- Windows x86_64
- AviUtl2（beta46に動作確認済み）

## インストール

1. [Releases](https://github.com/beive60/aviutl2-scene-lighting/releases) から最新の `scene_lighting.au2pkg.zip` をダウンロードします。
1. `scene_lighting.au2pkg.zip` を解凍し、`@scene_lighting.anm2` を `C:\ProgramData\aviutl2\Script` または `C:\ProgramData\aviutl2\Script\Beive60`にコピーする
1. AviUtl2 を再起動する

## 使い方

基本的な使い方：

1. 前景オブジェクト（キャラクター画像など）にアニメーション効果「scene_lighting@scene_lighting」を追加する
2. 背景レイヤーのトラックバーで参照先レイヤーを選択する（前景オブジェクトから相対的なレイヤー番号。例えば前景オブジェクトの一つ上のレイヤーを参照するなら `-1`）

### パラメータ一覧

| パラメータ | デフォルト | 説明 |
| --- | --- | --- |
| 背景レイヤー | −1 | 参照する背景レイヤーの相対オフセット（−20 〜 −1） |
| ブレンドモード | 1（スクリーン） | 0=乗算 / 1=スクリーン / 2=オーバーレイ / 3=加算 |
| 強度 | 50 | エフェクト全体の強度（%） |
| ブラー半径 | 15 | 平均サンプリングのステップ幅（大 = より広域平均） |
| エッジ幅 | 10 | ライトラップ / リムライトを適用するエッジ幅（px） |
| エッジ閾値 | 16 | エッジ検出のアルファ閾値 |
| ライトラップ | ON | 背景光の回り込み効果の有効 / 無効 |
| リムライト | ON | 疑似法線によるリムハイライトの有効 / 無効 |
| リムライト角度 | 45 | リムライト方向の角度（−180 〜 180 度、45 = 右上） |
| ベースカラー | 白（0xffffff） | 環境色に乗算するティントカラー。デフォルトの白は環境色のままになります |
| サンプリング | 0（平均） | 0=平均サンプリング / 1=中央点サンプリング |

## プロジェクト構成

```text
aviutl2-scene-lighting/
├── src/
│   └── @scene_lighting.lua    # 開発用ソース
├── docs/
│   └── architecture.md        # アーキテクチャ設計書
├── aviutl2.toml               # au2 CLI 設定
├── .stylua.toml               # StyLua 設定
├── .luacheckrc                # Luacheck 設定
└── README.md
```

## 開発

[CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## クレジット

- [aviutl2-cli](https://github.com/sevenc-nanashi/aviutl2-cli) — AviUtl2 スクリプト開発用 CLI

## ライセンス

[MIT](LICENSE) © 2026 べいぶ
