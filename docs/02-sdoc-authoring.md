# 02 `.sdoc` の書き方

**目的: 公式ユーザーガイドを毎回読まなくても `.sdoc` を書けるようにする。** 記述はすべて **strictdoc 0.27.1** で実際に走らせて確かめた。差異は「版による違い」に書いた。

**動く例は [`samples/sd-basic-ja/`](../samples/sd-basic-ja/)。** 本書の型はほとんどそこに実物がある。**カスタムノード型と独自フィールドだけは、同梱サンプルに実物が無い** — それを実演していた `sdoc-patterns` は保守の負担が見合わず削除した。JSON の引き方は [`03-sdoc-json-queries.md`](03-sdoc-json-queries.md)。

---

## 1. 最小の文書

**これ 1 ファイルで動く。** フォルダごと `launch-strictdoc.bat` にドロップすればよい。

`strictdoc_config.py` は**必須ではない**（無くても `export` は通る）。**要るのは、既定以外の機能を使うときだけ**である — 図からのリンク（§3）、差分画面、`SEARCH` 以外の画面など。置く場合は**入力フォルダそのもの**に置く。StrictDoc は親フォルダを探さない。

```
[DOCUMENT]
TITLE: 最小の要求文書

[TEXT]
STATEMENT: >>>
地の文はここに書く。
<<<

[REQUIREMENT]
UID: REQ-001
TITLE: 何かをすること
STATEMENT: >>>
本システムは、 何かをすること。
<<<

[REQUIREMENT]
UID: REQ-002
TITLE: 何かの下位要求
STATEMENT: >>>
本システムは、 何かの一部をすること。
<<<
RELATIONS:
- TYPE: Parent
  VALUE: REQ-001
```

| 決まりごと | 内容 |
|---|---|
| `[DOCUMENT]` | 1 ファイルに 1 つ。**先頭**に置く。`TITLE` は必須 |
| 単一行フィールド | `NAME: value` |
| 複数行フィールド | `NAME: >>>` … `<<<` |
| ノードの区切り | 空行 |
| `UID` | 文書をまたいで**一意**。関係はこれで張る |

## 2. 要求ノード

### フィールドの順序は強制される

**宣言順と違う順に書くとパースが落ちる。** 既定文法の順序は次のとおり。

```
MID → UID → LEVEL → STATUS → TAGS → TITLE → STATEMENT → RATIONALE → COMMENT
```

外すと `Semantic error: Wrong field order for requirement: [...]` が出る。エラーは実際の順序と文法の順序を並べて表示するので、それを見て直せばよい。

### `TITLE` と `STATEMENT` の使い分け

公式ユーザーガイドの指針は 2 文だけである。

> "Every requirement should have its `TITLE` field specified."
> "Every requirement shall have its `STATEMENT` field specified."
>
> — StrictDoc User Guide

強制されるのは **「`STATEMENT` か `TITLE` のどちらかがあること」** だけで、既定文法では全フィールドが `REQUIRED: False` である。

| 項目 | 実測結果 |
|---|---|
| `TITLE` の文字数制限 | **無い。** 強制も推奨も公式に存在しない。ソース上の長さ検査は「空でないこと」だけ |
| 長い `TITLE` を書くと | HTML の目次に**そのまま全文が出る**。省略されない |
| Markdown 形式では | `TITLE` が **見出しそのもの**になる |

> **目安（規則ではなく本書の助言）:** `TITLE` は一覧・目次・トレーサビリティ画面に並ぶ**索引**である。1 行に収まる長さにし、条件や理由は `STATEMENT` へ書く。

## 3. 関係の張り方

```
RELATIONS:
- TYPE: Parent
  VALUE: REQ-001
- TYPE: Parent
  VALUE: REQ-002
  ROLE: Verifies
- TYPE: File
  VALUE: src/convert.c
```

| 注意 | 内容 |
|---|---|
| 順序 | `TYPE` → `VALUE` → `ROLE`。`ROLE` を先に書くと落ちる |
| `ROLE` | 使うなら `.sgra` の `RELATIONS:` に宣言しておく |
| 向き | **親だけ書く。** 子は StrictDoc が逆算する |
| `TYPE: File` | `strictdoc_config.py` に `REQUIREMENT_TO_SOURCE_TRACEABILITY` と `include_source_paths` の**両方**が要る。無いと**エラーも警告も出さずにリンクが張られない**（JSON には残る） |

## 4. カスタム文法

足したフィールドは JSON にそのまま出る。**機械で引きたいものは、必ずノードのフィールドにする**（理由は §7）。

`patterns.sgra` を書き、各文書の先頭で読み込む。

```
[GRAMMAR]
ELEMENTS:
- TAG: REQUIREMENT
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: STATUS
    TYPE: SingleChoice(Draft, Reviewed, Approved, Revised)
    REQUIRED: False
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
  - TITLE: STATEMENT
    TYPE: String
    REQUIRED: True
  RELATIONS:
  - TYPE: Parent
  - TYPE: File
```

```
[DOCUMENT]
TITLE: ...

[GRAMMAR]
IMPORT_FROM_FILE: patterns.sgra
```

`TYPE` に使えるのは `String` / `SingleChoice(...)` / `MultipleChoice(...)` / `Tag`。`- TAG: <名前>` を足せば**新しいノード型**を作れる（例: `[FINDING]`）。

### 「指摘」と「修正」

**どちらも StrictDoc の標準概念ではない。** カスタム文法で作る。**同梱サンプルにこの形の実物は無い。** `samples/sd-basic-ja/04-review.sdoc` はもう一方の形 — 指摘を要求そのものの `REVIEW_STATUS` / `REVIEW_COMMENT` に書く形 — を採っており、両者の使い分けもそこに書いてある。

| 概念 | 作り方 |
|---|---|
| 指摘 | 独立したノード型 `- TAG: FINDING` にし、`ROLE: Reviews` で対象要求へ結ぶ |
| 修正 | 要求自身のフィールド `REVISION` にする |

## 5. 図と数式

```
.. raw:: html

    <pre class="mermaid">
    flowchart LR
      A --> B
    </pre>

.. image:: _assets/foo.svg

.. math::

    E = mc^2
```

`.. list-table::` などの reStructuredText もそのまま使える。

> **図を別文書に出す動機は「人が読みやすいこと」であって「JSON が軽くなること」ではない。** `samples/md-sovd-automotive-ja/` で実測したところ、Mermaid 15 ブロックは JSON 全体 623,085 バイトのうち **8,807 バイト（1.4 %）** に過ぎなかった（`export` が書いた JSON の中の Mermaid フェンスを数えた値）。この比は記法に依らないので `.sdoc` でも同じ結論になる。画像はもともと JSON に入らない。

## 6. Markdown 形式（experimental）

`.md` も入力形式である。**普通の Markdown は、H1 で始まってさえいれば無改造で通る。ただし要求ノードは 1 件も生まれない**（`SECTION` と `TEXT` になるだけ）。移行の手間は全部「要求ノードにする」ところにある。

**H1 は必須である。** 見出しが無い / `##` から始まる / 空、のいずれでも**その 1 ファイルが export 全体を止める**（実測）。

```text
Semantic error: Markdown parsing error: the document must start with an H1 heading.
```

**そして `.md` は置き場所を問わず解析される。`_assets/` の中でも同じ**である。「アセット置き場だから解析対象外」ということは無い — StrictDoc はアセット探索（`_assets` という名前のフォルダを探す）と文書探索（拡張子で探す）を**独立に 2 回**走らせており、後者が無視するのは出力先フォルダだけである（`document_finder.py`、0.27.1 のソースで確認）。

**文書にできない `.md` は `exclude_doc_paths` でファイル名を名指しして外す。フォルダごと外してはならない** — `exclude_doc_paths` は 2 つの走査の**両方**に渡されるため、`_assets/**` と書くとアセット置き場としても認識されなくなり、**同じフォルダの画像が黙ってコピーされなくなる**（export は成功と報告し、`<img>` だけが 404 になる）。

```markdown
# 文書タイトル

**Grammar**: patterns.sgra \
**UID**: DOC-1 \
**Version**: 1.0

## 要求のタイトル

**UID**: MD-001 \
**STATUS**: Approved

**Statement**: 本システムは、 何かをすること。

**Relations**:
- **Type**: `Parent` \
  **ID**: `MD-000`
```

| 規則 | 内容 |
|---|---|
| 要求になる条件 | `UID`（または `MID`）**と** `Statement` の**両方**があること。片方だけなら `SECTION` になる |
| 暗黙の `STATEMENT` | 見出し直下の地の文は `Statement` として扱われる |
| 行末の `\` | 他の Markdown ビューアでメタ行をひと塊に見せるためのもの。StrictDoc の解析には**不要** |
| ノード型の指定 | `**Type**: FINDING`。`**Type**: SECTION` は強制的に節にする |
| 文法 | `**Grammar**: patterns.sgra` または `**Grammar**: patterns.gra.md` |

`.gra.md` の書き方（0.27.1 で確認）:

```markdown
# StrictDoc Markdown Grammar

## Element: REQUIREMENT

### Field: UID

**Type**: String
**Required**: True

### Relations

#### Relation: Parent
```

## 7. やってはいけないこと

| # | 内容 |
|:-:|---|
| 1 | **文書にならない `.md` をツリーに残さない。** すべての `.md` が StrictDoc 文書として解析され、H1 で始まらないファイルや UTF-8 でないファイルが 1 つあると **export 全体が失敗する**。README や第三者からのコピーは `exclude_doc_paths` で**ファイル名を名指しして**除外する。**フォルダごと除外してはならない** — アセット置き場として認識されなくなり、同じフォルダの画像が黙ってコピーされなくなる（export は成功と報告し、`<img>` だけが 404 になる）。逆に、**図を入れた `.md` は文書にするのが正しい**。文書だからこそ ` ```mermaid ` が描画される（`samples/md-basic-ja/_assets/fig-state.md`） |
| 2 | **フィールドを宣言順と違う順に書かない**（§2） |
| 3 | **関係で `ROLE` を `VALUE` より先に書かない**（§3） |
| 4 | **文書レベルのメタデータに、機械で引きたい値を置かない。** `DATE:` と `METADATA:` ブロックは `.sdoc` / `.md` には往復するが **JSON にはまったく出ない**（`json_generator.py` が書くのは `UID` / `VERSION` / `CLASSIFICATION` / `PREFIX` / `ROOT` だけ）。作成日・作成者・承認者を引きたいならノードのフィールドにする |
| 5 | **JSON を「小さくなるもの」と考えない。** `strictdoc export --formats=json` は `json.dumps(..., indent=4)` で書くため、非 ASCII が `\uXXXX` に展開され 4 スペースで整形される。`sd-basic-ja` では **`.sdoc` の 3.49 倍**（トークン数）になった。JSON の利点は小ささではなく、**クエリで答えだけを取り出せること**である（[`03-sdoc-json-queries.md`](03-sdoc-json-queries.md)） |
| 6 | **JSON を辿る目的で `--included-documents` を付けない。** `DOCUMENT_FROM_FILE` で取り込んだ文書が**独立した文書としても重複**し、同じ UID が 2 か所に現れる |
| 7 | **カスタム文法を使ったまま `--formats=markdown` の往復に頼らない**（§8） |
| 8 | **JSON から取り込めると思わない。** 取り込めるのは ReqIF と Excel だけで、**JSON は出力専用**である |

## 8. `.sdoc` から `.md` へ出す

```bash
strictdoc export --formats=markdown --output-dir out .
```

出力は `out/markdown/*.md`。**`.sdoc` で書き、人に見せるときだけ `.md` に出す**という使い方は成り立つ。

**ただし往復は無損失ではない。** 出した `.md` を読み戻すと、`OPTIONS: MARKUP: Markdown` と `METADATA:` ブロックが増え、`>>> <<<` の複数行が 1 行に畳まれ、File 関係の `VALUE:` が `PATH:` になる。値そのものは失われない。

**そしてカスタム文法では、出した `.md` を StrictDoc 自身が読み戻せないことがある。** Markdown reader が復元する順序が決まっているためで、文法をこの順に宣言していないと `Wrong field order` で落ちる。

```
MID → UID → LEVEL → STATUS → TAGS  （既知のメタフィールド）
  → TITLE                          （見出しになる）
  → カスタムの単一行フィールド
  → STATEMENT
  → 残りの複数行フィールド（RATIONALE / COMMENT / カスタム）
```

## 9. 前提とする版

**本書と同梱サンプルは strictdoc 0.27 以降を前提とする。** `setup-strictdoc.bat` の既定（`strictdoc.version: latest`）はこれを満たす。

0.27 で効いてくる点を挙げる。**古い版を意図して使う場合はここが変わる。**

| 項目 | 0.27.1 での挙動 |
|---|---|
| `MATHJAX` / `MERMAID` | **既定で有効。`strictdoc_config.py` に書く必要はなく、列挙すると DEPRECATION 警告が出る** |
| サブコマンド | `import` は無い。`convert` と `format` がある |
| `project_features` | `RAPIDOC` は無い |
| JSON の文書メタ | `UID` / `VERSION` / `CLASSIFICATION` が**出る**（`DATE` は出ない） |
| `.md` のフィールド表記 | `**Statement**:`（先頭大文字）。**大文字の `**STATEMENT**:` も読める** |
| `.gra.md` | 文法ファイルとして扱われる |

> **上の各行は 0.23.1 と 0.27.1 の両端で実際に走らせて確かめたものである。挙動が変わった中間の版（0.24 / 0.25 / 0.26）は特定していない。**

**`.md` 文書は `.gra.md` ではなく `.sgra` を参照できる。** 混在プロジェクトではそちらが安全である（`samples/md-basic-ja/04-upper.md` がその形）。
