# Claude と組んで書く

**Grammar**: basic.sgra \
**UID**: DOC-COWORK \
**Version**: 1.0

**本書は、 この一式に同梱した `strictdoc-md` スキルを使って、 Claude Code に
仕様書を書かせ、 調べさせ、 レビューさせる方法を伝える。**

**スキルとは、 AI に渡す手引きをフォルダにまとめたものである。** Claude Code は
起動時に説明文だけを読み、 **仕事の中身が合致したときに本体を読み込む。**
だから毎回「StrictDoc の書き方はこうで」と説明し直さなくてよい。

このスキルの中身は `00-ai-guide.md` と `01-ai-queries.md` を英訳して規則と実例に
分けたものである。 **人が読むなら日本語のその 2 つを、 AI に渡すならスキルを使う。**

## スキルを入れる

**Type**: SECTION

**Claude Code に頼むのがいちばん速い。** 次のように言えば、 複製から置き場所の
選択までやる。

```text
claude-skills/strictdoc-md を私の環境で使えるようにして
```

**自分で入れたい人は付録を見ること。** 置き場所の規則と 1 行のコマンドがある。

入れたかどうかは、 **`/strictdoc-md` と打って名前で呼べるか**で分かる。
呼べるようになれば、 以降は仕事の中身が合致したときに自分から使う。

中身は次のとおりである。

| ファイル | 何が書いてあるか |
| --- | --- |
| `SKILL.md` | 規則・前提・4 つの罠。 Claude Code がいちばん先に読む |
| `references/authoring.md` | `.md` の形、 export を止める規則、 `.sgra` の雛形 |
| `references/notation.md` | 図・数式・コード・表・添付の書き方 |
| `references/traps.md` | 黙って壊れるもの。 癖の記録の運用 |
| `references/queries.md` | jq のクエリ集と、 実際に出た出力 |
| `scripts/audit.sh` | **StrictDoc が報告しない 6 つの検査** |

**前提は `strictdoc` と `jq` の 2 つである。** どちらも `PATH` に無いと
スキルは何もできない。

## AI に読ませる - `.md` を開かせない

**Type**: SECTION

**これがいちばん効く 1 点である。**

仕様書を `.md` のまま読ませると、 この一式だけで 64,000 tokens を超える。
**JSON へ書き出して `jq` で必要な部分だけ引けば、 同じ答えが 100 tokens 弱で出る。**

```text
strictdoc export <仕様書のフォルダ> --formats=json --output-dir <出力先>
```

スキルはこの手順を知っていて、 利用者が聞いた内容に応じたクエリを組む。
利用者の側は**普通に日本語で聞けばよい。**

- 「この仕様書の要求を一覧にして」
- 「テストが 1 つも当たっていない要求はどれ」
- 「`SW-002` の親を根まで辿って」
- 「壊れている関係はあるか」

**`.md` を開くのは、 中身を書き換えるときだけである。** JSON にはファイルの
場所が入っていないので、 JSON から `.md` へ機械的に書き戻すことはできない。

## AI に書かせる

**Type**: SECTION

**新しく起こすときも、 既にある仕様書に足すときも同じである。**
スキルは `.sgra` の雛形まで持っているので、 文法から起こせる。

頼むときに**先に決めて渡すとよいもの**が 3 つある。 決めずに投げると、
AI が勝手に決めて、 後から直す羽目になる。

1. **UID の付け方** — `SYS-` `SW-` `TC-` のような接頭辞と桁数
2. **ファイルの分け方** — 上位・下位・テスト・レビューで分けるのか、 機能で分けるのか
3. **文法** — `TEST_CASE` や独自の項目を使うのか、 既定の範囲で済ませるのか

**既定の文法で通るのはここまでである** (実測)。

| 使えるもの | `.sgra` が要るもの |
| --- | --- |
| `UID` / `Statement` / `Rationale` / `STATUS` | `Role` (`Verifies` などの役割) |
| `**Type**: SECTION` | `TEST_CASE` などの独自の型 |
| 関係の `Parent` | 独自の項目 |

**書かせた後は必ず export を通すこと。** 通らない `.md` は仕様書ではない。

```text
strictdoc export <仕様書のフォルダ> --formats=json --output-dir <出力先>
strictdoc export <仕様書のフォルダ> --formats=html --output-dir <出力先>
```

**JSON が通っても HTML が落ちることがある。** 段落が `$` で終わると HTML だけが
`string index out of range` で止まる。 **だから 2 つとも通すこと。**

export が止まって場所が出ないときは、 **`--no-parallelization` を付け直す。**
プロセスプールが死んで本当のエラーが隠れているだけで、 付け直せば行が出る。
`--debug` より速い。

## AI にレビューさせる

**Type**: SECTION

### StrictDoc 自身が止めるもの

**Type**: SECTION

次の 2 つは export が失敗するので、 わざわざ調べる必要が無い。

- **UID の重複**
- **存在しない UID を指す関係**

どちらも同じ文書の中でも、 文書をまたいでも止まる。

### StrictDoc が報告しないもの

**Type**: SECTION

こちらがスキルの `audit.sh` の担当である。 **6 つを調べる。**

```text
sh claude-skills/strictdoc-md/scripts/audit.sh <仕様書> <出力先> <除外する文書のUID>
```

| 検査 | 何を見つけるか |
| --- | --- |
| `trailing dollar` | 段落やセルが `$` で終わっている。 **HTML の export が止まる** |
| `broken table row` | 表の行が壊れている |
| `attachment not published` | 参照しているファイルが出力に出ていない。 **`_assets/` の外に置いた添付** |
| `oversized inline figure` | 本文に埋めた図が大きすぎる。 AI に渡す量が膨らむ |
| `review comment missing` | **指摘したのに中身が空。** `REVIEW_STATUS` が `Open` / `Fixed` / `WontFix` なのに `REVIEW_COMMENT` が無い |
| `wording candidates` | **EARS の形・語順・受動態・主語の欠落・否定形。** 違反ではなく**候補**であり、 判断は人と AI がする |

**第 3 引数を忘れないこと。** 解説文書は `![alt](path)` のような**書式の説明**を
本文に載せているので、 除外しないと `attachment not published` が誤って発火する。
この一式なら次を渡す。

```text
DOC-AI-GUIDE,DOC-AI-QUERIES,DOC-GUIDE,DOC-REVIEW,DOC-BROWSER,DOC-COWORK
```

### 中身のレビュー

**Type**: SECTION

検査で見つからないものは、 普通に聞けばよい。

- 「テストが当たっていない要求を挙げて」
- 「上位要求 `SYS-002` に対して下位が足りているか」
- 「この要求は検証できる書き方になっているか」

**監査が 0 件でも通ったことにはならない。** わざと壊した複製を作り、
検査が本当に発火するか確かめること。 **この手順で実際に監査スクリプトの
バグが 1 つ見つかった** (UID を持たない文書で例外になり、 それを握り潰していた)。

## 実例 - 5 つの頼み方

**Type**: SECTION

**ここから先は、 実際に頼んだ 5 つの例である。** 例ごとに **AI が裏で何をするか**、
**人が何を決めるか**、 **後で何を確かめるか**の 3 つを書く。 頼み文だけを並べても、
利用者は出てきた答えの正しさを判断できない。

呼び方はどれも同じである。 スキルの名前を頭に置き、 続けて普通の日本語で頼む。

| 例 | AI が裏で使うもの | 人が決めること |
| --- | --- | --- |
| 1. 他の形式から取り込む | 別のスキル + `.sgra` + export の検査 | どこまでを 1 つの要求と見なすか |
| 2. 不適切な要求を挙げる | `audit.sh` の `wording candidates` | 候補のどれが本当の誤りか |
| 3. 上位と下位を挙げる | JSON + `jq` の関係の走査 | 何階層まで辿るか |
| 4. テスト仕様を作る | JSON + `.sgra` の `TEST_CASE` | 「必要な分だけ」が何件か |
| 5. 未レビューを挙げる | JSON + `jq` の `REVIEW_STATUS` | どの状態を「終わり」に数えるか |

以下のクエリに出てくる `<json>` は `<出力先>/json/index.json` を指す。

### 1. 他の形式から取り込む

**Type**: SECTION

```text
/strictdoc-md XXX.pptx に記載の要求仕様書を .md 形式の StrictDoc に取り込め
```

**この 1 件は 1 つのスキルでは終わらない。** `.pptx` を読むのは `strictdoc-md` の
仕事ではない。 **このスキルが扱うのは `.md` の側だけである。** スライドを開いて文字を
取り出す部分は、 Claude Code の読み取り機能か、 `pptx` を扱う別のスキルが担当する。
**利用者は 2 つのスキルを組み合わせる仕事だと分かった上で頼むこと。**

**`strictdoc-md` が受け持つのは 3 つである。**

1. **落とし込む先の形** — `**UID**:` `**STATUS**:` `**Statement**:` の並びと、 節の作り方
2. **`.sgra`** — `TEST_CASE` や `REVIEW_STATUS` のような独自の項目が要るときの文法
3. **取り込んだ後の検査** — export を 2 形式とも通す

**人が決めること。** 前章の 3 つ (UID の付け方・ファイルの分け方・文法) に加えて、
**スライドのどの箱を 1 つの要求と見なすかを人が決める。** 図の中の文字が要求なのか
注記なのかを AI は決められない。 スライド 1 枚が要求 1 件のこともあれば、
箇条書きの 1 行が要求 1 件のこともある。

**後で確かめること。** export が 2 形式とも通ること、 そして**取り込んだ件数が
元の件数と合うこと**である。 件数は次で数える。

```text
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")] | length' <json>
```

### 2. 不適切な要求を挙げさせる

**Type**: SECTION

```text
/strictdoc-md 要求が EARS 構文に準拠していない、 意図せず受動態を使っている、 他動詞なのに目的語が無いなど、 不適切な要求を抽出して修正案を提示しろ
```

**AI が裏でやること。** JSON へ書き出し、 `audit.sh` の `wording candidates` を回す。
この検査は 5 つの型で候補を挙げる。

| 型 | 何を見つけるか |
| --- | --- |
| `ears-shape` | 文が「こと。」で終わっていない |
| `ears-order` | 条件の語 (もし・場合・とき・時・の間) が主語より後ろにある |
| `passive` | される・された・られる が出てくる |
| `no-subject` | 最初の句点までに「は」が出てこない |
| `negative` | ない・ません が出てくる |

**機械が決められるのは「その文字列が有るか」までである。**

- **機械は、 意図した受動態と事故の受動態を区別できない。**
- **機械は、 他動詞なのに目的語が無い要求を見つけられない。** その動詞が目的語を
  取るかどうか (結合価) を、 本文はどこにも書いていない。

だから**機械が候補を絞り、 AI が意図を判断する。** この分担がこの例の要点である。
機械が挙げた候補を AI が 1 件ずつ読み、 直す価値のあるものだけを修正案にする。

```text
sh claude-skills/strictdoc-md/scripts/audit.sh <仕様書> <出力先> <除外する文書のUID>
```

この一式で回すと 6 つの検査のうち 1 つが発火し、 候補が 3 件出る (実測)。

```text
  ok    trailing dollar              0
  ok    broken table row             0
  ok    attachment not published     0
  ok    oversized inline figure      0
  ok    review comment missing       0
  FAIL  wording candidates           3
          DOC-UPPER  SYS-002  negative
          DOC-UPPER  SYS-003  negative
          DOC-LOWER  SW-004  negative

1 check(s) found something
```

**この 3 件はどれも誤りではない。** EARS の「望ましくない振る舞い」の型は
「〜しないこと。」と書くので、 `negative` が出て当たり前である。 **機械はこの型を
知らないから出す。 型を知っているのは人と AI の側である。** 候補を読んで
「3 件とも直さない」と決めるところまでが、 この頼み方の 1 回分である。

**人が決めること。** 候補のどれを直すかである。 `ears-order` の候補は、
「本ツールは、 …場合、 …こと。」のように主語を条件より先に置いた文で出る。
EARS は条件を先に置くので、 合わせるなら「もし…ならば、 本ツールは、 …こと。」へ
直す。 **この一式の要求は後者の並びで書いてあるので、 `ears-order` の候補は
いま 0 件である。** どちらを取るかは、 読み手を決めてからでないと決まらない。

**後で確かめること。** 直した後にもう一度 `audit.sh` を回し、 **減った件数が直した
件数と合うこと**を見る。 そして export を 2 形式とも通す。

### 3. 上位と下位を挙げさせる

**Type**: SECTION

```text
/strictdoc-md SW-004 に紐づく上位要求と下位要求をそれぞれ列挙せよ
```

**AI が裏でやること。** JSON へ書き出し、 `jq` で関係を走査する。 **関係は子から親へ
1 方向にしか書いていない。** だから上位は自分の `RELATIONS` を読めば出るが、
下位は**全要求を走査して自分を指すものを集める**必要がある。 向きが違うので、
1 本のクエリで両方を出す。

```text
jq -r --arg uid SW-004 '
[ .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT" and .UID?) ] as $r
| ( [ $r[] | select(.UID==$uid) | .RELATIONS[]? | select(.TYPE=="Parent" and (.ROLE|not)) | .VALUE ] ) as $up
| ( [ $r[] | select( [.RELATIONS[]? | select(.TYPE=="Parent" and (.ROLE|not)) | .VALUE] | index($uid) ) | .UID ] ) as $down
| ( [ $r[] | select(.UID | IN($up[])) | .UID + "  " + .TITLE ] ) as $upl
| ( [ $r[] | select(.UID | IN($down[])) | .UID + "  " + .TITLE ] ) as $downl
| "upper (" + ($upl|length|tostring) + ")", ($upl[] | "  " + .),
  "lower (" + ($downl|length|tostring) + ")", ($downl[] | "  " + .)' <json>
```

出力はこうなる (実測)。

```text
upper (1)
  SYS-003  既存ファイルの保護
lower (0)
```

同じクエリを `SYS-003` で回すと向きが入れ替わる (実測)。

```text
upper (0)
lower (2)
  SW-003  出力先の確認
  SW-004  書き込みの原子性
```

**テストケースは `Verifies` の役割を持つので、 このクエリは下位に数えない。**
`select(.ROLE|not)` の 1 行がそれを落としている。 テストまで含めたいなら、
その条件を外す。

**人が決めること。** **何階層まで辿るかである。** 上のクエリは直接つながる 1 階層
だけを出す。 根まで辿るクエリはスキルの `references/queries.md` にある。
そして **0 件をどう読むかも人が決める。** `SW-004` の下位が 0 件なのは、
分解し終えたからなのか、 書き忘れたからなのか、 **機械には決められない。**

**後で確かめること。** 件数である。 **存在しない UID を指す関係は export が止めるので、
export が通っている時点で、 出てきた宛先は全部実在する。** 残る危険は、
関係を張り忘れた側にある。

### 4. テスト仕様を作らせる

**Type**: SECTION

```text
/strictdoc-md SW-003 に対するテスト仕様を必要な分だけ項目を分けて作成せよ
```

**AI が裏でやること。** JSON から対象の要求の `STATEMENT` を引いて条件を数え、
`.sgra` が宣言する `TEST_CASE` の形で `.md` へ書き足す。
**この一式のテストケースは Gherkin の 3 項目で書く。**

| 項目 | 何を書くか |
| --- | --- |
| `TITLE` | シナリオの名前 |
| `GIVEN` | 前提 |
| `WHEN` | 操作 |
| `THEN` | 期待する結果 |
| `TEST_RESULT` | 実行の結果 |
| `ISSUE_KEY` | 障害票の番号 |
| `TEST_REMARK` | 補足 |

要求へは `Parent` の関係に `Verifies` の役割を付けて張る。 現物は `07-tests.md` にある。

**型の行を忘れると、 StrictDoc はその節を要求として読む。** 節の先頭に
`**Type**: TEST_CASE` を書くこと。 忘れると `Invalid requirement field: TEST_RESULT` で
止まる。 **メッセージに出た項目名が、 型を失った節を教える。**

**人が決めること。** **「必要な分だけ」が何件かを人が決める。** 1 要求に 1 テストではない。
`SW-003` なら「同名のファイルが有る」と「無い」の 2 通りが最低で、 そこへ書き込み権限や
大文字小文字の扱いを足すかどうかは、 **何を守りたいかで決まる。** AI は要求の文から
条件を数えて候補を出せるが、 **どこで止めるかを決められない。**

**後で確かめること。** export を 2 形式とも通す。 そのうえで**テストが 1 つも当たって
いない要求**を数え直す。

```text
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $tested
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($tested[]) | not) | .UID + "  " + .TITLE' <json>
```

### 5. レビューが終わっていない仕様を挙げさせる

**Type**: SECTION

```text
/strictdoc-md レビューが終わっていない (NotReviewed, Open) の仕様を列挙せよ
```

**AI が裏でやること。** JSON へ書き出し、 `jq` で `REVIEW_STATUS` を絞る。
この一式の `.sgra` は 5 つの値を宣言している。

| 値 | 意味 |
| --- | --- |
| `NotReviewed` | まだ見ていない |
| `NoFinding` | 見て、 指摘が無かった |
| `Open` | 指摘があり、 まだ直していない |
| `Fixed` | 指摘があり、 直した |
| `WontFix` | 指摘があり、 直さないと決めた |

```text
jq -r '.DOCUMENTS[] | (.UID // .TITLE) as $doc
| recurse(.NODES[]?)
| select(.REVIEW_STATUS? and (.REVIEW_STATUS | IN("NotReviewed","Open")))
| [$doc, .UID, .REVIEW_STATUS, .TITLE] | @tsv' <json>
```

出力は 2 行である (実測)。

```text
DOC-UPPER	SYS-003	Open	既存ファイルの保護
DOC-LOWER	SW-003	NotReviewed	出力先の確認
```

**人が決めること。** **「終わっていない」の範囲を人が決める。** `WontFix` は
直さないと決めた終わりであり、 `Fixed` は直した終わりである。 **この 2 つを終わりに
数えるかどうかで、 答えの件数が変わる。** 上のクエリは 2 つとも終わりに数えている。

**後で確かめること。** `audit.sh` の `review comment missing` を見る。
`REVIEW_STATUS` が `Open` / `Fixed` / `WontFix` なのに `REVIEW_COMMENT` が空の節を
挙げる検査である。 **一覧が出ても中身が空なら、 レビューをしたことにならない。**

## 分担 - どこまで任せるか

**Type**: SECTION

| 仕事 | 向き | 理由 |
| --- | --- | --- |
| 一覧・集計・検索 | **AI** | JSON と `jq` で速く安い |
| 抜けの発見 (テスト無し、 壊れた関係) | **AI** | 機械的に決まる |
| 記法の直し (表・図・添付) | **AI** | 規則が明文化してある |
| 版のまたぎ・大量の書き換え | **AI** | 人がやると漏れる |
| **何を作るかを決める** | **人** | 仕様の中身は委ねられない |
| **要求の粒度を決める** | **人** | 正解が文脈でしか決まらない |
| **通ったことの確認** | **人** | AI の「できました」を信じない |

**大きい仕事を複数の AI に分けるときの実測**: ファイル単位で分け、 **同じファイルを
2 体に触らせないこと。** そして**ファイルを跨ぐ約束事は先に凍結して全体へ配ること。**
英訳のとき、 凍結した名前 (文書題名 9 個・ノード題名 13 個) は 14 体を通して 1 件も
食い違わなかったが、 凍結し忘れた山括弧のプレースホルダは **4 通りに割れた。**

## 版が変わったら

**Type**: SECTION

スキルの中身は **strictdoc 0.27.1 / jq 1.8.1 / Windows 11 の Git Bash** で
測ったものである。 **`SKILL.md` の 6 章にカナリアが入っている** — 版が違うときに
何を測り直すべきかが書いてある。

**本書に載っていないエラーに当たったら、 その場で原因を追ってはならない。**
`strictdoc-quirks.tsv` に 1 行だけ書き足して先へ進むこと。 版が上がったときや
行が溜まったときに読み返し、 手引きを直す材料にする。 **いま 16 行ある。**

ブラウザからの操作は `09-browser-guide.md` にある。

## 付録 - 手で入れる

**Type**: SECTION

スキルは `claude-skills/strictdoc-md/` にある。 使いたい場所へフォルダごと複製する。

```text
cp -r claude-skills/strictdoc-md ~/.claude/skills/
```

**置き場所は 2 つある。**

| 置き場所 | 効く範囲 |
| --- | --- |
| `~/.claude/skills/` | その利用者のすべてのプロジェクト |
| `<プロジェクト>/.claude/skills/` | そのプロジェクトだけ |

**次にセッションを始めると Claude Code が拾う。** 開いている最中に置いても、
そのセッションでは見えない。

**`claude-skills/` は公開用の写しであり、 Claude Code が読むのは `.claude/skills/`
である。** 両方を手で同期しているので、 **片方だけ直すと必ずずれる。**
