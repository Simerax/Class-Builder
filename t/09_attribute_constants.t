use strict;
use warnings;

use Test::More tests => 3;
use autodie;


package A;
use Class::Builder qw(has :CONSTANTS);
has {
    var => 'a',
    is => Class::Builder::RW,
};

has {
    var => 'b',
    is => RO,
};


no Class::Builder;
package main;

my $a = A->new({
    a => 20,
    b => 25
});

ok($a->a() eq 20);
ok($a->b() eq 25);
ok($a->b(5) eq 25);
