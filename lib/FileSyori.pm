package FileSyori {
    use strict;
    use warnings;
    use feature qw/say switch/;
    use utf8;
    use autodie;
    use Carp qw/confess croak/; # confessはスタックトレース付き

    use Text::Markdown::Discount qw/markdown/;
    use YAML qw/Load/;
    use List::AllUtils qw/uniq/;
    use Encode qw/encode decode/;

    use FindBin;
    use lib $FindBin::Bin;
    use TagReplace;
    my $tagreplace = new TagReplace;

    sub new {
        my $class = shift;
        my $args = ref $_[0] ? $_[0] : +{@_};
        bless $args, $class;
        return $args;
    }


    sub new_style_yaml {
        my $self = shift @_;
        return "$FindBin::Bin/new_style.yaml";
    }


    sub process_file_henkan {
        my ($self, $path, $ishtml) = @_;
        my $wq = $self->yomikomi($path, $ishtml);
        my $parsed_strings = _create_parsed_strings($wq);

        # ファイルに書き込む
        _output_file($path, $parsed_strings);
    }

    sub open_new_style {
        my $self = shift @_;
        open my $in_newstyles, '<:utf8', $self->new_style_yaml;
        my $new_styles = Load(do {local $/; <$in_newstyles>});
        return $new_styles;
    }

    sub marge_style {
        # 設定ファイル「new_style.yaml」の定義スタイルとのマージ
        my $self = shift @_;
        my $new_styles = $self->open_new_style;
        $tagreplace->danraku_style_marge($new_styles->{danraku});
        $tagreplace->moji_style_marge($new_styles->{moji});
    }


    sub yomikomi {
        my ($self, $path, $is_html) = @_;
        # 変換するファイルを読み込む
        open my $in, '<:utf8', $path;
        my $markdown = do { local $/; <$in> };
        my $html = '';
        if ($is_html or $path =~ m/\.html?$/) {
            $html = $markdown;
        }
        else {
            $html = markdown($markdown) . "\n";
        }

        # 改行をそのまま残すためにこのように動作させています。
        my $tree = HTML::TreeBuilder->new;
        $tree->no_space_compacting(1);
        my $wq = Web::Query->new_from_element($tree->parse($html));

        return $wq;
    }


    sub _create_parsed_strings {
        my $wq = shift @_;

        # 出力するファイルの1行目にヘッダーを挿入
        my $parsed_strings = $tagreplace->header . "\n";

        # Markdownを解析してInDesignタグ付きテキストに変換
        $wq->find('body')->contents->each(sub {
            my (undef, $webQuery) = @_;

            # $key はタグの名前。なんで $key という名前をつけてしまったのか...
            my ($key) = $webQuery->as_html =~ m/^<(.+?)[\s>]/;
            # $key で TagReplace のメソッドを動的に呼び出し
            $parsed_strings .= $tagreplace->$key($webQuery, $key) . "\n";
        });
        return $parsed_strings;
    }


    sub _output_file {
        my ($path, $parsed_strings) = @_;

        my $outPath = decode(locale_fs => $path); # $path はバイナリデータなので文字列にdecode
        $outPath =~ s|(?=\.[^\.]+$)|_IndTag|;     # で、ファイル名を書き換え。
        # タグ付きテキストをUnicodeで利用するには「utf-16le」でエンコード。
        open my $out, '>', $outPath;
        print $out encode("utf-16le" => $parsed_strings);

        # Automator用に出力する場合はエンコードすると文字化けする
        say qq/ファイルの変換が完了しました。\n"$outPath" に保存されています。/;
    }

    1;
}

