package TagReplace;
use strict;
use warnings;
use feature qw/say/;
use utf8;
use autodie;

use FindBin;
use lib $FindBin::Bin . '/lib';

use Encode;
use Encode::Locale;
use Web::Query;
use Text::Markdown::Discount qw/markdown/;
use HTML::Entities;

use Class::Accessor::Fast q/antlers/;

my %henkan_danraku = (
    h1     => '大見出し',
    h2     => '中見出し',
    h3     => '小見出し',
    h4     => 'コラム見出し',
    p      => '本文',
    ul     => {li => '箇条書き'},
    ol     => {li => '箇条書き-no'},
    th     => '表-見出し行',
    td     => '表-行',
    code   => 'コード',
    column => {h4 => 'コラム見出し', p => 'コラム'},
);

my %henkan_moji = (
    strong => '強調',
    em     => '斜体',
    code   => 'コードインライイン',
);

my %before_henkan = ();
my %after_henkan  = ();

sub danraku {
    return %henkan_danraku;
}

sub danraku_style_marge {
    my ($self, $new_styles_danraku) = @_;
    %henkan_danraku = (%henkan_danraku, %$new_styles_danraku);
}

sub moji_style_marge {
    my ($self, $new_styles_moji) = @_;
    %henkan_moji = (%henkan_moji, %$new_styles_moji);
}

sub header {
    my $self = shift @_;
    if ($^O eq 'darwin') {
        return '<SJIS-MAC>';
    }
    else {
        return '<SJIS-WIN>';
    }
}

# 以下はHTML要素を分解してテキスト化する関数
# 第2引数の $webQuery は Web::Query のインスタンス

sub default_tag {
    my ($self, $webQuery, $key) = @_;
    if ($key eq 'p' && $webQuery->find('img')->as_html) {
        return $webQuery->find('img')->attr('src');
    }
    else {
        return replace($henkan_danraku{$key}, $webQuery);
    }
}

sub h1 {
    my $self = shift @_;
    $self->default_tag(@_);
}

sub h2 {
    my $self = shift @_;
    $self->default_tag(@_);
}

sub h3 {
    my $self = shift @_;
    $self->default_tag(@_);
}

sub p {
    my $self = shift @_;
    $self->default_tag(@_);
}

sub div {
    my ($self, $webQuery, $key) = @_;
    if ($webQuery->attr('class') eq 'column') {
        my $column_html = markdown($webQuery->text);
        my @column_text = ();
        wq("<body>$column_html</body>")->contents->each( sub {
            my ($num, $clwq) = @_;
            my ($key) = $clwq->as_html =~ m/^<([^<\s]+?)[\s>]/;
            push @column_text => replace(
                $henkan_danraku{$webQuery->attr('class')}->{$key}, $clwq
            );
        });
        return join "\n" => @column_text;
    }
}

sub ul {
    # /ul li/を処理
    my ($self, $webQuery, $key) = @_;
    return $self->li($webQuery, $key);
}

sub ol {
    # /ul li/を処理
    my ($self, $webQuery, $key) = @_;
    return $self->li($webQuery, $key);
}

sub li {
    my ($self, $webQuery, $key) = @_;
    my @li_list = ();
    $webQuery->find('li')->each(sub {
        my (undef, $child_elem) = @_;
        push @li_list => replace($henkan_danraku{$key}->{li}, $child_elem);
    });
    return join "\n" => @li_list;
}

sub table {
    # /tabel tr th|td/を処理
    my ($self, $webQuery, $key) = @_;
    my (@header, @body) = ();
    $webQuery->find('tr')->each(sub {
        my ($num, $child_elem) = @_;
        if ($num == 0) {
            $child_elem->find('th')->each(sub { push @header => $_ });
        }
        else {
            my @body_elem = ();
            $child_elem->find('td')->each(sub { push @body_elem => $_ });
            push @body => \@body_elem;
        }
    });
    my (@list_h,  @list) = ();
    my $header = join "\t" => map {$_->html} @header;
    push @list => replace($henkan_danraku{th}, $header);
    for my $body_elem (@body) {
        my $list_str = join "\t" => map {$_->html} @$body_elem;
        push @list => replace($henkan_danraku{td}, $list_str);
    }
    return join "\n" => @list;
}

sub pre {
    # /pre code/を処理
    my ($sef, $webQuery, $key) = @_;
    my @code_line = ();
    for my $line (split "\n" => $webQuery->text) {
        push @code_line => "<ParaStyle:$henkan_danraku{code}>$line";
    }
    return join "\n" => @code_line;
}

sub blockquote {
    my ($sef, $webQuery, $key) = @_;
    # これから書きます……
    ...;
    return replace($key, $webQuery);
}


sub replace {
    my ($tagname, $webQuery) = @_;
    # たまにHTMLエンコードされたテキストが来るので、対処を切り分け
    my $html_entities = ref $webQuery ? $webQuery->html : $webQuery;
    # 文字スタイルの処理
    for my $tag (keys %henkan_moji) {
        $html_entities =~ s{<$tag>(.+?)</$tag>}
                {<CharStyle:$henkan_moji{$tag}>$1<CharStyle:>}g;
    }
    my $content = decode_entities($html_entities);
    return "<ParaStyle:$tagname>$content";
}

1;

# ================================================================= #

package main;

use v5.14;
use warnings;
use utf8;
use autodie;

use Encode;
use Encode::Locale;
use Encode::UTF8Mac;

binmode STDOUT => ':encoding(console_out)';

# change locale_fs "utf-8" to "utf-8-mac"
if ($^O eq 'darwin') {
    require Encode::UTF8Mac;
    $Encode::Locale::ENCODING_LOCALE_FS = 'utf-8-mac';
}


use Web::Query;
use Text::Markdown::Discount qw/markdown/;
use HTML::TreeBuilder;
use YAML::Syck;
$YAML::Syck::ImplicitUnicode = 1;


my $tagreplace = TagReplace->new;

# marge_style();
# my %dan = $tagreplace->danraku();
# say $dan{h1};
# use Data::Dump qw(dump);
# warn dump %dan;


main($_) for @ARGV;

sub marge_style {
    # 設定ファイル「new_style.yaml」の定義スタイルとのマージ
    open my $in_newstyles, '<:utf8', $FindBin::Bin . '/new_style.yaml';
    my $new_styles = Load(do {local $/; <$in_newstyles>});
    $tagreplace->danraku_style_marge($new_styles->{danraku});
    $tagreplace->moji_style_marge($new_styles->{moji});
}

sub main {
    my $path = shift @_;

    # 設定ファイル「new_style.yamal」の定義スタイルとのマージ
    marge_style();

    # 変換するファイルを読み込む
    open my $in, '<:utf8', $path;
    my $markdown = do { local $/; <$in> };
    my $html = markdown($markdown) . "\n";

    # 改行をそのまま残すためにこのように動作させています。
    my $tree = HTML::TreeBuilder->new;
    $tree->no_space_compacting(1);
    my $wq = Web::Query->new_from_element($tree->parse($html));


    # 出力するファイルの1行目にヘッダーを挿入
    my $parsed_strings = $tagreplace->header . "\n";

    # Markdownを解析してInDesignタグ付きテキストに変換
    $wq->find('body')->contents->each(sub {
        my (undef, $webQuery) = @_;

        # $key はタグの名前。なんで $key という名前をつけてしまったのか...
        my ($key) = $webQuery->as_html =~ m/^<(.+?)[\s>]/;
        # $key で TagReplace のメソッドを動的に呼び出し
        $parsed_strings .=  $tagreplace->$key($webQuery, $key) . "\n";
    });

    # ファイルに書き込む
    output_file($path, $parsed_strings);
}

sub output_file {
    my ($path, $parsed_strings) = @_;

    my $outPath = decode(locale_fs => $path); # $path はバイナリデータなので文字列にdecode
    $outPath =~ s|(?=\.[^\.]+$)|_IndTag|;     # で、ファイル名を書き換え。
    # タグ付きテキストはshift-jisでないと上手く動かないらしいので。
    open my $out, '>', $outPath;
    print $out encode(shift_jis => $parsed_strings);

    # Automator用に出力する場合はエンコードすると文字化けする
    say qq/ファイルの変換が完了しました。\n"$outPath" に保存されています。/;
}

