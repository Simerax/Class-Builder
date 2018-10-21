use strict;
use warnings;

use Test::More tests => 2;
use autodie;

package A;
use Class::Builder qw(has);

has {
    var => 'a',
    is => 'ro',
};

no Class::Builder;
package main;

my $a = A->new({
    a => 25
});

ok($a->a(5) eq 25);

if(eval { $a->{'a'} = 25 }) {
    fail("can change Class Attributes directly");
} else {
    pass("can't change Class Attributes directly");
}