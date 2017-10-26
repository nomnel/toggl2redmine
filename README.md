# 概要

toogl に登録したデータから Redmine の作業時間を登録するためのコードを吐くスクリプト
(Redmine の REST API を使うことは妥協した)

# 事前準備

`~/.toggl` として Toggl の token を記入したファイルを置く

# 使い方

```sh
bundle exec ruby fetch.rb '2017-10-01'
# intermediate.csv を編集する
bundle exec ruby generate.rb nomnel
# あとは表示されたスクリプトを丹念に rails c に流し込む
```
