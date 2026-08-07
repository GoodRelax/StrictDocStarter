# 基本 - テストケース

**Grammar**: basic.sgra \
**UID**: DOC-TESTS \
**Version**: 1.0

テストケースは **StrictDoc の標準概念ではない。** `basic.sgra` で `TEST_CASE` という
ノード型を自分で足してある。 足したので `EXPECTED` という独自のフィールドも持てる。

`.md` で文法の型を使うには、 見出しの直下の `Type` に型の名前を書く。

```text
## 変換が成功する

**Type**: TEST_CASE \
**UID**: TC-001
```

**ここに `.md` 固有の落とし穴が 2 つある。**

1. **`Type` は型の指定に使われる名前なので、 文法側に `TYPE` という名前の
   フィールドを作ってはならない。** 作ると `.md` から書けなくなる。
2. **カスタムフィールドのキーは文法どおりの大文字で書く。** `EXPECTED` は通るが
   `Expected` は落ちる。 一方 `Statement` や `Title` などの組み込み 8 語だけは
   大文字小文字を問わない。 **この非対称は覚えるしかない。**

**関係の種類は `Parent` のまま、 `Role` で意味を変える。** ここでは `Verifies` を
付けた。 `Role` は使う前に文法側で宣言しておく必要がある。

この 4 件で `04-lower.md` の下位要求 4 件を 1 対 1 で覆っている。 覆えているか
どうかは、 左のツールバーの**トレーサビリティマトリクス**の画面で一目で分かる。

## 変換が成功する

**Type**: TEST_CASE \
**UID**: TC-001

**Statement**: 想定した形式の入力ファイルを与え、 出力先に同名のファイルが無い状態で実行する。

**EXPECTED**: 正常終了し、 出力ファイルが指定した形式で生成されている。

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-001` \
  **Role**: `Verifies`

## 想定外の形式を拒否する

**Type**: TEST_CASE \
**UID**: TC-002

**Statement**: 指定した形式ではない入力ファイルを与えて実行する。

**EXPECTED**: 異常終了し、 出力ファイルが生成されていない。

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-002` \
  **Role**: `Verifies`

## 既存ファイルを上書きしない

**Type**: TEST_CASE \
**UID**: TC-003

**Statement**: 出力先に同名のファイルを置いた状態で実行し、 実行の前後でその中身を比べる。

**EXPECTED**: 異常終了し、 既存ファイルの中身が変わっていない。

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-003` \
  **Role**: `Verifies`

## 中断しても不完全なファイルを残さない

**Type**: TEST_CASE \
**UID**: TC-004

**Statement**: 書き出しの途中で処理を強制終了させ、 出力先の状態を確認する。

**EXPECTED**: 出力先に不完全なファイルが残っていない。

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-004` \
  **Role**: `Verifies`
