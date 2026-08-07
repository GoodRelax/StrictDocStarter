# jq クエリ集 — AI 向け

**本書は、`00-ai-guide.md` の「3. 仕様書から必要な部分だけを取り出す」の詳細版である。**
主要なクエリは `00-ai-guide.md` に載せてある。**そちらで足りるなら本書は読まなくてよい。**

以下はすべて `samples/md-basic-ja` を `strictdoc export --formats=json` した結果に対して
実行し、出力を確認したものである。`<json>` は `<出力先>/json/index.json` を指す。

このサンプルの中身: 上位要求 `SYS-001..003` / 下位要求 `SW-001..004` /
テストケース `TC-001..004` / レビュー指摘 `RV-001..002`。
図・数式・コードは `DOC-LOWER` の末尾の章と、`_assets/fig-state.md` (`DOC-FIG-STATE`) にある。

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
DOC-FIG-STATE  大きい図 - 変換処理の状態遷移
DOC-NOTE  用語の対応表
```

**7 件出る。** `DOC-GUIDE` は人間向けの解説書、`DOC-NOTE` は `_assets/note.md` の用語表、
`DOC-FIG-STATE` は `_assets/fig-state.md` の大きい図で、いずれも要求を持たない。
`.md` は置き場所に関係なく文書として解析されるためである。

### A2. ノード型ごとの件数

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | ._NODE_TYPE] | group_by(.) | map({(.[0]): length}) | add' <json>
```

```json
{"DOCUMENT":7,"FINDING":2,"REQUIREMENT":7,"SECTION":18,"TEST_CASE":4,"TEXT":23}
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

---

## G. 図・数式・コードを扱う

**図も数式もコードも、`STATEMENT` に原文のまま入っている。** だから `jq` で取り出せるし、
中身を数えることもできる。この節のクエリはそれを前提にしている。

**この節のクエリには 2 つの決まりがある。**

- **正規表現に二重バックスラッシュを使わない。** `\\$` や `\\[` の代わりに `[$]` `[[]` の
  文字クラスを使い、正規表現で足りるところも `contains()` / `split()` で書いてある。
  理由は G0 に書く
- **コードフェンスを 4 個のバッククォートで囲んである。** クエリ本文に ` ``` ` が出るため、
  3 個だと囲みが途中で閉じる。4 個は StrictDoc でも正しく解釈される (実測)

### G0. なぜ二重バックスラッシュを避けるか

**Git Bash に `bash -c "..."` の形でクエリを渡すと、二重バックスラッシュが半分に減る。**
strictdoc 0.27.1 / jq 1.8.1 / Windows 11 で実測した。

| 渡し方 | `scan("!\\[...")` の結果 |
|---|---|
| `jq -f クエリ.jq` | 通る |
| シェルスクリプトに書いて `bash script.sh` | 通る |
| **`bash -c 'jq -r ...'`** | **`Invalid escape` で落ちる** |

AI がコマンドを実行するときはたいてい `bash -c` の形になる。**だから二重バックスラッシュを
含むクエリは書かない。** 同じ結果は文字列操作で書ける。

**単独のバックスラッシュは無事である。** `split("\n")` は上のどの渡し方でも通る (実測)。
減るのは二重のときだけなので、`\n` `\t` は普通に使ってよい。

**どうしても複雑になるならファイルに書く。** シェルを通らないので何も壊れない。

```bash
jq -r -f <クエリを書いたファイル>.jq <json>
```

### G27. どこに何があるか

**最初に打つのはこれである。** どの文書のどのノードに図・数式・コード・表・画像が
あるかを一覧にする。

````bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | select(.STATEMENT?) as $n | $n.STATEMENT as $s
| [$s | split("```") | to_entries[] | select(.key % 2 == 1) | .value | split("\n")[0]] as $lang
| [ (if ($lang | index("mermaid")) then "図" else empty end),
    (if ($s | contains("$$")) then "数式" else empty end),
    (if ($lang | map(select(. != "mermaid" and . != "")) | length) > 0 then "コード" else empty end),
    (if ($s | test("(?m)^[|]")) then "表" else empty end),
    (if ($s | contains("![")) then "画像" else empty end) ] as $k
| select(($k | length) > 0) | $doc + "  " + ($n.UID // $n._TOC // "-") + "  " + ($k | join(","))' <json>
````

```text
DOC-GUIDE  3.2.1  図,画像
DOC-GUIDE  5.1  数式,表
DOC-GUIDE  5.2.1  数式,コード,表
DOC-LOWER  6.1  図,数式,コード
DOC-TESTS  1  コード
DOC-FIG-STATE  1  図
DOC-NOTE  1  表
```

(全 19 行のうち代表を抜いた。`DOC-GUIDE` の行が多いのは、あれが記法の解説書だからである)

2 列目は `UID` があればそれ、無ければ `_TOC` の階層番号である。**地の文には UID が
無い**ので、位置を指すには `_TOC` を使う。

**★ 言語名はフェンス 1 個ずつ見ること。** ` ``` ` で切ると奇数番目が必ずフェンスの
中身になるので、その 1 行目が言語名である。**ノード全体に対して
「`mermaid` を含むか」で判定してはならない。** 図とコードが同じノードに同居すると
コードを取りこぼす。`DOC-LOWER 6.1` がまさにその形 (図・数式・コードが同居) なので、
自分でこの種のクエリを書いたら**必ずこの行で試すこと。**

### G28. 図の定義を取り出す

````bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-FIG-STATE") | recurse(.NODES[]?) | (.STATEMENT? // "")
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid")) | ltrimstr("mermaid")' <json>
````

```text
stateDiagram-v2
    [*] --> 待機
    待機 --> 引数解釈 : 変換を実行
    (以下 16 行)
```

`split("```")` でフェンスを境に切り、`mermaid` で始まる断片だけを拾い、
先頭の `mermaid` の 5 文字を落としている。**フェンスの中身はそのまま入っている**ので、
これで Mermaid の定義がそっくり手に入る。

言語を変えれば同じ形でコードも取れる (G31)。

### G29. 図の大きさを測る (「15 行を超えたら外に出す」の監査)

**このプロジェクトの規則は「Mermaid フェンスの中身が 16 行以上なら
`_assets/fig-*.md` に独立した文書として出す」である。** 守れているかを機械で確かめる。

まず全部の図を測る:

````bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid"))
| ltrimstr("mermaid") | split("\n") | map(select(. != "")) | length as $c
| $doc + "  " + ($c | tostring) + " 行  " + (if $c > 15 then "外に出す" else "本文でよい" end)' <json>
````

```text
DOC-GUIDE  8 行  本文でよい
DOC-LOWER  8 行  本文でよい
DOC-FIG-STATE  19 行  外に出す
```

違反だけを出す形。**`DOC-FIG-` で始まる文書は既に外に出したものなので除く。
0 行が正常である。**

````bash
jq -r '.DOCUMENTS[] | select(.UID | startswith("DOC-FIG-") | not) | .UID as $doc
| recurse(.NODES[]?) | select(.STATEMENT?) as $n | $n.STATEMENT
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid"))
| ltrimstr("mermaid") | split("\n") | map(select(. != "")) | length as $c
| select($c > 15) | $doc + "  " + ($n.UID // $n._TOC // "-") + "  " + ($c | tostring) + " 行"' <json>
````

このサンプルでは 0 件。

### G30. 数式を取り出す

```bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-LOWER") | recurse(.NODES[]?) | (.STATEMENT? // "")
| [scan("[$][$]([^$]+)[$][$]")] | .[][] | gsub("^\n|\n$"; "")' <json>
```

```text
S_{need} = S_{out} + S_{tmp} = 2 \times S_{out}
```

`[$][$]` は `$$` を表す文字クラスである (G0)。`scan()` は取り出し組ごとに配列を返すので
`.[][]` で潰す。

**文書を絞ること。** 絞らずに全体へ当てると `02-guide-for-human.md` の記法の解説に
書いてある `$$` の説明文まで拾い、何が本物の数式か分からなくなる。

**インラインの `$...$` を機械的に取り出すのは諦めたほうがよい。** 地の文に紛れた
`$` (金額や環境変数) と区別が付かず、誤爆する。インラインの数式が要るときは
G27 で場所を突き止めてから、そのノードの `STATEMENT` を丸ごと読む。

### G31. コードを言語別に

何の言語が何個あるか:

````bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | (.STATEMENT? // "") | scan("(?m)^```([a-z]+)")]
| flatten | group_by(.) | map({(.[0]): length}) | add' <json>
````

```json
{"bash":5,"json":1,"mermaid":3,"python":3,"text":14}
```

**`mermaid` もここに出る。** 図もコードフェンスだからである。

中身を取り出す (G28 と同じ形):

````bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-LOWER") | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("```")[] | select(startswith("python")) | ltrimstr("python")' <json>
````

```text
def convert(src: str, dst: str) -> None:
    tmp = dst + ".part"          # dst と同じディレクトリに作る
    (以下 6 行)
```

**言語名が書かれていないフェンスは、この形では拾えない。** だから書くときは必ず
言語名を付ける。

### G32. 画像の参照先

```bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("![") | .[1:][] | select(contains("](")) | split("](")[1] | split(")")[0]
| $doc + "  " + .' <json>
```

```text
DOC-GUIDE  path
DOC-GUIDE  _assets/flow.svg
```

`path` は解説書に書いてある `![alt](path)` という書式の説明そのものである。**実在する
画像ではない。** 記法を説明している文書を含む一式では、こういう見かけの当たりが混ざる。

バックスラッシュを使わずに `![...](...)` を切り出すため、`split()` を 3 回重ねている。

### G33. `$` の罠を含む行を探す

**`$` が段落や表のセルの最後の 1 文字になっていると、HTML の export が
`error: string index out of range` だけを出して止まる。** ファイル名も行番号も出ない。

**ところが JSON の export は成功する** (実測)。だから **JSON を出してからこのクエリを
当てれば、HTML を作る前に場所が分かる。**

````bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("```") | to_entries | map(select(.key % 2 == 0) | .value) | .[]
| split("\n")[] | select(test("[^$][$] *$") or test("[^$][$] *[|]"))
| $doc + "  " + .' <json>
````

このサンプルでは 0 件。**0 件が正常である。** わざと壊した文書に当てると、こう出る:

```text
DOC-LINT  CRASH  paragraph ending in math $T$
DOC-LINT  CRASH  bare trailing dollar 100 $
DOC-LINT  SAFE   escaped trailing dollar 100 \$
DOC-LINT  | CRASH cell ending in math | $T$ |
```

`split("```") | to_entries | map(select(.key % 2 == 0))` は**コードフェンスの中身を
捨てる定型である。** フェンスで切ると奇数番目が必ずフェンスの中身になる。
`$` はフェンスの中では無害なので、除かないと誤検出だらけになる。

**誤検出は 1 種類だけある** — `\$` と書いて逃がしてある行も出る (上の 3 行目)。
逃がしてあるなら安全なので、見て飛ばす。

### G34. 図を書き換えて `.md` に戻す

**JSON から `.md` へ機械的に書き戻すことはできない。** JSON にファイルパスが
入っていないためである (本書冒頭の注意)。手順は次のとおり。

**1. 図を取り出す** — G28。

**2. どのファイルにあるかを突き止める。** UID の宣言を固定文字列で探す。
`-F` を付けるのは `**` を正規表現と解釈させないためである。

```bash
grep -rlF '**UID**: DOC-FIG-STATE' <仕様書のフォルダ> --include=*.md
```

```text
samples/md-basic-ja/_assets/fig-state.md
```

**UID を書いてあるだけのファイルは出ない。** 上のクエリは `**UID**:` の宣言に
一致するので、`[LINK: DOC-FIG-STATE]` で参照しているだけの `04-lower.md` は外れる。

**3. その `.md` を直接編集する。** フェンスの中身を差し替える。

**4. 行数を測り直す。** 16 行以上になったなら、本文にあった図は
`_assets/fig-*.md` へ移し、元の場所には `[LINK:]` を残す (G29)。

**5. 再度 export する。** JSON は自動では更新されない。

```bash
strictdoc export <仕様書のフォルダ> --formats=json --output-dir <出力先>
```

**6. HTML も通ることを確かめる。** `--formats=json` は `$` の罠を素通しする。
図や数式を触ったときは `--formats=html` も必ず通す。

```bash
strictdoc export <仕様書のフォルダ> --formats=html --output-dir <出力先>
```
