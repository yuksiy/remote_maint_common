# remote_maint_common

## 概要

リモートメンテナンス共通ツール

現状では以下のパッケージによってのみ使用されることを想定しています。

* [system_backup_unix](https://github.com/yuksiy/system_backup_unix)

## 使用方法

「*.sh」ファイルのヘッダー部分を参照してください。

## 動作環境

OS:

* Linux

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* openssh
* [ssh_cmd](https://github.com/yuksiy/ssh_cmd)
* [iface_tools_pl](https://github.com/yuksiy/iface_tools_pl) (「HOST_WAIT 関数」を使用する場合のみ)
* [cmd_status_wait](https://github.com/yuksiy/cmd_status_wait) (「CMD_WAIT 関数」を使用する場合のみ)

## インストール

ソースからインストールする場合:

    (Linux の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

[examples/README.md ファイル](https://github.com/yuksiy/remote_maint_common/blob/master/examples/README.md)
を参照して設定ファイルをインストールしてください。

## 最新版の入手先

<https://github.com/yuksiy/remote_maint_common>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/remote_maint_common/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2012-2017 Yukio Shiiya
