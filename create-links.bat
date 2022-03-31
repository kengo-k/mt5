@rem リポジトリ内の各ディレクトリをmt5の対応するディレクトリ内にリンクするスクリプト。
@rem mklinkを使用するため実行するには管理者権限が必要。

setlocal

set current_dir=%~dp0

@rem mt5のデータディレクトリを引数として指定する
@rem データディレクトリはC:\Users\maku\AppData\Roaming\MetaQuotes\Terminal\XXXXXXXXXXXのような形式になっている
@rem ※各マシンごとに異なるので確認すること
@rem 自宅のメインPC: C:\Users\kuronyan\AppData\Roaming\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB
set data_dir=%~1


cd /d %data_dir%
mklink /d MQL5\Experts\Custom %current_dir%MQL5\Experts\Custom
mklink /d MQL5\Include\Custom %current_dir%MQL5\Include\Custom
mklink /d MQL5\Libraries\Custom %current_dir%MQL5\Libraries\Custom
