# レビューの進め方

**Grammar**: basic.sgra \
**UID**: DOC-REVIEW \
**Version**: 1.0

**本書は、 レビューの結果をどこにどう書くかを伝える。**

**この一式は、 指摘を要求そのものに書く。** 指摘を別のノードとして起こし、
関係で要求へ結ぶやり方もあるが、 採らない。 理由は 3 章にある。

要求に足したのは次の 3 項目である。 `basic.sgra` が `REQUIREMENT` に宣言している。

| 項目 | 中身 | 書く人 |
| --- | --- | --- |
| `REVIEW_STATUS` | レビューの状態。 **必須** | レビューアと書いた人 |
| `REVIEW_COMMENT` | 指摘の内容。 何が問題か | レビューア |
| `REVIEW_ACTION` | 対策として何をしたか。 直さないならその理由 | 書いた人 |

## 状態の 5 つ

**Type**: SECTION

```text
- TITLE: REVIEW_STATUS
  TYPE: SingleChoice(NotReviewed, NoFinding, Open, Fixed, WontFix)
  REQUIRED: True
```

| 値 | 意味 | `REVIEW_COMMENT` | `REVIEW_ACTION` |
| --- | --- | --- | --- |
| `NotReviewed` | まだ誰も見ていない | 空 | 空 |
| `NoFinding` | 見た。 指摘なし | 空 | 空 |
| `Open` | **指摘あり・未対応** | **要る** | 空 |
| `Fixed` | 指摘に対応した | **要る** | **要る** |
| `WontFix` | 検討して**対応しないと決めた** | **要る** | **要る (理由を書く)** |

**`REQUIRED: True` にしてある。** 書き忘れると `strictdoc export` が止まるので、
「レビュー欄が無い要求」が生まれない。 **`NotReviewed` を明示的に置いたのは
このためである** — 欄が無いことに意味を持たせると、 書き忘れと区別が付かなくなる。

**`WontFix` は `Fixed` と同じくらい正当な終わり方である。** 指摘を受けて検討し、
直さないと決めたなら、 **その理由を `REVIEW_ACTION` に残す。** 理由が残っていれば、
半年後に同じ指摘が出たときに議論をやり直さずに済む。

**`Rejected` という語を使わない**のは、 指摘そのものを退けたように読めるためである。
受け取ったうえでの判断だと分かる語を選んだ。

## 書き方

**Type**: SECTION

**`REVIEW_STATUS` は `STATUS` の下、 メタの塊の中に置く。** 文章の 2 項目は
`Statement` や `Rationale` と同じ形で、 **ノードの末尾に段落として置く。**

```text
## 想定外の入力の拒否

**UID**: SYS-002 \
**STATUS**: Approved \
**REVIEW_STATUS**: Fixed

**Statement**: 本ツールは、 入力ファイルが利用者の指定した形式でない場合、 変換を行わないこと。

**REVIEW_COMMENT**: 壊れたファイルを渡されたときの扱いが決まっていなかった。

**REVIEW_ACTION**: SW-002 に読み取り失敗も検査の対象として足した。
```

**★ 段落として書く項目の順を変えてはならない。** `basic.sgra` が宣言した順と
`.md` に書いた順が食い違うと、 export が次のように止まる。 **メタの塊の中の
単一行の項目は順を入れ替えても通り、 StrictDoc が黙って文法の順へ並べ直す** (実測)。

```text
Semantic error: Wrong field order for requirement: [UID, STATUS, TITLE, REVIEW_STATUS, ...]
```

**★ 綴りは文法のとおりに書く。** `**Review_comment**:` は
`Invalid requirement field` で落ちる。 大文字小文字を問わないのは
`Statement` `Title` `Status` `Rationale` `Comment` `Level` `Tags` `Prefix`
の 8 語だけである。

## なぜ別ノードにしないか

**Type**: SECTION

指摘を `FINDING` のような独自の型として起こし、 `Role: Reviews` で要求へ結ぶ
やり方もある。 **この一式は以前それを採っていた。 やめた理由は 1 つである。**

**要求の一覧から状態が見えないからである。** 関係として結ぶと、 要求の側には
「指摘が在る」ことしか出ない。 **未対応なのか対応済みなのかは、 指摘を開くまで
分からない。** レビューで知りたいのはまさにそこである。

要求の項目にすると、 **Document / Table / Traceability の 3 つのビューすべてに出る**
(実測)。 とくに Table ビューは列の取捨選択と並べ替えができるので、
**「`Open` だけを並べる」がその場で終わる。**

**捨てたものもある。**

| | 要求の項目 (この一式) | 別ノード + 関係 |
| --- | --- | --- |
| 要求の一覧から状態が見える | **○** | ✗ |
| 1 つの要求に指摘を複数 | ✗ **1 件だけ** | **○** |
| 指摘ごとの UID と履歴 | ✗ | **○** |
| プロジェクト全体の行列に出る | ✗ | **○** |
| 書く手間 | **3 行足すだけ** | 別文書にノードを起こす |

**指摘を何件も積み、 1 件ずつ追跡する必要があるなら、 別ノードのほうが向く。**
そのときは `basic.sgra` に型を足す。 やり方は `02-guide-for-human.md` にある。

## 溜まった状態を数える

**Type**: SECTION

**画面で数えるより JSON を引くほうが速い。** 未対応の指摘を全部出す。

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS == "Open")
| .UID + "  " + .TITLE + "  " + (.REVIEW_COMMENT // "-")' <json>
```

状態ごとの件数はこれで出る。

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS?) | .REVIEW_STATUS]
| group_by(.) | map({(.[0]): length}) | add' <json>
```

**まだ誰も見ていない要求**を出すには `NotReviewed` を選ぶ。

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS == "NotReviewed")
| .UID + "  " + .TITLE' <json>
```

**指摘したのに中身を書き忘れた要求**は、 `audit.sh` が見つける。
`review comment missing` という検査がそれである。 **`Open` `Fixed` `WontFix` の
どれかなのに `REVIEW_COMMENT` が空**なら発火する。

## この一式の現状

**Type**: SECTION

`03-upper.md` と `04-lower.md` の 7 件が、 5 つの状態を一通り見せている。

| UID | `REVIEW_STATUS` | 何の例か |
| --- | --- | --- |
| `SYS-001` | `NoFinding` | 見たが指摘なし |
| `SYS-002` | `Fixed` | 指摘して直した |
| `SYS-003` | `Open` | **指摘あり・未対応** |
| `SW-001` | `NoFinding` | |
| `SW-002` | `NoFinding` | |
| `SW-003` | `NotReviewed` | **まだ見ていない** |
| `SW-004` | `WontFix` | 検討して直さないと決めた |

**テストケースには `REVIEW_STATUS` が無い。** `basic.sgra` は `REQUIREMENT` に
だけ宣言している。 テストもレビューの対象にするなら `TEST_CASE` にも同じ 3 項目を
足す。 **足すのは文法ファイルであり、 個別の文書ではない。**
