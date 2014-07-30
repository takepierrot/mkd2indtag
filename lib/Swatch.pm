package Swatch;
use strict;
use warnings;
use feature qw/say switch/;
use utf8;
use autodie;
use Carp qw/confess croak/; # confessはスタックトレース付き
use List::AllUtils qw/uniq/;
use FindBin;
use lib $FindBin::Bin;
use FileSyori;
use YAML;
use DDP;

my $file_serve = new FileSyori;

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : +{@_};
    bless $args => $class;
    return $args;
}


sub create_swatch_profile {
    my ($self, $wq) = @_;
    my @class_names = ();
    $wq->find('span')->each( sub {
            push @class_names => $_->attr('class');
        });
    my @uniq_classes = uniq(@class_names);

    # 定義済みのスウォッチの読み込み
    my $defined_swatch = $self->get_defined_swatch;
    my @undef_swatch = ();      # 未定義のスウォッチ
    my $swatch_list = $self->get_swatch_list; # スウォッチの定義リスト
    for my $elem (@uniq_classes) {
        # 未定義のスウォッチの抽出
        push @undef_swatch => $elem unless grep {$_ eq $elem} keys %$defined_swatch;
    }
    my %new_swatch = map {$_ => $swatch_list->{$_}} @undef_swatch;
    my %kakikomi = (%$defined_swatch, %new_swatch);
    $self->write_swatch_to_yaml(\%kakikomi);
}

sub write_swatch_to_yaml {
    my ($self, $kakikomi) = @_;
    my $style = $self->style;
    $style->{defined_swatch} = $kakikomi;
    my $yaml = YAML::Dump($style);
    open my $out, '>:utf8', $file_serve->new_style_yaml;
    print $out $yaml;
}

sub write_swatch_to_profile {
    my $self = shift @_;
    my $defined_swatch = $self->get_defined_swatch;
    my @list = ();
    for my $name (keys %$defined_swatch) {
        my $elem = $defined_swatch->{$name};
        my $swatch = sprintf '<%s:COLOR:CMYK:Process:%s,%s,%s,%s>',
                $name, $elem->{C}, $elem->{M}, $elem->{Y}, $elem->{K};
        push @list => $swatch;
    }
    my $swatch_profile = '<ctable:=' . join('' => @list)   . '>';
    open my $out, '>:utf8', "$FindBin::Bin/new_swatch_profile.txt";
    print $out $swatch_profile;
}

sub get_swatch_list {
    my $self = shift @_;
    my $str = do { local $/; <DATA> };
    my $swatch_list = Load($str);
    return $swatch_list->{swatch_list};
}

sub get_defined_swatch {
    my $self = shift @_;
    unless ($self->style) {
        my $new_styles = $file_serve->open_new_style;
        $self->style($new_styles);
    }
    my $style = $self->style;
    return $style->{defined_swatch};
}

sub style {
    my ($self, $new_styles) = @_;
    $self->{style} = $new_styles if $new_styles;
    return $self->{style};
}

1;

__DATA__
swatch_list :
    addition:
        C: 0.9
        K: 0.4
        M: 0.45
        Y: 0
    attribute:
        C: 0.8
        K: 0.2
        M: 0
        Y: 0.4
    body:
        C: 0
        K: 0.4
        M: 0
        Y: 0.1
    built_in:
        C: 0.3
        K: 0
        M: 0.8
        Y: 0
    cdata:
        C: 0.6
        K: 0
        M: 0.6
        Y: 0.9
    change:
        C: 0.3
        K: 0.5
        M: 0
        Y: 0.6
    chunk:
        C: 0.2
        K: 0
        M: 0.5
        Y: 0.7
    class:
        C: 0
        K: 0.75
        M: 0.5
        Y: 0
    clojure:
        C: 0
        K: 0.5
        M: 0.4
        Y: 0.8
    command:
        C: 0.1
        K: 0.1
        M: 0.4
        Y: 0
    comment:
        C: 0.2
        K: 0
        M: 0.2
        Y: 0.8
    constant:
        C: 0.35
        K: 0.2
        M: 0.7
        Y: 0
    css:
        C: 0.1
        K: 0.5
        M: 0
        Y: 0.2
    deletion:
        C: 0.4
        K: 0
        M: 0.2
        Y: 0.7
    diff:
        C: 0.4
        K: 0
        M: 0.2
        Y: 0.5
    django:
        C: 0
        K: 0.4
        M: 0
        Y: 0
    doctype:
        C: 0
        K: 0.2
        M: 0.4
        Y: 0.1
    formula:
        C: 0.4
        K: 0
        M: 0.1
        Y: 0.3
    haskell:
        C: 0.1
        K: 0
        M: 0
        Y: 0.4
    header:
        C: 0.2
        K: 0
        M: 0.4
        Y: 0.8
    hen:
        C: 0.5
        K: 0
        M: 0.5
        Y: 0.8
    hexcolor:
        C: 0.4
        K: 0.2
        M: 0
        Y: 0.8
    id:
        C: 0.1
        K: 0
        M: 0.2
        Y: 0
    javascript:
        C: 0.2
        K: 0
        M: 0.1
        Y: 0.8
    keyword:
        C: 0.3
        K: 0
        M: 0.8
        Y: 0.5
    lisp:
        C: 0
        K: 0.75
        M: 0.1
        Y: 0.4
    literal:
        C: 0.8
        K: 0
        M: 0.5
        Y: 0.7
    number:
        C: 0
        K: 0.1
        M: 0
        Y: 0.4
    phpdoc:
        C: 0
        K: 0.2
        M: 0.6
        Y: 0.1
    pi:
        C: 0
        K: 0.4
        M: 0.1
        Y: 0.5
    preprocessor:
        C: 0
        K: 0.2
        M: 0.5
        Y: 0
    prompt:
        C: 0
        K: 0
        M: 0.3
        Y: 0.4
    property:
        C: 0.1
        K: 0
        M: 0.7
        Y: 0.9
    regexp:
        C: 0
        K: 0.5
        M: 0
        Y: 0.1
    request:
        C: 0.7
        K: 0
        M: 0
        Y: 0
    rule:
        C: 0.4
        K: 0
        M: 0.1
        Y: 0.1
    rules:
        C: 0.7
        K: 0
        M: 0.9
        Y: 0
    shebang:
        C: 0
        K: 0.3
        M: 0.2
        Y: 0.4
    special:
        C: 0.1
        K: 0.75
        M: 0
        Y: 0.1
    status:
        C: 0.4
        K: 0
        M: 0.5
        Y: 0.5
    string:
        C: 0
        K: 0.2
        M: 0.4
        Y: 0
    subst:
        C: 0.1
        K: 0.4
        M: 0
        Y: 0
    symbol:
        C: 0.4
        K: 0.1
        M: 0
        Y: 0.4
    tag:
        C: 0.9
        K: 0.75
        M: 0
        Y: 0.1
    template_comment:
        C: 0
        K: 0
        M: 0.6
        Y: 0.9
    tex:
        C: 0
        K: 0.75
        M: 0.8
        Y: 0.1
    title:
        C: 0.1
        K: 0.3
        M: 0.2
        Y: 0
    type:
        C: 0.9
        K: 0
        M: 0.8
        Y: 0.8
    value:
        C: 0
        K: 0.2
        M: 0.1
        Y: 0
    variable:
        C: 0.2
        K: 0
        M: 0.3
        Y: 0.6
    winutils:
        C: 0.15
        K: 0.75
        M: 0.3
        Y: 0

