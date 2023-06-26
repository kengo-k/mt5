# 初期設定

GitHub から Clone した本プロジェクトのルートディレクトリを`MQL5`という名前に変更し MT5 の所定ディレクトリにそのまま配置する。
(修正したソースコードをそのまま GitHub へ Push できるようにするため)

MT5 の所定ディレクトリは以下の通り:

```
<HOME_DIRECTORY>\AppData\Roaming\MetaQuotes\Terminal\<ID>
```

しかし上記のディレクトリ内にはすでに`MQL5`ディレクトリが存在している。そのため、次の手順に従い移行を行う。

- 既存の`MQL5`ディレクトリをリネームする(MQL5.bk)
- clone したリポジトリを`MQL5`にリネームし上記の所定ディレクトリ内に配置する
- `MQL5.bk`内のファイルをすべて選択し、`MQL5`ディレクトリ内に貼り付ける

この操作により、MQL5 の開発に必要な既存の構成と自分が作成するソースコードがマージされる。

現在は下記のディレクトリを使用している。

```
C:\Users\<user-name>\AppData\Roaming\MetaQuotes\Terminal\2FA8A7E69CED7DC259B1AD86A247F675
```

上記ディレクトリは XMTrading(本番利用のために口座を解説したが現在は凍結中) の MT5 となる。
