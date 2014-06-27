package Swatch {
    use strict;
    use warnings;
    use feature qw/say switch/;
    use utf8;
    use autodie;
    use Carp qw/confess croak/; # confessはスタックトレース付き

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

        my @definde_swatch;         # 定義済みのスウォッチの読み込み
        my @undef_swatch = ();      # 未定義のスウォッチ
        for my $elem (@uniq_classes) {
            # 未定義のスウォッチの抽出
            push @undef_swatch => $elem unless grep {$_ eq $elem} @definde_swatch;
        }
    }

    sub write_swatch {

    }

    sub import_switch {

    }

    sub define_swatch {

    }

    1;
}

