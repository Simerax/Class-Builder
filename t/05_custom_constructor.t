use strict;
use warnings;

use Test::More tests => 1;
use autodie;

package A;
use Class::Builder qw(has);

has {
    var => 'a',
    is => 'ro',
};

sub __construct {
    my ($self) = @_;

    $self->{'a'} = 5;
}

no Class::Builder;
package main;

my $a = A->new({
    a => 25
});

ok($a->a() eq 5);
