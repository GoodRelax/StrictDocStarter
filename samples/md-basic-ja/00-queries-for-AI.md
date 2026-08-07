# jq クエリ集 — AI 向け

**本書は、`00-guide-for-AI.md` の「2. 仕様書から必要な部分だけを取り出す」の詳細版である。**
主要なクエリは `00-guide-for-AI.md` に載せてある。**そちらで足りるなら本書は読まなくてよい。**

以下はすべて `samples/md-basic-ja` を `strictdoc export --formats=json` した結果に対して
実行し、出力を確認したものである。`<json>` は `<出力先>/json/index.json` を指す。

このサンプルの中身: 上位要求 `SYS-001..003` / 下位要求 `SW-001..004` /
テストケース `TC-001..004` / レビュー指摘 `RV-001..002`。

---

## A. 全体を掴む

### A1. 文書の一覧

```bash
jq -r '.DOCUMENTS[] | (.UID // "-") + "  " + .TITLE' <json>
```

```text
DOC-GUIDE  基本 - まずこれを読む
DOC-UPPER  基本 - 上位要求
DOC-LOWER  基本 - 下位要求
DOC-TESTS  基本 - テストケース
DOC-REVIEW  基本 - レビュー指摘
DOC-NOTE  用語の対応表
```

**6 件出る。** `DOC-GUIDE` は人間向けの解説書、`DOC-NOTE` は `_assets/note.md` の用語表で、
どちらも要求を持たない。`.md` は置き場所に関係なく文書として解析されるためである。

### A2. ノード型ごとの件数

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | ._NODE_TYPE] | group_by(.) | map({(.[0]): length}) | add' <json>
```

```json
{"DOCUMENT":6,"FINDING":2,"REQUIREMENT":7,"SECTION":13,"TEST_CASE":4,"TEXT":17}
```

### A3. 目次

`_TOC` は `2.1.1` のような階層番号である。

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="SECTION") | ._TOC + "  " + .TITLE' <json>
```

### A4. 型ごとに使えるフィールド名

**既存プロジェクトのスキーマを JSON から知る。** 新規に書き起こすときは JSON がまだ無いので、
このクエリは使えない。そのときは `basic.sgra` を直接読む。

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE) | {t:._NODE_TYPE, k:keys}] | group_by(.t) | map({(.[0].t): (map(.k)|add|unique)}) | add' <json>
```

```json
{"REQUIREMENT":["RATIONALE","RELATIONS","STATEMENT","STATUS","TITLE","UID","_NODE_TYPE","_TOC"],
 "TEST_CASE":["EXPECTED","RELATIONS","STATEMENT","TITLE","UID","_NODE_TYPE","_TOC"],
 "FINDING":["RELATIONS","RESOLUTION","SEVERITY","STATEMENT","TITLE","UID","_NODE_TYPE","_TOC"]}
```

---

## B. 位置を特定する

### B5. UID で 1 件

```bash
jq -c 'first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002")) | del(.NODES)' <json>
```

`first(...)` は最初の 1 件で探索を打ち切る。`del(.NODES)` は章にも同じ式を使えるようにするため。

### B6. UID を正規表現で

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? and (.UID | test("^SW-"))) | .UID' <json>
```

```text
SW-001
SW-002
SW-003
SW-004
```

### B7. 語で探す

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(((.TITLE//"") + (.STATEMENT//"")) | contains("変換")) | .UID' <json>
```

全フィールドを対象にするなら `[.. | strings] | join(" ")` で潰してから `contains` する。

### B8. 正規表現で探す

**`test()` は第 2 引数にフラグを取る。`"i"` で大文字小文字を無視する。日本語も使える。**

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.TITLE? and (.TITLE | test("変換|検査"; "i"))) | (.UID // "-") + "  " + .TITLE' <json>
```

```text
SYS-001  ファイルの変換
SW-001  変換の実行
SW-002  入力形式の検査
TC-001  変換が成功する
RV-001  SW-002 の検査方法が決まっていない
```

### B9. 特定の文書だけに絞る

**ファイル名では絞れない。JSON にファイルパスは入っていない。** 文書の `UID` を使う。

```bash
jq -r '.DOCUMENTS[] | select(.UID=="DOC-UPPER") | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | .UID + "  " + .TITLE' <json>
```

文書の UID が分からないときは A1 で調べる。

### B10. 特定の章だけに絞る

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._TOC? and (._TOC | startswith("2."))) | ._TOC + "  " + (.TITLE // "")' <json>
```

`startswith("2.")` は `2.1` `2.2` に一致するが、章そのもの (`2`) には一致しない。
章自身も含めるなら `(._TOC=="2" or (._TOC|startswith("2.")))` とする。

---

## C. 関係をたどる

### C11. 直接の親

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?=="TC-001") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE' <json>
```

### C12. 親を根までたどる (推移的)

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)] as $all
| def anc($u): ($all[] | select(.UID==$u) | .RELATIONS? // [] | .[] | select(.TYPE=="Parent") | .VALUE) as $p | [$p], anc($p);
  [anc("TC-001")] | flatten | unique | .[]' <json>
```

```text
SW-001
SYS-001
```

### C13. 直接の子 (逆引き)

**JSON に子は記録されていない。** 全ノードを走査して「親が自分であるもの」を集める。

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="SYS-001")) | .UID' <json>
```

### C14. 子を葉までたどる (推移的)

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)] as $all
| def desc($u): ($all[] | select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE==$u)) | .UID) as $c | [$c], desc($c);
  [desc("SYS-001")] | flatten | unique | .[]' <json>
```

```text
SW-001
TC-001
```

### C15. ROLE で絞る

`Verifies` はテスト、`Reviews` はレビュー指摘が使う。

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) as $n | ($n.RELATIONS // [])[] | select(.ROLE=="Verifies") | $n.UID + " -> " + .VALUE' <json>
```

```text
TC-001 -> SW-001
TC-002 -> SW-002
TC-003 -> SW-003
TC-004 -> SW-004
```

---

## D. 抜けを見つける

### D16. テストケースから「直接」指されていない要求

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $tested
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($tested[]) | not) | .UID + "  " + .TITLE' <json>
```

```text
SYS-001  ファイルの変換
SYS-002  想定外の入力の拒否
SYS-003  既存ファイルの保護
```

この一式ではテストが下位要求 `SW-*` を覆っており、上位要求 `SYS-*` は直接には覆われていない。
**これは欠陥ではなく設計である** — 上位は下位を通じて覆われる。

### D17. 親を持たない要求

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(((.RELATIONS // []) | map(select(.TYPE=="Parent")) | length) == 0) | .UID' <json>
```

### D18. 誰からも指されていない要求

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $parents
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($parents[]) | not) | .UID' <json>
```

このサンプルでは 0 件 (全要求が誰かに指されている)。

### D19. 存在しない UID を指している関係 (リンク切れ)

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) | .UID] as $ids
| .DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) as $n
| ($n.RELATIONS // [])[] | select(.VALUE | IN($ids[]) | not) | $n.UID + " -> " + .VALUE' <json>
```

このサンプルでは 0 件。**0 件が正常**である。

### D20. UID の重複

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) | .UID] | group_by(.) | map(select(length>1) | .[0])' <json>
```

`[]` が正常。

---

## E. フィールドで絞る

### E21. STATUS で絞る

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT" and .STATUS=="Draft") | .UID' <json>
```

### E22. and / or / not

`select()` の中で普通の論理演算子が使える。

```bash
# and — 未対処かつ重大な指摘
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="FINDING" and .SEVERITY=="Major" and .RESOLUTION=="Open") | .UID' <json>

# or — テストか指摘
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE" or ._NODE_TYPE=="FINDING") | .UID' <json>

# not — 要求以外で UID を持つもの
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? and (._NODE_TYPE=="REQUIREMENT" | not)) | ._NODE_TYPE + " " + .UID' <json>
```

`not` は**後ろに置く**。`select(not(...))` とは書けない。

### E23. フィールドが無いものを探す

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(has("RATIONALE") | not) | .UID' <json>
```

**値が空でも `has()` は真になる。** 空文字を除きたいなら `select((.RATIONALE // "") == "")` とする。

---

## F. 形を整えて出す

### F24. 表形式 (最も安い一覧)

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | [.UID, .STATUS, .TITLE] | @tsv' <json>
```

```text
SYS-001	Approved	ファイルの変換
SW-004	Draft	書き込みの原子性
```

### F25. 件数だけ

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")] | length' <json>
```

### F26. 必要な欄だけを JSON で

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="FINDING")] | map({UID, SEVERITY, RESOLUTION})' <json>
```

**`-r` を付けない。** 付けると文字列に潰れる。
