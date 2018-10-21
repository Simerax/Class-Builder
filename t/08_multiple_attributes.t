use strict;
use warnings;

use Test::More tests => 2;
use autodie;


package A;
use Class::Builder qw(has);
has {
    var => 'a',
    is => 'rw',
};

has {
    var => 'b',
    is => 'ro',
};


no Class::Builder;
package main;

my $a = A->new({
    a => 20,
    b => 25
});

ok($a->a() eq 20);
ok($a->b() eq 25);
