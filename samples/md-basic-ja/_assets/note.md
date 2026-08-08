# 用語の対応表

**UID**: DOC-NOTE

このファイルは `_assets/` の中にあるが、 **StrictDoc は 1 個の文書として扱う。**
`02-guide-for-human.md` の「リンク」の節から `[LINK: DOC-NOTE]` で飛んでくる。

リンクの宛先になるために必要なのは、 見出しの直下に `**UID**:` を宣言することだけ
である。 出力先のパスは書かない。 StrictDoc が UID から解決する。

| 本サンプルの言い方 | StrictDoc の言い方 | 実体 |
| --- | --- | --- |
| 上位要求 | REQUIREMENT | `05-upper.md` の `SYS-*` |
| 下位要求 | REQUIREMENT | `06-lower.md` の `SW-*` |
| テストケース | TEST_CASE | `07-tests.md` の `TC-*` |
| レビューの結果 | REQUIREMENT の項目 | `REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` |
| 地の文 | TEXT | UID を持たない段落 |
| 章 | SECTION | `**Type**: SECTION` を書いた見出し |

**StrictDoc はプロジェクト内の `.md` を、 置き場所に関係なく全部文書として解析する。**
だからこのファイルも `#` の見出しで始めなければならない。 見出しの無い `.md` が
1 つあると export 全体が止まる。
