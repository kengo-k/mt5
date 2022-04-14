@rem リポジトリ内の各ディレクトリをmt5の対応するディレクトリ内にリンクするスクリプト。
@rem mklinkを使用するため実行するには管理者権限が必要。

setlocal

set current_dir=%~dp0

@rem mt5のデータディレクトリを引数として指定する
@rem データディレクトリはC:\Users\maku\AppData\Roaming\MetaQuotes\Terminal\XXXXXXXXXXXのような形式になっている
@rem ※各マシンごとに異なるので確認すること
@rem 自宅のメインPC: C:\Users\kuronyan\AppData\Roaming\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB
@rem set data_dir=%~1


@rem cd /d %data_dir%
mklink /d D:\MQL5\Experts %current_dir%Experts\Custom
mklink /d D:\MQL5\Include %current_dir%Include\Custom
mklink /d D:\MQL5\Libraries %current_dir%Libraries\Custom
mklink /d D:\MQL5\Tests %current_dir%Tests
mklink /d D:\MQL5\Reports %current_dir%..\Reports

