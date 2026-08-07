# 基本 - レビュー指摘

**Grammar**: basic.sgra \
**UID**: DOC-REVIEW \
**Version**: 1.0

**この文書が `basic.sgra` を置いてある理由そのものである。**

レビュー指摘も StrictDoc の標準概念ではない。 組み込みの要求に無理に押し込むと
「重大度」や「対処状況」の置き場が無い。 そこで `basic.sgra` に `FINDING` という
ノード型を足し、 `SEVERITY` と `RESOLUTION` を専用のフィールドとして宣言してある。

**選択肢は文法側で固定する。** `SingleChoice(Major, Minor, Question)` と書いて
おけば、 綴り違いはその場で解析エラーになり、 ブラウザの編集画面では選択肢の
ドロップダウンになる。 自由記入にしてはならない。

対象の要求へは `Reviews` のロールで結ぶ。 これで指摘は要求の画面にも並んで
表示され、 JSON からも 1 クエリで取り出せる。

## SW-002 の検査方法が決まっていない

**Type**: FINDING \
**UID**: RV-001

**SEVERITY**: Major

**RESOLUTION**: Open

**Statement**: SW-002 は「形式を検査する」の判定方法を書いていない。 拡張子で見るのか中身を見るのかで実装も TC-002 の手順も変わる。 どちらかに決めること。

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-002` \
  **Role**: `Reviews`

## SYS-003 に上書きを許す手段が無い

**Type**: FINDING \
**UID**: RV-002

**SEVERITY**: Question

**RESOLUTION**: Open

**Statement**: 既定を安全側に倒すのは妥当だが、 意図して上書きしたい利用者の逃げ道が無い。 明示的な指定を設けるかどうかが未決である。

**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-003` \
  **Role**: `Reviews`
