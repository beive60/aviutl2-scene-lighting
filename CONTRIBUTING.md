# Contributing

このリポジトリへのコントリビューションを歓迎します。
本プロジェクトは AviUtl2 用スクリプトを `aviutl2-cli` で開発・配置する構成です。

## 前提環境

- Windows x86_64
- [aviutl2-cli](https://github.com/sevenc-nanashi/aviutl2-cli) (`au2` コマンド)
- AviUtl2（`au2 prepare` で開発環境をセットアップ）
- StyLua（formatter）
- Luacheck（linter）

インストール例:

```powershell
au2 prepare
cargo binstall stylua
luarocks install luacheck
```

`aviutl2.toml` を変更した場合は、必要に応じて `au2 prepare` を再実行してください。

## リポジトリ構成

```text
aviutl2-scene-lighting/
├── src/
│   └── @scene_lighting.lua
├── regression/
│   └── regression.aup2
├── docs/
│   └── architecture.md
├── aviutl2.toml
├── .stylua.toml
├── .luacheckrc
└── README.md
```

重要な点:

- 開発時の正本は `src/@scene_lighting.lua` です。
- `au2 develop` / `au2 release` 実行時に `Script/@scene_lighting.anm2` として配置されます。
- `.aviutl2-cli/`、`logs/`、`release/` は生成物またはローカル検証用です。

## 開発フロー

通常の作業手順は次のとおりです。

1. `src/@scene_lighting.lua` を編集する。
2. `stylua src` で整形する。
3. `luacheck src` で静的検査する。
4. `au2 develop .\regression\regression.aup2` で開発環境に配置し、回帰用プロジェクトで確認する。
5. 変更内容に応じて `README.md` や `docs/architecture.md` を更新する。

VS Code を使う場合は、タスク `Lua: Format` と `Lua: Lint` を利用できます。

## Lua コーディング方針

- 手作業の列揃えスペースは使わず、StyLua による通常の Lua 形式に寄せてください。
- 整形は `.stylua.toml` を基準にします。
- AviUtl2 から注入されるグローバル変数は `.luacheckrc` と `.vscode/settings.json` に定義しています。
- 新しいトラックバーやチェック項目を追加した場合は、Luacheck と VS Code 診断設定の両方を同期してください。
- HLSL 埋め込み文字列を含むため、見た目だけを目的にした広範な再整形は避け、変更範囲を明確に保ってください。

## 検証

最低限、次を確認してください。

```powershell
stylua src
luacheck src
au2 develop .\regression\regression.aup2
```

確認時の観点:

- スクリプトが開発環境へ正常に配置されること
- `regression/regression.aup2` で意図した見た目とパラメータ挙動になっていること
- 追加・変更した UI パラメータが README と設計書に反映されていること

## ドキュメント更新の目安

次の変更を行った場合は、関連ドキュメントも更新してください。

- UI パラメータの追加、削除、既定値変更
- サンプリング、ブレンド、ライティング処理の仕様変更
- 開発フローや成果物配置の変更
- 回帰確認方法の変更

主な更新先:

- `README.md`: 利用者向けの使い方と開発手順
- `docs/architecture.md`: 内部実装と処理フロー
- `CONTRIBUTING.md`: コントリビューション手順

## Pull Request の目安

- 変更目的と背景を簡潔に書いてください。
- 実施した検証手順を本文に含めてください。
- 動作や見た目が変わる変更では、確認した条件や差分が分かる説明を含めてください。
- 無関係な整形やリファクタリングは分離してください。

## コミット対象について

通常は次をコミット対象にしません。

- `.aviutl2-cli/`
- `logs/`
- `release/`

判断に迷う場合は、変更の目的と検証内容が追える最小単位で Pull Request を作ってください。
