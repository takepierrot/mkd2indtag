#!/usr/bin/env perl
use v5.14;
use warnings;
use utf8;
use autodie;

use FindBin;
use lib $FindBin::Bin . '/lib';

use Encode qw/encode decode/;
use Encode::Locale;
use Encode::UTF8Mac;

binmode STDOUT => ':encoding(console_out)';
binmode STDERR => ':encoding(console_out)';

use FileSyori;
use Swatch;

# change locale_fs "utf-8" to "utf-8-mac"
if ($^O eq 'darwin') {
    require Encode::UTF8Mac;
    $Encode::Locale::ENCODING_LOCALE_FS = 'utf-8-mac';
}


use Web::Query qw/wq/;
use HTML::TreeBuilder;


use Getopt::Long qw/GetOptions :config posix_default no_ignore_case bundling auto_help/;
use Pod::Usage qw/pod2usage/;


# 受け取るoptionの定義とオプションのデフォルト値
# s=文字列型, i=整数型, f=実数型, @=同optionを複数回指定可, 型なし=boolean
my @def = qw/mac|m win|w profile|p=s@ ishtml|i swatch|s help|h/;
my $opt = {};

main();


sub main {
    GetOptions($opt, @def) or pod2usage();
    pod2usage(verbose => 99) if $opt->{help};

    # 解析した以外の引数が必要ならここでチェック
    pod2usage("Pleas set \@ARGV\n") unless @ARGV;

    my $file_serve = FileSyori->new;

    # スウォッチファイルの作成
    my $swatch = Swatch->new;
    if ($opt->{swatch}) {
        $swatch->create_swatch_profile($_, $opt->{ishtml}) for @ARGV;
        exit;
    }

    # 必須オプションのチェック
    my @no_double = grep {exists $opt->{$_}} qw/win mac/;
    pod2usage(qq/オプション "@no_double" は同時に設定できません\n/) if scalar @no_double == 2;

    # 設定ファイル「new_style.yaml」の定義スタイルとのマージ
    $file_serve->marge_style();
    # 引数のファイルを処理
    $file_serve->process_file_henkan($_, $opt->{ishtml}) for @ARGV;
}



=encoding utf8

=head1 NAME

script_name - mkd2indtag.pl

=head1 SYNOPSIS

 $ mkd2indtag.pl [options] [file ...]

 [Markdownファイルからタグ付きテキストを生成する場合]
 $ mkd2indtag.pl sample_text.md

 [HTMLファイルからタグ付きテキストを生成する場合]
 $ mkd2indtag.pl --ishtml sample_text.html

 [その前にスウォッチの定義を設定ファイルに書き込む場合]
 $ mkd2indtag.pl --swatch --ishtml sample_text.html

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

=head1 DESCRIPTION

 指定したMarkdownテキストファイルをInDesignタグ付きテキストに変換します。
 テキストファイルはあらかじめエンコーディングをUTF-8に変換してください。
 出力ファイルはUnicode（UTF-16 little endian）で作成しています。
 ヘボいエディタだと中身が見られないかもしれません（Vimなら見られます！）。

 Windowsだと秀丸エディタなら普通に見られるはず……。

=head1 PREPARATION 使うまでの準備

 圧縮ファイルをデスクトップで解凍したと仮定して解説します。
 ターミナルを起動し、カレントディレクトリを解凍したフォルダに移動します。

 $ cd ~/Desktop/mkd2indtag/

 アプリケーションの実行に必要なモジュールをダウンロードします。
 下記のコマンドでダウンロードできます。

 $ ./cpanm -L . --installdeps .


 解凍したフォルダを環境変数「PATH」に追加しておくと便利です。
 シェルがbashなら、おそらく下記のコマンドを実行すれば大丈夫（たぶん。。

 $ echo "export PATH = $PATH:~/Desktop/mkd2indtag" >> ~/.bash_profile

 あとはターミナルを再起動するだけ！ これで準備は完了です。


=head1 追加したい機能

 preタグのクラス名から言語名を読み取る。また、spanタグのクラス名から各言語のスウォッチを定義する。
 
 プログラムのフローとしては、
 1. 原稿を読み込んで必要な言語と要素を取得
 2. 設定ファイルを確認して未定義のスウォッチを探す
 3. 未定義のスウォッチを定義する
 4. 未定義のスウォッチを設定ファイルに書き込む
 5. 設定ファイルから定義済みのスウォッチを読み込む
 6. 原稿にスウォッチを定義する
    6-1. 「<>'&」などの文字をHTMLエンコード
    6-2. InDesignたぐい外で使われている「<>」を「\」でエスケープ
 7. spanタグの該当部分に定義済みのスウォッチを割り当てる

 
=head2 スウォッチの定義は下記のとおり

 <ColorTable:=<RTF r163 g21 b21:COLOR:CMYK:Process:0.42089998722076416,1,1,0.09129999577999115><chap02:COLOR:CMYK:Process:0,0.8999999761581421,0.5,0><表組01:COLOR:CMYK:Process:0,0,0.1,0><表組02:COLOR:CMYK:Process:0,0,0,0.1><Paper:COLOR:CMYK:Process:0,0,0,0>>

=head2 スウォッチの割り当ては下記のとおり

 <cColor:RTF r163 g21 b21>\<stdio.h\><cColor:>

=head1 METHOD

none.

=head1 AUTHOR

Takehiro Sawada

=head1 LICENSE

Copyright (C) Takehiro Sawada

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
