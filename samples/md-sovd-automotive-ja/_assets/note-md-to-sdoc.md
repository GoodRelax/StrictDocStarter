# 覚書 - この仕様書を `.sdoc` から `.md` へ移したときに測ったこと

**UID**: DOC-SOVD-NOTE-MD2SDOC

本書は仕様ではない。 **この一式を `.sdoc` の原本から `.md` へ移す作業で実際に
測った制約**を残したものである。 逆方向 (`.md` → `.sdoc`) を試す人にも同じ制約が
効く。

**このファイル自身が「外部 Markdown」の実例でもある。** `_assets/` に置いた `.md` は
StrictDoc が 1 個の文書として解析するので、 見出しの直下で `**UID**:` を宣言すれば
本文から `[LINK:]` で飛べる。 **`.md` には図や文書の断片を取り込む手段が無い**
(`.sdoc` の `[DOCUMENT_FROM_FILE]` に相当するものが無い) ため、 外に出した資料へは
リンクで繋ぐ。

環境: strictdoc 0.27.1 / Python 3.13 / Windows 11。

## 1. 変換そのものは StrictDoc が行う

**Type**: SECTION

`.sdoc` から `.md` への変換は `--formats=markdown` が行う。 逆は `--formats=sdoc`
である。 ノードの構造 — 文書・章・要求・関係・カスタムフィールド — はそのまま移る。

```bash
strictdoc export <仕様書のフォルダ> --formats=markdown --output-dir <出力先>
```

**移らないのは本文の記法だけである。** `.sdoc` の本文は既定で RST として解釈される
ので、 RST のディレクティブはそのままの文字列で出てくる。 この一式では次の 5 つを
手で書き換えた。

| RST | Markdown |
|---|---|
| `.. raw:: html` + `<pre class="mermaid">` | ` ```mermaid ` のフェンス |
| `.. math::` / `` :math:`x` `` | `$$ ... $$` / `$x$` |
| `.. image:: path` | `![説明](path)` |
| `.. list-table::` | パイプ表 |
| `.. code-block:: <言語>` | ` ``` ` + 言語名のフェンス |

## 2. ★ 文法の宣言順を直さないと `.md` は読めない

**Type**: SECTION

**`.md` では `TITLE` を見出しから取るため、 StrictDoc は `TITLE` を `UID` の直後に
置く。** したがって **文法の `FIELDS` も `TITLE` を `UID` の直後に宣言する**必要が
ある。 原本の `sovd-grammar.sgra` は `TITLE` を `LAYER` の後ろに宣言していたので、
変換した `.md` はこう言って止まった。

```text
Semantic error: Wrong field order for requirement: [UID, TITLE, TYPE, ASIL, LAYER, STATEMENT, VERIFICATION].
Hint: Problematic field: TITLE. Compare with the document grammar: [UID, TYPE, ASIL, CAL, LAYER, TITLE, STATEMENT, RATIONALE, VERIFICATION] for type: REQUIREMENT.
```

**直し方は 2 つある。** 文法の `TITLE` を前に出すか、 `.md` を諦めるかである。
この一式は前者を採り、 `REQUIREMENT` と `API` の `TITLE` を `UID` の直後へ移した。
`.sdoc` の原本も同じ順に直さないと、 今度は原本が止まる。

**★ 順を崩すと json / html / sdoc のすべてが即座に止まる** (実測)。
「json は通るが sdoc で落ちる」ということは起きない。

## 3. ★ `TYPE` という名前は使える。 `LEVEL` は使えない

**Type**: SECTION

**`TYPE` は使える。** `.md` の reader が予約しているのは `Type` という綴りだけで、
`field_.name == "Type"` と**完全一致・大文字小文字を区別して**比べている
(`backend/markdown/reader.py`)。 `**TYPE**:` と大文字で書けば通常のフィールドとして
通り、 同じノードに `**Type**: COMPONENT` を併記することもできる。

**`LEVEL` は使えない。** StrictDoc 組み込みの `Level` (目次の水準) と衝突する。
**厄介なのは、 export が成功したまま壊れることである** — 目次の番号 `_TOC` が
`LEVEL` の値で上書きされる。

```text
{"_TOC":"Unit", "_NODE_TYPE":"REQUIREMENT", "UID":"R-001", "LEVEL":"Unit", "TITLE":"..."}
                                                    ↑ 本来は "1" のような階層番号
```

この一式はテストの水準を **`TEST_LEVEL`** という名前に変えて避けている。
`COMMENT` や `PRIORITY` は同じ組み込み語でも衝突しなかった (実測)。
**大文字小文字を問わない組み込み 8 語** — `Statement` `Title` `Status` `Rationale`
`Comment` `Level` `Tags` `Prefix` — のうち、 実害が出たのは `Level` だけである。

## 4. ★ `.md` → `.sdoc` の往復はそのままでは戻らない

**Type**: SECTION

`--formats=sdoc` は全文書を書き出すが、 **その出力の読み戻しは 2 つの理由で
止まる。 どちらも宣言順とは関係が無い** (実測)。

1. **`.sgra` が一緒に複製されない。** 生成した `.sdoc` は文法ファイルを名指しするが、
   出力先へその複製を作る仕組みが無い。 自分で複製する
2. **`[LINK: UID]` を「書き方の例」として引用している文書が、 その引用を実際の
   リンクに変える。** `.md` ではただの文字のままだが、 生成した `.sdoc` では
   StrictDoc が解決しようとして次のように止まる

```text
error: DocumentIndex: the inline link references an object with an UID that does not exist: UID.
```

**`[LINK: DOC-FIG-ARCH-CONTEXT]` のような本物のリンクは変換で保たれる。**
引用 1 箇所を潰し、 文法を複製したところ、 読み戻しは通った。

**この一式が記法の解説文書を持たない**のは、 同じ知識を 4 か所に増やさないためだが、
**副次的にこの罠も避けている** — 引用する `[LINK: UID]` がどこにも無い。

## 5. 往復が要るなら `.md` を正本にする

**Type**: SECTION

上の 2 つは手で直せる範囲であり、 **一方向の変換は実用になる。** ただし往復を
前提にするなら、 **`.md` を正本として保ち、 `.sdoc` は書き出した結果として扱う**のが
安全である。 逆にすると、 変換のたびに上の 2 点を手当てし続けることになる。
