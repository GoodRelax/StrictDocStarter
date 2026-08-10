# StrictDocStarter (日本語)

英語版は [README.md](README.md) にあります。

**[StrictDoc](https://github.com/strictdoc-project/strictdoc) を Windows で一発で使い始めるためのクイックスタート。**
クリーンな Windows 11 PC から「ブラウザで要求ツリーを閲覧」まで到達できます。
Python もコマンドラインも手動設定も要りません。

> **公式の置き換えではなく、コミュニティ製のクイックスタートです。** StrictDocStarter は
> 公式 StrictDoc を導入して起動するところまでを引き受けます。サーバもプロジェクト雛形も
> 設定も、すべて公式 StrictDoc のものです。実プロジェクトでは公式のドキュメントに従ってください。

## クイックスタート

必要なものは **Windows 11** だけです。Git も Python も StrictDoc も setup が入れます。

1. **[ZIP をダウンロード](https://github.com/GoodRelax/StrictDocStarter/archive/refs/heads/main.zip)** (約 4 MB)。
2. 右クリックして**すべて展開**を選びます。**`StrictDocStarter-main`** という名前の
   フォルダができます。デスクトップなど、好きな場所へ置いてください。
3. **`setup-strictdoc.bat`** をダブルクリックし、Windows の確認画面を承認して、
   表示されるプランを読んでから `yes` と入力します。ツールチェインが入ります。
   **15〜30 分**かかり、そのほとんどはダウンロード時間です。
4. **`launch-strictdoc.bat`** をダブルクリックし、**Enter** を押します。

ブラウザで `http://127.0.0.1:5111/` が開き、実物の要求ツリーが表示されます。
**止めるときは、ブラウザと一緒に開いたサーバウィンドウを閉じてください。**

> 企業プロキシの配下では、手順 3 が何もダウンロードできずに失敗することがあります。
> 先に[プロキシ環境の場合](docs/04-starter-guide-ja.md#プロキシ環境の場合)を読んでください。

## いま開いているもの

表示されているのは `samples/md-basic-en` です。要求仕様書として最低限成り立つ一式で、
上位要求 3 件、それを指す下位要求 4 件、それを検証するテストケース 4 件、そして要求
そのものに載せたレビュー欄を**それぞれ別ファイル**に置いてあります。トレーサビリティ
がファイルをまたぐようにするためです。

**自分の仕様書は、このフォルダを丸ごと写して始めてください。** 別のフォルダを開くには、
そのフォルダを `launch-strictdoc.bat` にドラッグ&ドロップします。1 文書 = 1 ウィンドウで、
何枚でも同時に開けます。

StrictDoc 自身にもランチャーが入り、`open-strictdoc-launcher.bat` で起動できます。
同時に開けるのは 1 文書だけですが、その代わり Export・設定編集・UID 修復・`git` 操作まで
面倒を見てくれます —— [2 つの比較](docs/04-starter-guide-ja.md#2-つのランチャー)。

同梱サンプルは[ブラウザでも読めます](https://goodrelax.github.io/StrictDocStarter/)。何も入れずに読めて、
要求 122 件の自動車仕様書も入っています。

## 次に読むもの

| 場所                                                           | 内容                                                                                                                                                      |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`docs/04-starter-guide-ja.md`](docs/04-starter-guide-ja.md)   | **StrictDocStarter のそれ以外すべて**。setup が導入するもの、複数文書の同時起動、生成物の出力先、ライトとダーク、同梱サンプル、StrictDoc のバージョン固定 |
| [`docs/01-environment.md`](docs/01-environment.md)             | セットアップの手順詳細とトラブルシュート表                                                                                                                |
| [`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md)       | **`.sdoc` と `.md` の書き方。** 書き手が要求 1 件ごとに公式ガイドを読み直さずに済む最小限                                                                 |
| [`docs/03-sdoc-json-queries.md`](docs/03-sdoc-json-queries.md) | JSON 出力に対する、コピーして実行できる `jq` クエリ 5 種                                                                                                  |
| [`claude-skills/strictdoc-md/`](claude-skills/strictdoc-md)    | 仕様書の読み書きと監査を Claude に任せるための **Claude Code スキル**                                                                                     |
| `try-json-query-ja.bat`                                        | 仕様書を JSON に出し、`jq` で答えを引く手順を 7 段でなぞる練習用。ダブルクリックで動きます。`-en` は同じ内容の英語版                                      |

うまく動かないときは `gather-logs.bat` を実行してください。ログと診断レポートが
ZIP にまとまります。展開して Claude Code に読ませ、原因を調べさせてください。
レポートには PC 名やフォルダの場所が入るので、誰かに渡す前に中身を確認してください。

## ライセンス

[Apache License 2.0](LICENSE) — StrictDoc と同じライセンス。

## リンク

- 公式 StrictDoc: <https://github.com/strictdoc-project/strictdoc>
- StrictDoc ドキュメント: <https://strictdoc.readthedocs.io/>
