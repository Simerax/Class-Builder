use strict;
use warnings;

use Test::More tests => 3;
use autodie;


package A;
use Class::Builder qw(has);

has {
    var => 'a',
    is => 'rw',
};

no Class::Builder;
package main;

my $a = A->new({
    a => 25
});

ok($a->a eq 25);
ok($a->a(30) eq 30);

if(eval { $a->{'a'} = 25 }) {
    fail("can change Class Attributes directly");
} else {
    pass("can't change Class Attributes directly");
}
