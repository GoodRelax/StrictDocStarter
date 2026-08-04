# 03 JSON クエリ集

**目的: 仕様書の全文を読み直さずに、必要な答えだけを取り出す。**

以下はすべて [`samples/sdoc-patterns/`](../samples/sdoc-patterns/) に対して **strictdoc 0.27.1 / jq 1.8.1** で実行した結果である。出力は実物をそのまま貼ってある。書き方は [`02-sdoc-authoring.md`](02-sdoc-authoring.md)。

---

## 0. 準備

```bash
strictdoc export --formats=json --output-dir out samples/sdoc-patterns
```

`out/json/index.json` が生まれる。**要求を追加・修正したら毎回これを走らせ直す。**

### Windows での注意 — フィルタはファイルに書く

**PowerShell はクォートの中の `"` を落とすため、`jq '...' file` の形はそのままでは動かない。**

```text
jq: error: syntax error, unexpected ',' ...
    select(._NODE_TYPE==FINDING) | join(,)      <- " が消えている
```

**フィルタを `.jq` ファイルに保存して `-f` で渡せば、PowerShell でも Git Bash でも同じに動く。**

**本書の 7 本は [`samples/sdoc-patterns/queries/`](../samples/sdoc-patterns/queries/) にそのまま同梱してある。** 書き写す必要はない。

```powershell
jq -r -f samples\sdoc-patterns\queries\q6-findings.jq out\json\index.json
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

```jq
.DOCUMENTS[] | recurse(.NODES[]?)
| select(._NODE_TYPE=="SECTION" and (.TITLE|startswith("2. ")))
| recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| .UID + "  " + .TITLE
```

```text
PAT-002  入力形式の検査
PAT-003  出力先の上書き禁止
```

> 章の指定は `--arg` で外に出せる。`jq -r --arg sec "2. " -f queries/q1-section-requirements.jq ...` とし、フィルタ側は `startswith($sec)` にする。

## Q2. 指定の ID の要求の全フィールド — `queries/q2-one-requirement.jq`

```jq
first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "PAT-003"))
| del(.NODES)
```

```json
{
  "_TOC": "2.2",
  "_NODE_TYPE": "REQUIREMENT",
  "UID": "PAT-003",
  "STATUS": "Revised",
  "TITLE": "出力先の上書き禁止",
  "STATEMENT": "本ツールは、 出力先に既存のファイルがある場合、 上書きせずに終了すること。\n",
  "RATIONALE": "既存ファイルを無警告で潰すと、 利用者は取り返しのつかない操作を\n気づかずに起こせる。 既定は安全側に倒す。 明示的な上書き指定を設けるかは未決。\n",
  "REVISION": "v1.0: レビュー指摘 FND-001 を受け、 「上書きしてもよい」から\n「上書きせずに終了する」へ変更した。\n",
  "RELATIONS": [
    {
      "TYPE": "Parent",
      "VALUE": "PAT-001"
    }
  ]
}
```

> **`RELATIONS` は `Parent` も `File` も同じ配列に入る。** 親だけが欲しいなら `select(.TYPE=="Parent")` で絞る（Q4 / Q5 はそうしている）。PAT-001 は `File` 関係を持つので、そちらで確かめられる。

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
jq -r --arg kw "上書き" -f samples\sdoc-patterns\queries\q3-keyword.jq out\json\index.json
```

```text
PAT-003  出力先の上書き禁止
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
  [ parents("PAT-003") ] | flatten | unique | .[]
```

```text
PAT-001
```

> **推移的に辿る。** 直接の親だけでよければ `select(.UID=="PAT-003") | .RELATIONS[] | select(.TYPE=="Parent") | .VALUE` で足りる。

## Q5. 指定の要求の下位要求（子を辿る) — `queries/q5-children.jq`

```jq
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)
| select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="PAT-001"))
| ._NODE_TYPE + "  " + .UID + "  " + (.TITLE // "")
```

```text
REQUIREMENT  PAT-002  入力形式の検査
REQUIREMENT  PAT-003  出力先の上書き禁止
```

> **JSON に「子」は書かれていない。全ノードを走査して「親が自分であるもの」を集める。** テストや部品も同じ形で引っかかるので、絞るなら `._NODE_TYPE` で条件を足す。

## Q6. 指摘箇所 — `queries/q6-findings.jq`

**StrictDoc に「指摘」の標準概念は無い。** カスタム文法で `FINDING` ノード型を作ってある場合のクエリである（[`02-sdoc-authoring.md` §4](02-sdoc-authoring.md)）。**素の文法のままでは結果は必ず 0 件になる。**

```jq
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="FINDING")
| .UID + " [" + .SEVERITY + "/" + .RESOLUTION + "] -> "
+ ((.RELATIONS // []) | map(select(.ROLE=="Reviews") | .VALUE) | join(","))
+ "  " + .TITLE
```

```text
FND-001 [Major/Fixed] -> PAT-003  PAT-003 が上書き可否を決めていなかった
FND-002 [Question/Open] -> PAT-002  PAT-002 の検査対象が書かれていない
```

未解決だけ見るなら `select(.RESOLUTION=="Open")` を足す。

## Q7. 修正箇所 — `queries/q7-revised.jq`

**これも標準概念ではない。** 要求に `REVISION` フィールドと `STATUS: Revised` を持たせてある前提である。

```jq
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.REVISION != null or .STATUS == "Revised")
| .UID + " (" + (.STATUS // "-") + ")  " + .TITLE
```

```text
PAT-003 (Revised)  出力先の上書き禁止
```

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

// Q6 equivalent.
for (const n of nodes.filter((n) => n._NODE_TYPE === "FINDING")) {
  const target = (n.RELATIONS ?? [])
    .filter((r) => r.ROLE === "Reviews")
    .map((r) => r.VALUE)
    .join(",");
  console.log(`${n.UID} [${n.SEVERITY}/${n.RESOLUTION}] -> ${target}  ${n.TITLE}`);
}
```

```bash
node nodes.mjs out/json/index.json
```

```text
FND-001 [Major/Fixed] -> PAT-003  PAT-003 が上書き可否を決めていなかった
FND-002 [Question/Open] -> PAT-002  PAT-002 の検査対象が書かれていない
```

---

## なぜ JSON を使うのか — 実測

**JSON は元の `.sdoc` より小さくならない。** `samples/sovd-automotive-ja/`（要求 122 件・13 文書）で測った値:

| 成果物 | バイト | トークン | `.sdoc` 比（トークン） |
|---|---:|---:|---:|
| `.sdoc` ソース 13 本 | 178,614 | 56,815 | 1.00 |
| JSON（`export` が出すそのまま） | 576,432 | 158,534 | **2.79** |
| JSON（`jq -c .` を一度通したもの） | 226,496 | 68,696 | **1.21** |

`strictdoc` は `json.dumps(..., indent=4)` で書き出す（`json_generator.py:67`）。`ensure_ascii=False` を渡していないので Python の既定が効き、**非 ASCII が `\uXXXX` に展開される。日本語 1 文字が UTF-8 の 3 バイトから 6 バイトになる。** 加えて 4 スペースで整形される。

## 一手で戻せる — `jq -c .`

**`jq` は既定で `\uXXXX` を本来の文字に戻して出力する。** 整形も外れる。

```bash
jq -c . out/json/index.json > out/json/index.min.json
```

**これだけで 2.79 倍が 1.21 倍になる**（上表）。中身は同じ JSON で、クエリの結果も変わらない。**JSON をそのまま人や機械に渡す場面があるなら、export の直後に一度通しておく。**

> ただし本書の使い方——`jq` でクエリを当てて答えだけを取り出す——では、通しても通さなくても結果は同じである。`jq` はどちらの表記も同じに読む。**効くのは「JSON 全体を渡す」場合だけ。**

**利点は小ささではなく、答えだけを取り出せることである。** 同じ `sovd-automotive-ja` に対して、本書のクエリを当てたときの出力量:

| クエリ | 出力トークン | `.sdoc` 全文 56,815 に対する比 |
|---|---:|---:|
| Q1 章内の要求一覧 | 124 | 0.22 % |
| Q2 指定 ID の全フィールド | 186 | 0.33 % |
| Q3 キーワード検索 | 208 | 0.37 % |
| Q4 上位要求（推移的） | 36 | 0.06 % |
| Q5 下位要求 | 73 | 0.13 % |

> トークン数は tiktoken `o200k_base` による。**これは OpenAI のトークナイザであり、他のモデルのものではない。** 同じ内容の別表現どうしを比べる相対値としてのみ用いること。バイト数は実測値である。上表 3 行は strictdoc 0.27.1 で測り直した。

**`--included-documents` は付けてはいけない。** `DOCUMENT_FROM_FILE` で取り込んだ文書が独立した文書としても重複し、同じ UID が 2 か所に現れる（実測で JSON は 5,174 → 9,624 バイト）。
