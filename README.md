mkd2indtag
==========

MarkdownをInDesignタグ付きテキストに変換するPerlスクリプト

##  SYNOPSIS

```sh
$ mkd2indtag.pl [options] [file ...]
```

Markdownファイルからタグ付きテキストを生成する場合
```sh
$ mkd2indtag.pl sample_text.md
```

HTMLファイルからタグ付きテキストを生成する場合
```sh
$ mkd2indtag.pl --ishtml sample_text.html
```

その前にスウォッチの定義を設定ファイルに書き込む場合
```sh
$ mkd2indtag.pl --swatch --ishtml sample_text.html
```

オプションです。
```
 Options:
    -m, --mac      InDesign for Mac向けのタグ付きテキストを生成する。
    -w, --win      InDesign for Windows向けのタグ付きテキストを生成する。
    -p, --profile  使用する設定ファイルを指定できます。デフォルトで使用する
                   設定ファイルは読み込まれません。
    -i, --ishtml   ファイルを強制的にHTMLファイルとして読み込む場合に指定。
                   拡張子が「.html」「.htm」の場合は指定しなくても勝手にHTML
                   ファイルとして読み込みます。
    -s, --swatch   ファイルを読み込んで必要なスウォッチを設定ファイルに定義します。
    -h, --help     ヘルプを全文表示します。初期設定の方法とかも見れます
```

##  DESCRIPTION

指定したMarkdownテキストファイルをInDesignタグ付きテキストに変換します。
テキストファイルはあらかじめエンコーディングをUTF-8に変換してください。
出力ファイルはUnicode（UTF-16 little endian）で作成しています。
ヘボいエディタだと中身が見られないかもしれません（Vimなら見られます！）。

Windowsだと秀丸エディタなら普通に見られるはず……。

##  PREPARATION 使うまでの準備

圧縮ファイルをデスクトップで解凍したと仮定して解説します。
ターミナルを起動し、カレントディレクトリを解凍したフォルダに移動します。

```sh
$ cd ~/Desktop/mkd2indtag/
```

アプリケーションの実行に必要なモジュールをダウンロードします。
下記のコマンドでダウンロードできます。

```sh
$ ./cpanm -L . --installdeps .
```


解凍したフォルダを環境変数「PATH」に追加しておくと便利です。
シェルがbashなら、おそらく下記のコマンドを実行すれば大丈夫（たぶん。。

```sh
$ echo "export PATH = $PATH:~/Desktop/mkd2indtag" >> ~/.bash_profile
```

あとはターミナルを再起動するだけ！ これで準備は完了です。


##  追加したい機能

preタグのクラス名から言語名を読み取る。また、spanタグのクラス名から各言語のスウォッチを定義する。

プログラムのフローは、以下のような感じかな？

1. 原稿を読み込んで必要な言語と要素を取得
2. 設定ファイルを確認して未定義のスウォッチを探す
3. 未定義のスウォッチを定義する
4. 未定義のスウォッチを設定ファイルに書き込む
5. 設定ファイルから定義済みのスウォッチを読み込む
6. 原稿にスウォッチを定義する
   6-1. 「<>'&」などの文字をHTMLエンコード
   6-2. InDesignたぐい外で使われている「<>」を「\」でエスケープ
7. spanタグの該当部分に定義済みのスウォッチを割り当てる


###  スウォッチの定義は下記のとおり

```
<ColorTable:=<RTF r163 g21 b21:COLOR:CMYK:Process:0.42089998722076416,1,1,0.09129999577999115><chap02:COLOR:CMYK:Process:0,0.8999999761581421,0.5,0><表組01:COLOR:CMYK:Process:0,0,0.1,0><表組02:COLOR:CMYK:Process:0,0,0,0.1><Paper:COLOR:CMYK:Process:0,0,0,0>>
```

###  スウォッチの割り当ては下記のとおり

```
<cColor:RTF r163 g21 b21>\<stdio.h\><cColor:>
```

