# 書き方の型 - Markdown 版

**Grammar**: patterns.sgra \
**UID**: DOC-PATTERNS-MD \
**Version**: 1.0

同じ要求を Markdown で書くとこうなる。 `.sdoc` 版とは別の UID を使っている
(同じ UID を 2 つの文書に置くことはできない)。

`# ` が文書タイトル、 `## ` が要求のタイトル、 メタは行末のバックスラッシュで
1 ブロックにまとめる。 バックスラッシュは StrictDoc 以外の Markdown ビューアで
メタ行が離れて表示されるのを防ぐためのもので、 StrictDoc の解析には不要である。

## 入力ファイルの変換

**UID**: MD-001 \
**STATUS**: Approved

**Statement**: 本ツールは、 利用者が指定した入力ファイルを出力形式へ変換すること。

## 入力形式の検査

**UID**: MD-002 \
**STATUS**: Approved

**Statement**: 本ツールは、 変換を開始する前に入力ファイルが想定した形式かを検査し、 形式が異なる場合は変換を行わずに終了すること。

**Relations**:
- **Type**: `Parent` \
  **ID**: `MD-001`

## 画像の埋め込み

**Type**: SECTION

見出し直下の地の文は暗黙の `Statement` として扱われるため、 このままでは要求ノードに
なり、 文法が要求する `UID` が無いと解析が落ちる。 **要求ではない節は
`**Type**: SECTION` と明示する。**

画像は `![alt](path)` で埋め込む。 `.sdoc` 側の `.. image::` と同じファイルを指せる。

**図 (Mermaid) はこの文書には置かない。** 本サンプルは図を `_assets/` の断片へ
外に出し、 `[DOCUMENT_FROM_FILE]` で取り込む 1 通りに統一している。 理由と書き方は
`03-figures.sdoc` を参照。

![input file から output file までの流れと停止条件](_assets/pipeline.png)
