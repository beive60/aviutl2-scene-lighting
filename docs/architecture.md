# aviutl2-scene-lighting — Architecture

## 概要

AviUtl2 のアニメーション効果（`.anm2`）として動作するシーンライティングフィルタです。
背景レイヤーの環境光を前景オブジェクト（キャラクターイラスト等）のエッジに動的に適応させ、
合成映像のリアリティを向上させます。

---

## 処理パイプライン

```text
┌────────────────────────────────────────────────────────────────┐
│  入力                                                          │
│    fg_data  : 前景オブジェクトの BGRA バイト列                 │
│    bg_data  : 背景レイヤーの BGRA バイト列（任意）             │
└──────────────────────┬─────────────────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │  パス 1                 │
          │  前景ピクセルデータ取得 │  obj.getpixeldata()
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  パス 2                 │
          │  背景レイヤーデータ取得  │  pcall { obj.load("layer"), obj.copybuffer, obj.getpixeldata }
          │  ※ 失敗時はフォールバック│    → フォールバック: 環境色グレー (128, 128, 128)
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  パス 3                 │
          │  環境色サンプリング     │  平均サンプリング / 中央点サンプリング
          │  + ティント乗算         │  → amb_r, amb_g, amb_b
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  パス 4                 │
          │  アルファエッジ検出     │  4 近傍比較 → エッジ境界画素を dist=0 で初期化
          │  + 2 パス距離変換       │  順方向・逆方向パスで Manhattan 距離を伝播 (O(N))
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  パス 5                 │
          │  コンポジット           │
          │  (a) 環境色ブレンド     │  全不透明画素: blend_fn(fg, amb) × intensity
          │  (b) ライトラップ       │  エッジ領域: bg局所色加算 × edge_mask × 0.5
          │  (c) リムライト         │  エッジマスク勾配 → 疑似法線 → ライト内積
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  出力                   │
          │  obj.putpixeldata()     │  1024 バイトチャンクで string.char 変換
          └─────────────────────────┘
```

---

## モジュール設計

各パスは `src/@scene_lighting.lua` 内の独立した論理セクションとして実装されており、
コメントでパス番号と役割を明記している。

| パス | 役割 | 計算量 |
| --- | --- | --- |
| 1 | 前景データ取得 | O(1) |
| 2 | 背景データ取得（pcall） | O(1) |
| 3 | 環境色サンプリング | O(N / step²) |
| 4 | エッジ検出 + 距離変換 | O(N) |
| 5 | コンポジット | O(N) |

全パスの合計計算量は **O(N)**（N = 画素数）。
Sobel フィルタ等の全画素勾配計算（ピローシェーディングの原因）は排除し、
疑似法線はエッジ領域（`dist_map[i] < edge_width`）のみで評価する。

---

## データ構造

### `dist_map` テーブル

```text
dist_map[i] の意味:
  nil    透明画素 (alpha < edge_threshold)
         → 距離変換の伝播を遮断する
  0      エッジ境界画素（不透明 AND 4 近傍に透明が存在）
  1..ew  エッジ境界からの Manhattan 距離
  INF    エッジから edge_width より遠い内部画素
```

距離変換は 2 パス（順方向 + 逆方向）の走査で実現する。
透明画素は `nil` のままにすることで、距離が透明領域を跨いで伝播しないよう保証する。

### エッジマスク値

```lua
em(i) = (dist_map[i] < edge_width) and (1.0 - dist_map[i] / edge_width) or 0.0
```

`em = 1.0`（境界直上）から `em = 0.0`（`edge_width` 画素内側）へ線形に減衰する。

### 疑似法線

エッジマスク値の中心差分で勾配を計算し、正規化して法線ベクトルとする。

```text
gx = em(i+1) - em(i-1)
gy = em(i+fg_w) - em(i-fg_w)
n  = normalize(gx, gy)
```

`light_dir` は UI の `rim_angle`（度）から導出する。

```lua
rad      = math.rad(rim_angle)
light_dx = math.cos(rad)
light_dy = -math.sin(rad)
```

ここで `light_dir = (light_dx, light_dy)` とみなす。

リムライト強度 = max(0, dot(n, light_dir)) × em × intensity

---

## UI パラメータ

| パラメータ | 型 | 範囲 | デフォルト | 説明 |
| --- | --- | --- | --- | --- |
| `bg_layer` | track (整数) | −20 〜 −1 | −1 | 参照する背景レイヤーの相対オフセット |
| `blend_mode` | track (整数) | 0 〜 3 | 1 | ブレンドモード (0=乗算, 1=スクリーン, 2=オーバーレイ, 3=加算) |
| `intensity` | track (整数) | 0 〜 100 | 50 | エフェクト全体の強度 (%) |
| `blur_radius` | track (整数) | 1 〜 100 | 15 | 平均サンプリングのステップ幅（大 = より広域平均） |
| `edge_width` | track (整数) | 1 〜 50 | 10 | ライトラップ / リムライトを適用するエッジ幅 (px) |
| `edge_threshold` | track (整数) | 1 〜 255 | 16 | エッジ検出のアルファ閾値 |
| `enable_wrap` | check (bool) | — | true | ライトラップの有効 / 無効 |
| `enable_rim` | check (bool) | — | true | リムライトの有効 / 無効 |
| `rim_angle` | track (整数) | −180 〜 180 | 45 | リムライト方向の角度（45 = 右上） |
| `tint_color` | color (int) | 0x000000 〜 0xffffff | 0xffffff | 環境色に乗算するティント |
| `sampling_method` | track (整数) | 0 〜 1 | 0 | サンプリング方法 (0=平均, 1=中央点) |

---

## 背景レイヤーバッファ取得戦略

`.anm2` スクリプトはオブジェクト単位で実行されるため、
別レイヤーのバッファへの直接アクセスは API 制約を伴う。
以下の順で取得を試み、すべて失敗した場合はフォールバック色でエフェクトを適用する。

```text
1. obj.load("layer", abs_layer, true)        ← 背景レイヤーを object に読み込む
2. obj.copybuffer("cache:scene_lighting/bg", "object")
   obj.getpixeldata("cache:scene_lighting/bg", "bgra") で取得
3. obj.copybuffer("object", "cache:scene_lighting/fg")  ← 前景を復元
4. フォールバック: amb = (128, 128, 128)     ← バッファ取得不可時
```

---

## プロジェクト構成

```text
aviutl2-scene-lighting/
├── src/
│   └── @scene_lighting.lua    # 開発用ソース
├── docs/
│   └── architecture.md        # 本ドキュメント
├── aviutl2.toml               # au2 CLI 設定
├── .stylua.toml               # StyLua 設定
├── .luacheckrc                # Luacheck 設定
└── README.md
```
