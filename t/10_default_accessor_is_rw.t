use strict;
use warnings;

use Test::More tests => 2;
use autodie;


package A;
use Class::Builder qw(has);
has {
    var => 'a'
};


no Class::Builder;
package main;

my $a = A->new({
    a => 20
});

ok($a->a() eq 20);
ok($a->a(25) eq 25);