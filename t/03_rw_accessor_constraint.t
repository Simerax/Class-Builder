# use strict;
# use warnings;

use Test::More tests => 4;
use autodie;

package A;
use Class::Builder qw(has);

has {
    var => 'a',
    is => 'rw',
    constraint => sub {
        my $value = shift;
        if ($value > 0) {
            return $value;
        } else {
            return undef;
        }
    }
};

no Class::Builder;
package main;

my $a = A->new({
    a => 25
});

ok($a->a(-2) eq 25);
ok($a->a(5) eq 5);

$a = A->new({
    a => -3
});

ok($a->a() eq undef);
ok($a->a(5) eq 5);
