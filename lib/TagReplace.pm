package TagReplace {
    use strict;
    use warnings;
    use feature qw/say/;
    use utf8;
    use autodie;

    use Web::Query q/wq/;
    use Text::Markdown::Discount q/markdown/;
    use HTML::Entities qw/decode_entities encode_entities/;

    sub new {
        my $class = shift;
        my $args = ref $_[0] ? $_[0] : +{@_};
        bless $args => $class;
        return $args;
    }

    my %henkan_danraku = (
        h1     => '大見出し',
        h2     => '中見出し',
        # h3     => '小見出し',
        # h4     => 'コラム見出し',
        p      => '本文',
        # ul     => {li => '箇条書き'},
        # ol     => {li => '箇条書き-no'},
        # th     => '表-見出し行',
        # td     => '表-行',
        # code   => 'コード',
        # column => {h4 => 'コラム見出し', p => 'コラム'},
    );

    my %henkan_moji = (
        # strong => '強調',
        # em     => '斜体',
        # code   => 'コードインライン',
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
        # return $^O eq 'darwin' ? '<SJIS-MAC>' : '<SJIS-WIN>';
        return $^O eq 'darwin' ? '<UNICODE-MAC>' : '<UNICODE-WIN>';
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
        my $class_name = $webQuery->attr('class');
        if (lc $class_name eq 'column') {
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
        for my $line (split "\n" => $webQuery->html) {
            push @code_line => replace($henkan_danraku{code}, $line);
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
            # unless (exists $henkan_moji{$tag}) {
            #     die sprintf 'Please set value %%henkan_moji. Undef key($tag) is "%s"', $tag;
            # }
            $html_entities =~ s{<$tag>(.+?)</$tag>}
                    {<CharStyle:$henkan_moji{$tag}>$1<CharStyle:>}g;
        }
        $html_entities =~ s/<br>/\n/g;
        $html_entities =~ s/(?=&[gl]t;)/\\/g;
        my $content = decode_entities($html_entities);
        return "<ParaStyle:$tagname>$content";
    }

    1;
}

