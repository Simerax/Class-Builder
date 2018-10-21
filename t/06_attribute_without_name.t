use Test::More tests => 1;
use autodie;


my $fail = eval {
    package A;
    use Class::Builder qw(has);
    has {
        is => 'rw',
    };
    no Class::Builder;
    package main;

    my $a = A->new();
};

ok($fail eq undef);
