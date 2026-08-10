# テストケース

**Grammar**: basic.sgra
**UID**: DOC-TESTS
**Version**: 1.0

テストケースは StrictDoc の標準概念ではない。 `basic.sgra` で `TEST_CASE` という
ノード型を自分で足してある。 足したので `GIVEN` `WHEN` `THEN` という Gherkin の 3 語も
そのままフィールドにできる。 見出しがシナリオ名を兼ねるので、 この文法は `SCENARIO`
というフィールドを持たない。

`.md` で文法の型を使うには、 見出しの直下の `Type` に型の名前を書く。

```text
## シナリオ名

**Type**: TEST_CASE
**UID**: TC-001
**TEST_RESULT**: Passed

**GIVEN**: 〜が〜の状態である。

**WHEN**: 〜が〜する。

**THEN**: 〜が〜する。
```

`**Type**:` と綴りの大文字小文字、 そして欄を並べる順の 3 つは、
`02-guide-for-human.md` の「ノード型もフィールドも好きなだけ足してよい」と
`08-review.md` の「書き方」にある。 **`TEST_CASE` にだけ効く落とし穴が 1 つある。**

この文法の `TEST_CASE` は `STATEMENT` を持たないので、 その中に地の文を書けない。
StrictDoc は `.md` の地の文を `Statement` と解釈する。 そのため `TEST_CASE` の中に
地の文を置くと、 StrictDoc は `Semantic error: Invalid requirement field: STATEMENT`
を出して停止する (0.27.1 で実測)。 説明は `TEST_REMARK` に書く。

`TEST_RESULT` は必須で、 `NotRun` `Passed` `Failed` `Blocked` の 4 択である。
`ISSUE_KEY` と `TEST_REMARK` は任意なので、 必要なシナリオにだけ書く。

関係の種類は `Parent` のまま、 `Role` で意味を変える。 ここでは `Verifies` を
付けた。 `Role` は使う前に文法側で宣言しておく必要がある。

この 4 件で `06-lower.md` の下位要求 4 件を 1 対 1 で覆っている。 覆えているか
どうかは、 左のツールバーのトレーサビリティマトリクスの画面で一目で分かる。

同じ 4 件が `03-usecases.md` の `UC-001` も検証している。 各テストの
`GIVEN` / `WHEN` / `THEN` はどれも「利用者が本ツールを実行する」という受入の高さで
書いてあり、 主成功シナリオ 1 本と拡張 3 本に 1 対 1 で並ぶためである。
拡張は `UC-001` の本文ではなく、 `03-usecases.md` の「ユースケースは要求の上に置く」の
対応表にある。

| テスト   | 下位要求 | `03-usecases.md` のどこ |
| -------- | -------- | ----------------------- |
| `TC-001` | `SW-001` | 主成功シナリオ          |
| `TC-002` | `SW-002` | 拡張 2a                 |
| `TC-003` | `SW-003` | 拡張 3a                 |
| `TC-004` | `SW-004` | 拡張 4a                 |

**1 つのテストが 2 つの親を持ってよい。** 高さの違う 2 つを同時に覆っているだけで、
矛盾ではない。 これを張らないと、 マトリクスで `UC-001` が未被覆に見える —
実際には覆えているのに、 である。

## Gherkin とは何か

**Type**: SECTION

Gherkin は、 振る舞いを 3 つに割って書くための言語である。 Cucumber という
テスト自動化の道具が読む形式として広まった。 公式の定義は 3 語をこう説明している。

| 語      | 何を書くか                              |
| ------- | --------------------------------------- |
| `Given` | 前提。 何かが起きる前の、 系の状態      |
| `When`  | 出来事。 人か外の系が起こす操作そのもの |
| `Then`  | 期待結果。 起きるはずのこと             |

割る理由は、 前提と操作と結果が混ざった文が検証できないからである。
「壊れたファイルを渡すと異常終了する」 と 1 文で書くと、 何を用意すれば試せるのかが
読み取れない。 3 つに割れば、 用意するもの・押すもの・見るものがそれぞれ決まる。

**StrictDoc のフィールドは繰り返せない。** Gherkin の `And` と `But` は
別のフィールドにできないので、 `GIVEN` の中に複数行書く。

```text
**GIVEN**: 変換できる入力ファイルがある。
出力先に同名のファイルは無い。
```

この一式が使うのは `Given` / `When` / `Then` の 3 語だけである。 Gherkin には
`Feature` `Rule` `Scenario Outline` `Examples` `Background` などもあるが、
StrictDoc の文書構造が同じ役割を果たすので採らない。 `Feature` は文書と章、
`Scenario` は見出しに当たる。

### 原典

**Type**: SECTION

- Gherkin の公式リファレンス — <https://cucumber.io/docs/gherkin/reference/>
  語の一覧と、 `Given` / `When` / `Then` それぞれの定義が載っている。
  本書の 3 語の説明は、 このページの定義をなぞったものである。

## 変換が成功する

**Type**: TEST_CASE
**UID**: TC-001
**TEST_RESULT**: Passed

**GIVEN**: 利用者が指定した形式の入力ファイルを 1 つ用意し、 出力先に同名のファイルが無い。

**WHEN**: 利用者が本ツールを実行する。

**THEN**: 本ツールが正常終了し、 利用者が指定した形式の出力ファイルを作る。

**Relations**:

- **Type**: `Parent`
  **ID**: `SW-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `UC-001`
  **Role**: `Verifies`

## 想定外の形式を拒否する

**Type**: TEST_CASE
**UID**: TC-002
**TEST_RESULT**: Failed
**ISSUE_KEY**: PROJ-142

**GIVEN**: 利用者が指定した形式ではない入力ファイルを 1 つ用意する。

**WHEN**: 利用者が本ツールを実行する。

**THEN**: 本ツールが異常終了し、 出力ファイルを作らない。

**Relations**:

- **Type**: `Parent`
  **ID**: `SW-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `UC-001`
  **Role**: `Verifies`

## 既存ファイルを上書きしない

**Type**: TEST_CASE
**UID**: TC-003
**TEST_RESULT**: NotRun

**GIVEN**: 利用者が出力先に、 本ツールが作る出力ファイルと同じ名前のファイルを置く。

**WHEN**: 利用者が本ツールを実行する。

**THEN**: 本ツールが異常終了し、 既存ファイルの中身が変わらない。

**Relations**:

- **Type**: `Parent`
  **ID**: `SW-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `UC-001`
  **Role**: `Verifies`

## 中断しても不完全なファイルを残さない

**Type**: TEST_CASE
**UID**: TC-004
**TEST_RESULT**: Blocked
**ISSUE_KEY**: PROJ-207

**GIVEN**: 本ツールが出力ファイルを書き出している途中である。

**WHEN**: 利用者が本ツールの処理を強制終了する。

**THEN**: 本ツールが出力先に不完全なファイルを残さない。

**TEST_REMARK**: 検証チームが、 書き出しの途中で処理を止める手順をまだ用意していない。 手順が揃うまで、 検証チームはこのシナリオを保留する。

**Relations**:

- **Type**: `Parent`
  **ID**: `SW-004`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `UC-001`
  **Role**: `Verifies`
