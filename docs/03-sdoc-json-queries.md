# 03 JSON クエリ集

**目的: 仕様書の全文を読み直さずに、必要な答えだけを取り出す。**

以下はすべて [`samples/sd-basic-ja/`](../samples/sd-basic-ja/) に対して **strictdoc 0.27.1 / jq 1.8.1** で実行した結果である。出力は実物をそのまま貼ってある。書き方は [`02-sdoc-authoring.md`](02-sdoc-authoring.md)。

---

## 0. 準備

```bash
strictdoc export --formats=json --output-dir out samples/sd-basic-ja
```

`out/json/index.json` が生まれる。**要求を追加・修正したら毎回これを走らせ直す。**

### Windows での注意 — フィルタはファイルに書く

**PowerShell はクォートの中の `"` を落とすため、`jq '...' file` の形はそのままでは動かない。**

```text
jq: error: syntax error, unexpected ',' ...
    select(._NODE_TYPE==REQUIREMENT) | join(,)      <- " が消えている
```

**フィルタを `.jq` ファイルに保存して `-f` で渡せば、PowerShell でも Git Bash でも同じに動く。**

**本書の 5 本は [`docs/queries/`](queries/) にそのまま同梱してある。** 書き写す必要はない。

```powershell
jq -r -f docs\queries\q5-children.jq out\json\index.json
```

Git Bash なら `jq -r '<フィルタ本体>' out/json/index.json` と直接貼っても動く。本書は以下、各クエリの「フィルタ本体」を載せる。同梱ファイル名は各節の見出しに添える。

### JSON の形

```json
{
  "DOCUMENTS": [
    { "_NODE_TYPE": "DOCUMENT", "TITLE": "...", "GRAMMAR": { ... },
      "NODES": [
        { "_NODE_TYPE": "SECTION", "TITLE": "...", "NODES": [ ... ] },
        { "_NODE_TYPE": "REQUIREMENT", "UID": "...", "TITLE": "...",
          "STATEMENT": "...",
          "RELATIONS": [ { "TYPE": "Parent", "VALUE": "...", "ROLE": "..." } ] }
      ] }
  ]
}
```

| 覚えること | 内容 |
|---|---|
| ノードは**入れ子** | `SECTION` の中に `NODES` がある。平坦化には `recurse(.NODES[]?)` を使う |
| `_` 付きは**メタ** | `_NODE_TYPE` / `_TOC` / `_OPTIONS` |
| 関係は**親だけ**持つ | 子を出すには**逆に引く**（Q5） |
| `DATE` と `METADATA:` は**入らない** | 文書レベルのメタは `UID` / `VERSION` / `CLASSIFICATION` / `PREFIX` / `ROOT` のみ |

全クエリ共通の平坦化イディオム:

```jq
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE)
```

---

## Q1. 指定の章に属する要求の一覧 — `queries/q1-section-requirements.jq`

**章は `--arg` で渡す。** 同梱ファイルはこの形にしてある（フィルタ本体に章題を埋め込まないので、どの言語のプロジェクトにも使える）。前方一致なので、番号付きの見出しなら `--arg sec "2. "` のように番号だけでも指せる。

```jq
($ARGS.named.sec // "") as $sec
| .DOCUMENTS[] | recurse(.NODES[]?)
| select(._NODE_TYPE=="SECTION" and (.TITLE|startswith($sec)))
| recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| .UID + "  " + .TITLE
```

```powershell
jq -r --arg sec "要求も同じように書ける" -f docs\queries\q1-section-requirements.jq out\json\index.json
```

```text
SW-005  変換結果の要約表示
```

> 同梱ファイルは `--arg` を付けずに走らせると、エラーではなく使い方の 1 行を返す。

## Q2. 指定の ID の要求の全フィールド — `queries/q2-one-requirement.jq`

```jq
first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002"))
| del(.NODES)
```

```json
{
  "_TOC": "2",
  "_NODE_TYPE": "REQUIREMENT",
  "UID": "SW-002",
  "STATUS": "Approved",
  "TITLE": "入力形式の検査",
  "REVIEW_STATUS": "NoFinding",
  "STATEMENT": "もし入力ファイルの形式が利用者の指定した形式と異なるならば、 本ツールは、\n変換を行わず異常終了すること。\n",
  "RELATIONS": [
    {
      "TYPE": "Parent",
      "VALUE": "SYS-002"
    }
  ]
}
```

> **`RELATIONS` は `Parent` も `File` も同じ配列に入る。** 親だけが欲しいなら `select(.TYPE=="Parent")` で絞る（Q4 / Q5 はそうしている）。

> `first(...)` は最初の 1 件で探索を打ち切る。`del(.NODES)` は複合ノードの子を落とすためで、要求ノードには効かないが章にも同じフィルタを使えるようにしてある。

## Q3. 指定のキーワードを含む要求 — `queries/q3-keyword.jq`

**キーワードは `--arg` で渡す。** 同梱ファイルはこの形にしてある（フィルタ本体に検索語を埋め込まないので、どの言語のプロジェクトにも使える）。

```jq
($ARGS.named.kw // "") as $kw
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(((.TITLE//"") + (.STATEMENT//"")) | contains($kw))
| .UID + "  " + .TITLE
```

```powershell
jq -r --arg kw "変換" -f docs\queries\q3-keyword.jq out\json\index.json
```

```text
SYS-001  ファイルの変換
SYS-002  想定外の入力の拒否
SW-001  変換の実行
SW-002  入力形式の検査
SW-005  変換結果の要約表示
```

> 同梱ファイルは `--arg` を付けずに走らせると、エラーではなく使い方の 1 行を返す。

> `RATIONALE` や独自フィールドも見るなら、連結する対象を足す。全フィールドを対象にするなら `[.. | strings] | join(" ")` で潰してもよい。

## Q4. 指定の要求の上位要求（親を辿る) — `queries/q4-parents.jq`

```jq
[ .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID) ] as $all
| def parents($u):
    ($all[] | select(.UID == $u) | .RELATIONS? // [] | .[]
     | select(.TYPE=="Parent") | .VALUE) as $p
    | [$p], parents($p);
  [ parents("SW-002") ] | flatten | unique | .[]
```

```text
SYS-002
```

> **推移的に辿る。** 直接の親だけでよければ `select(.UID=="SW-002") | .RELATIONS[] | select(.TYPE=="Parent") | .VALUE` で足りる。

## Q5. 指定の要求の下位要求（子を辿る) — `queries/q5-children.jq`

```jq
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)
| select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="SYS-001"))
| ._NODE_TYPE + "  " + .UID + "  " + (.TITLE // "")
```

```text
REQUIREMENT  SW-001  変換の実行
REQUIREMENT  SW-005  変換結果の要約表示
```

> **JSON に「子」は書かれていない。全ノードを走査して「親が自分であるもの」を集める。** テストや部品も同じ形で引っかかるので、絞るなら `._NODE_TYPE` で条件を足す。

## 指摘と修正を引く

**StrictDoc に「指摘」の標準概念は無い。** `sd-basic-ja` は指摘を要求そのものの `REVIEW_STATUS` / `REVIEW_COMMENT` に書く形を採っている（[`02-sdoc-authoring.md`](02-sdoc-authoring.md)）。その形なら、未解決の指摘は普通のフィールド条件で引ける。

```jq
.DOCUMENTS[] | recurse(.NODES[]?)
| select(.REVIEW_STATUS == "Open")
| .UID + "  " + .TITLE
```

指摘を要求とは別のノードとして積み、1 件ずつ追跡したいなら、カスタム文法で専用のノード型を作る形もある。**その形にすると、上のような素のフィールド条件では引けなくなる。** どちらを採るかの比較は `samples/sd-basic-ja/04-review.sdoc` にある。

> **版と版の差分そのものを見たいなら、クエリではなく StrictDoc の差分機能がある。** `strictdoc_config.py` の `project_features` に **`DIFF`（experimental）を足したうえで**、`--generate-diff-dirs <old> <new>` または `--generate-diff-git "HEAD^..HEAD"` を付けると `diff.html` と `changelog.html` が生まれる。**`DIFF` を足さないと、オプションを付けても差分ページは作られない**（0.27.1 で確認）。

---

## jq が無い場合 — Node.js

`setup-strictdoc.bat` は既定で jq を入れるが、無い環境では Node で同じことができる。

```javascript
// nodes.mjs
import { readFileSync } from "node:fs";

const doc = JSON.parse(readFileSync(process.argv[2], "utf8"));

const nodes = [];
const walk = (n) => {
  if (n._NODE_TYPE) nodes.push(n);
  for (const c of n.NODES ?? []) walk(c);
};
for (const d of doc.DOCUMENTS) walk(d);

// Q5 equivalent.
for (const n of nodes.filter((n) =>
  (n.RELATIONS ?? []).some((r) => r.TYPE === "Parent" && r.VALUE === "SYS-001")
)) {
  console.log(`${n._NODE_TYPE}  ${n.UID}  ${n.TITLE ?? ""}`);
}
```

```bash
node nodes.mjs out/json/index.json
```

```text
REQUIREMENT  SW-001  変換の実行
REQUIREMENT  SW-005  変換結果の要約表示
```

---

## なぜ JSON を使うのか — 実測

**JSON は元の `.sdoc` より小さくならない。** `samples/sd-basic-ja/`（要求 8 件・7 文書）で測った値:

| 成果物 | `.sdoc` 比（バイト） | `.sdoc` 比（トークン） |
|---|---:|---:|
| `.sdoc` ソース 6 本 | 1.00 | 1.00 |
| JSON（`export` が出すそのまま） | **約 3 倍** | **約 3.5 倍** |
| JSON（`jq -c .` を一度通したもの） | **約 1.3 倍** | **約 1.4 倍** |

`strictdoc` は `json.dumps(..., indent=4)` で書き出す（`json_generator.py:67`）。`ensure_ascii=False` を渡していないので Python の既定が効き、**非 ASCII が `\uXXXX` に展開される。日本語 1 文字が UTF-8 の 3 バイトから 6 バイトになる。** 加えて 4 スペースで整形される。

## 一手で戻せる — `jq -c .`

**`jq` は既定で `\uXXXX` を本来の文字に戻して出力する。** 整形も外れる。

```bash
jq -c . out/json/index.json > out/json/index.min.json
```

**これだけで約 3.5 倍が約 1.4 倍になる**（上表）。中身は同じ JSON で、クエリの結果も変わらない。**JSON をそのまま人や機械に渡す場面があるなら、export の直後に一度通しておく。**

> ただし本書の使い方——`jq` でクエリを当てて答えだけを取り出す——では、通しても通さなくても結果は同じである。`jq` はどちらの表記も同じに読む。**効くのは「JSON 全体を渡す」場合だけ。**

**利点は小ささではなく、答えだけを取り出せることである。** 同じ `sd-basic-ja` に対して、本書のクエリを当てたときの出力量:

| クエリ | 引数 | `.sdoc` 全文に対する比 |
|---|---|---:|
| Q1 章内の要求一覧 | `--arg sec "要求も同じように書ける"` | 0.09 % |
| Q2 指定 ID の全フィールド | `SW-002` | 0.95 % |
| Q3 キーワード検索 | `--arg kw "変換"` | 0.43 % |
| Q4 上位要求（推移的） | `SW-002` | 0.03 % |
| Q5 下位要求 | `SYS-001` | 0.23 % |

> **引数を表に載せたのは、値を再現できるようにするためである。** Q2 / Q4 / Q5 は同梱ファイルがこの UID を埋め込んであるので、そのまま走らせればこの表の値が出る。
>
> 比はトークン数で測った。トークン数は tiktoken `o200k_base` による。**これは OpenAI のトークナイザであり、他のモデルのものではない。** 同じ内容の別表現どうしを比べる相対値としてのみ用いること。上の 2 表は strictdoc 0.27.1 / jq 1.8.1 で測り直した。**絶対値ではなく比で載せているのは、行末が CRLF か LF かでバイト数が動き、読者の手元で再現できないためである。**

**`--included-documents` は付けてはいけない。** `DOCUMENT_FROM_FILE` で取り込んだ文書が独立した文書としても JSON に重複して入る（`sd-basic-ja` の実測で **約 3 % 増える**）。取り込む文書が UID を持つ場合は、その UID が 2 か所に現れる。
