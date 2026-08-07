# StrictDoc の `.md` 仕様書 — AI 向け手引き

**本書は、AI がこのフォルダの形式で仕様書を書き、そこから必要な情報を取り出すための手引きである。**
本書 1 つで足りる。ほかの解説文書を読む必要はない。

このフォルダの構成。**`.md` はすべて文書として解析される** — `exclude_doc_paths` で外したものを除く。

| ファイル | 中身 | 文書になるか |
|---|---|---|
| `basic.sgra` | 文法定義。ノード型・フィールド・`Role` はここで宣言する | — |
| `02-upper.md` | 上位要求 3 件 | `DOC-UPPER` |
| `03-lower.md` | 下位要求 4 件。上位要求へ繋がる | `DOC-LOWER` |
| `04-tests.md` | テストケース 4 件。下位要求へ繋がる | `DOC-TESTS` |
| `05-review.md` | レビュー指摘 2 件。対象の要求へ繋がる | `DOC-REVIEW` |
| `01-guide-for-human.md` | 人間向けの解説書。**AI は読まなくてよい** | `DOC-GUIDE` (要求は無い) |
| `_assets/note.md` | 用語表。リンク先 | `DOC-NOTE` (要求は無い) |
| `00-guide-for-AI.md` / `00-queries-for-AI.md` | 本書と詳細版 | **ならない** (`exclude_doc_paths`) |
| `strictdoc_config.py` | プロジェクト設定。`exclude_doc_paths` などを書く | — |

**後の用例 1 は文書を 6 件返す。** 上表のうち「文書になる」もの全部である。
`DOC-GUIDE` と `DOC-NOTE` は要求を持たないので、要求を数えるときは混ざらない。

コマンド例は Git Bash で実行する前提で書いてある。

---

## 1. 仕様書を書く

以下は strictdoc 0.27.1 で parse 確認済みの雛形である。`DOCUMENT` / `TEXT` / `SECTION` /
`REQUIREMENT` / カスタムノード型の 5 種が生成される。

```markdown
# 文書のタイトル

**Grammar**: basic.sgra \
**UID**: DOC-UPPER \
**Version**: 1.0

H1 の直下は地の文になる。 UID が無いので要求ではない。

## 章の名前

**Type**: SECTION

章の中の地の文。 `Type` を書かないと、 この段落は要求の本文と見なされる。

## 要求の名前

**UID**: SW-001 \
**STATUS**: Approved

**Statement**: 本システムは、 〜すること。

**Rationale**: そう決めた理由。

## テストケースの名前

**Type**: TEST_CASE \
**UID**: TC-001

**Statement**: 〜の条件で実行する。

**EXPECTED**: 〜になっている。

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-001` \
  **Role**: `Verifies`
```

行末の `\` は StrictDoc の解析には不要である。StrictDoc 以外の Markdown ビューアで、
連続する行が 1 行に繋がって表示されるのを防ぐために付けている。

### 違反すると export 全体が停止する規則

| 規則 | 違反時のエラーメッセージ |
|---|---|
| ファイルの先頭を H1 で始める。1 ファイルに 1 つだけ | `the document must start with an H1 heading` |
| 見出しの直後に空行を 2 つ以上置かない | `two or more consecutive empty lines are not allowed` |
| フィールド名は文法どおりの綴りで書く | `Invalid requirement field` |
| 文法に `TYPE` という名前のフィールドを作らない | 型の指定に使う名前なので `.md` から書けなくなる |
| 宣言されていない `Role` を書かない | `Semantic error: Requirement relation type/role is not registered: Parent / Verifies` |

**原因が書かれていないエラーが 1 つある。**

```text
error: A process in the process pool was terminated abruptly while the future was running or pending.
```

**ファイル名も行番号も出ない。** 行継続の `\` が壊れているときなどに出る。
`strictdoc --debug export ...` を付け直すと stack trace が出るので、そこから当たる。

### 実例を見ても分からない規則

- **見出しの直下に置いた文は、暗黙の `Statement` として扱われる。** その結果、その見出しは
  要求ノードになる。要求ではない章には `**Type**: SECTION` を明記する。明記しないと
  「`UID` が無い」という理由で停止する。**ただし H1 の直下だけは例外**で、常に地の文になる
- **フィールド名の大文字小文字**: `Statement` `Title` `Status` `Rationale` `Comment` `Level`
  `Tags` `Prefix` の 8 語だけは大文字小文字を問わない。それ以外は文法どおりに書く
  (`EXPECTED` は通るが `Expected` は停止する)。**判断できないときは全部大文字で書く**
- **繋がりは下位の側に書く。** 下位のノードに `**Relations**:` を置き、親の UID を指す。
  上位の側には何も書かない。親が別のファイルにあってもよい (StrictDoc はプロジェクト全体で
  UID を解決するため)
- **`Role` を書けるのは、その節点型の関係に `ROLE` が宣言されている場合だけである。**
  `basic.sgra` の宣言は次のとおり。**下位要求に `Role` を付けてはならない** —
  テストケースの書き方をそのまま真似すると停止する
  | 節点型 | 書ける関係 |
  |---|---|
  | `REQUIREMENT` | `Parent` / `Child`。**`Role` は付けられない** |
  | `TEST_CASE` | `Parent` + `Role: Verifies` |
  | `FINDING` | `Parent` + `Role: Reviews` |
- **関係の中だけ `**ID**:` である。** ノードの識別子は `**UID**:` だが、`**Relations**:`
  ブロックの中で相手を指すキーは `**ID**:` になる。`**UID**:` と書くと通らない
- **`Type` は `.md` 上でノード型を選ぶための予約語であり、文法のフィールドではない。**
  だから `**Type**: TEST_CASE` は書けるのに、文法に `TYPE` という名前のフィールドは作れない
- **フィールドの並び順は `basic.sgra` の `FIELDS` 宣言順の制約である** (`.md` に書く順ではない)。
  `UID → STATUS → TITLE → カスタムの単一行フィールド → STATEMENT →
  RATIONALE などの複数行フィールド` の順で宣言する。`--formats=sdoc` で `.sdoc` に変換して
  読み戻すとき、この順でないと `Wrong field order` で停止する
- **フォルダ内の `.md` は、置き場所に関係なくすべて文書として解析される。** `_assets/` の中も
  例外ではないため、そこに置く `.md` にも H1 が必要である
- **文書として解析させたくない `.md` は、`strictdoc_config.py` の `exclude_doc_paths` に
  ファイル名で指定する。** `_assets/**` のようにフォルダごと指定してはならない。指定すると
  画像もコピーされなくなり、export は成功と報告するのに HTML の画像だけが 404 になる
- 図は Mermaid のコードフェンスをそのまま本文に書ける。画像は `_assets/` に置いて
  `![alt](path)` で参照する。表はパイプ表のみが使え、桁を揃える必要はない
- **ノード型・フィールド・`Role` を追加するときは `basic.sgra` に追加する。**
  個別の文書に追加してはならない

**新しくプロジェクトを起こすときの最小構成** (実測):

```text
<プロジェクトフォルダ>/
  basic.sgra        ← 文書と同じフォルダに置く。**Grammar**: basic.sgra はここを指す
  02-upper.md
  03-lower.md
```

**`strictdoc_config.py` は無くても export は通る。** `exclude_doc_paths` や画面の設定が
要るときだけ、このフォルダの直下に置く (親フォルダには置かない。読まれない)。

---

## 2. 仕様書から必要な部分だけを取り出す

**仕様書の一部だけが必要なとき、`.md` ファイルを読んではならない。**
このフォルダの `.md` を全部読むと約 2,900 tokens を消費する。
JSON に変換して `jq` で取り出せば、1 回あたり 5〜100 tokens で済む。

### 手順 1 — JSON に変換する

```bash
strictdoc export <仕様書のフォルダ> --formats=json --output-dir <出力先>
```

`<出力先>/json/index.json` が生成される。以下ではこのファイルを `<json>` と表記する。

**`<出力先>` は仕様書のフォルダの外にすること。** 中に置くと、次の export が自分の出力を
文書として読み直す。`%TEMP%` 配下など、作業用の場所を使う。

**`.md` を修正したら、再度この `strictdoc export` を実行すること。**
JSON は自動では更新されない。

**この `index.json` を直接読んではならない** — 約 30,000 tokens ある。
`jq` に読ませるためだけのファイルである。

**StrictDoc 自身にも問い合わせ言語があるが、JSON 出力には効かない。**
`--filter-nodes` は `.sdoc` と HTML の出力しか絞り込まない。`--formats=json` に付けても
**エラーも警告も出さないまま全件が出力される**。絞り込みは `jq` で行う。

### 手順 2 — jq で取り出す

JSON の構造:

```json
{"DOCUMENTS": [
  {"_NODE_TYPE": "DOCUMENT", "UID": "...", "TITLE": "...", "GRAMMAR": {},
   "NODES": [
     {"_NODE_TYPE": "SECTION", "TITLE": "...", "NODES": []},
     {"_NODE_TYPE": "REQUIREMENT", "UID": "...", "TITLE": "...", "STATEMENT": "...",
      "RELATIONS": [{"TYPE": "Parent", "VALUE": "...", "ROLE": "..."}]}]}]}
```

ノードは入れ子になっている。**平坦化には次の定型を使う。**

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | .UID + "  " + .TITLE' <json>
```

- ノード型を判定するキーは `_NODE_TYPE` である。**先頭に下線が付く。** `_TOC` `_OPTIONS` も同様
- **`.md` のファイルパスは JSON に入っていない。** 「特定のファイルの要求だけ」を取り出すには、
  文書の `UID` (`DOC-UPPER` など) で絞る。文書の UID は用例 1 で調べる
- `_TOC` は `2.1.1` のような階層番号である。章単位で絞るときに使う
- **JSON に「子」は記録されていない。** ある要求の子を取り出すには、全ノードを走査して
  「親がその要求であるもの」を集める
- `RELATIONS` には `Parent` も `File` も同じ配列に入る。親だけが必要なら
  `select(.TYPE=="Parent")` で絞り込む
- **`--included-documents` を付けてはならない。** 取り込んだ文書が重複し、
  同じ UID が 2 か所に現れる
- `DATE` と `METADATA:` は JSON に含まれない。文書レベルのメタ情報は
  `UID` / `VERSION` / `CLASSIFICATION` / `PREFIX` / `ROOT` のみ
- `-r` を付けると人が読む行として出力され、付けなければ JSON のまま出力される。
  **プログラムで処理するなら付けない**
- 日本語は `index.json` の中では `\uXXXX` に変換されているが、`jq` の出力では
  元の文字に戻る。変換作業は不要である

### 用例

以下はすべて実行して出力を確認したものである。

```bash
# 1. まず何があるか — 文書の一覧
jq -r '.DOCUMENTS[] | (.UID // "-") + "  " + .TITLE' <json>

# 2. 型ごとに使えるフィールド名 (既存プロジェクトのスキーマを JSON から知る。
#    新規に書き起こすときは JSON がまだ無いので、basic.sgra を直接読むこと)
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE) | {t:._NODE_TYPE, k:keys}] | group_by(.t) | map({(.[0].t): (map(.k)|add|unique)}) | add' <json>

# 3. 要求の一覧を表で (最も安い)
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | [.UID, .STATUS, .TITLE] | @tsv' <json>

# 4. 特定の要求の全フィールド
jq -c 'first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002")) | del(.NODES)' <json>

# 5. 特定の文書だけに絞る (ファイル名では絞れない)
jq -r '.DOCUMENTS[] | select(.UID=="DOC-UPPER") | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | .UID + "  " + .TITLE' <json>

# 5b. 逆引き — 各ノードがどの文書に属するか
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | select(.UID? and ._NODE_TYPE!="DOCUMENT") | $doc + "  " + .UID + "  " + .TITLE' <json>

# 6. 正規表現で探す (第 2 引数はフラグ。"i" で大小無視。日本語も使える)
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.TITLE? and (.TITLE | test("変換|検査"; "i"))) | (.UID // "-") + "  " + .TITLE' <json>

# 7. and / or / not — not は後ろに置く
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="FINDING" and .SEVERITY=="Major" and .RESOLUTION=="Open") | .UID' <json>
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE" or ._NODE_TYPE=="FINDING") | .UID' <json>
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? and (._NODE_TYPE=="REQUIREMENT" | not)) | ._NODE_TYPE + " " + .UID' <json>

# 8. 直接の子 (逆引き)
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="SYS-001")) | .UID' <json>

# 9. 親を根までたどる (推移的)。unique でソートされるので出力の順は階層順ではない。
#    どれが根かは、返った UID を用例 4 で開いて RELATIONS が無いことで判定する
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)] as $all
| def anc($u): ($all[] | select(.UID==$u) | .RELATIONS? // [] | .[] | select(.TYPE=="Parent") | .VALUE) as $p | [$p], anc($p);
  [anc("TC-001")] | flatten | unique | .[]' <json>

# 10. テストケースから「直接」指されていない要求。
#     これは推移的なカバレッジではない。このサンプルでは SYS-001..003 が返るが、
#     3 件とも下位要求を経由してテストされている。欠陥ではない。
#     推移的に見るには、返った UID それぞれに用例 9 の逆 (子をたどる) を当てる
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $tested
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($tested[]) | not) | .UID + "  " + .TITLE' <json>

# 11. 存在しない UID を指す関係 (リンク切れ)。0 件が正常
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) | .UID] as $ids
| .DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) as $n
| ($n.RELATIONS // [])[] | select(.VALUE | IN($ids[]) | not) | $n.UID + " -> " + .VALUE' <json>

# 12. 件数だけ
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")] | length' <json>
```

上で足りないときだけ `00-queries-for-AI.md` を読む。26 本を用途別に分類し、出力例を付けてある
(約 3,100 tokens)。目次・章単位の絞り込み・推移的な子・ROLE での絞り込み・孤立要求の検出・
UID の重複検出などが載っている。
