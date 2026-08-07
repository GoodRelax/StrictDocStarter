# jq-samples/

`try-json-query-ja.bat` が使う jq のフィルタ置き場です。手で走らせることもできます。

```bat
strictdoc export samples\md-basic-ja --formats=json --output-dir exported-json
jq -r -f jq-samples\01-open-findings-en.jq exported-json\json\index.json
```

| ファイル | 何を出すか | 書いてある言語 |
|---|---|---|
| `01-open-findings-en.jq` | 未対処のレビュー指摘を 1 行ずつ | 英語 |
| `02-keyword-ja.jq` | 「変換」を含む要求 | 日本語 |
| `03-findings-json.jq` | レビュー指摘を JSON の配列で | 英語 |

## 覚えておくこと

**フィルタは文字列で渡さずファイルに書く。** PowerShell は引用符の中の二重引用符を
落とすため、`jq "<フィルタ>" file` の形はそこで壊れます。`-f ファイル` ならどの
shell でも同じに動きます。

**日本語はこのファイルの中に書く。** 同じ語をコマンド行から `--arg` で渡すと、
cmd.exe の既定 (cp932) では**エラーも出ずに 0 件**になります。`chcp 65001` を先に
打てば通りますが、打ち忘れた人は「1 件も無い」という誤った答えを受け取ります。
ファイルの中身は jq が UTF-8 として読むので、cp932 のままでも正しく一致します
(いずれも実測)。

**`-r` を付けるかどうかで用途が変わる。** 付ければ人が読む行、付けなければ JSON
のままです。プログラムに渡すなら付けません。

## 自分のプロジェクトで使うとき

`FINDING` は StrictDoc の標準のノード型ではありません。`samples/md-basic-ja` と
`samples/sd-basic-ja` が共有する `basic.sgra` が宣言しているものです。素の文法の
プロジェクトに `01` や `03` を当てると、エラーではなく**結果が 0 件**になります。

さらに 7 本の実例が [`docs/03-sdoc-json-queries.md`](../docs/03-sdoc-json-queries.md)
にあります。解説は [`samples/md-basic-ja/01-guide-for-human.md`](../samples/md-basic-ja/01-guide-for-human.md)
の第 4 章です。
