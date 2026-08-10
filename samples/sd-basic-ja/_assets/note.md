# 用語の対応表

**UID**: DOC-NOTE

このファイルは `.md` である。 **`.sdoc` の文書からリンクを張る先**として置いてある。
`00-guide-for-human.sdoc` の「添付」の節から `[LINK: DOC-NOTE]` で飛んでくる。

リンクの宛先になるために必要なのは、 見出しの直下に `**UID**:` を宣言すること
だけである。 出力先のパスは書かない。 StrictDoc が UID から解決する。

| 本サンプルの言い方 | StrictDoc の言い方 | 実体                                                 |
| ------------------ | ------------------ | ---------------------------------------------------- |
| 上位要求           | REQUIREMENT        | `01-upper.sdoc` の `SYS-*`                           |
| 下位要求           | REQUIREMENT        | `02-lower.sdoc` の `SW-*`                            |
| テストケース       | TEST_CASE          | `03-tests.sdoc` の `TC-*`                            |
| レビューの結果     | REQUIREMENT の項目 | `REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` |
| 地の文             | TEXT               | UID を持たない段落                                   |
| 章                 | SECTION            | `00-guide-for-human.sdoc` の入れ子                   |

**プロジェクト内の `.md` は、 置き場所に関係なく全部 StrictDoc が文書として
解析する。** `_assets/` の中も例外ではない。 だからこのファイルは `#` の見出しで
始めなければならない。 見出しの無い `.md` が 1 つあると export 全体が止まる。
