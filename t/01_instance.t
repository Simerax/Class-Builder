use strict;
use warnings;

use Test::More tests => 1;
use autodie;


package A;
use Class::Builder qw(has);

has {
    var => 'a',
    is => 'rw',
};

no Class::Builder;
package main;

my $instance = A->new();

ok(ref($instance) eq 'A');
