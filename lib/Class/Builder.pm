package Class::Builder;

our $VERSION = '0.00.10';

use Hash::Util qw(lock_value unlock_value);


use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = ();
    @EXPORT_OK = qw(has);


    %EXPORT_TAGS = (
        CONSTANTS => [
            qw(
                RW
                RO
            )
        ]
    );

    Exporter::export_ok_tags(
        qw(
            CONSTANTS
        )
    );
}

use constant {
    RW => 'rw',
    RO => 'ro',
};


use strict;

my ($parent) = caller;
my @ro_attributes;


sub has {
    my ($attribute) = @_;

    my $attribute_name = $attribute->{'var'};
    my $attribute_constraint = $attribute->{'constraint'};
    my $is_rw = $attribute->{'is'};


    # Make sure there is a valid Accessor name
    if (!$attribute_name) {
        use Carp;
        croak "Attributes are required to have a name. Set 'var' in your Attribute Definition.";
    } else {
        if ($attribute_name !~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
            use Carp;
            croak "Illegal attributename '$attribute_name'. Attributes are only allowed to have A-Z, a-z, _, 0-9.";
        }
    }

    # Check accessor type (rw/ro)
    if (!$is_rw) {
        $is_rw = 1; # If not specified we create a read/write accessor
    } else {
        if ($is_rw !~ /^r[wo]$/i) {
            use Carp;
            croak "Attribute can only be 'read only' or 'read write' (ro/rw) not '$is_rw'";
        } else {
            lc($is_rw);
            $is_rw = 
                $is_rw eq 'rw'
                ? 1 
                : 0;
        }
    }

    my $sub;
    if ($is_rw) {
        $sub = _rw_accessor($attribute_name, $attribute_constraint);
    } else {
        $sub = _ro_accessor($attribute_name);
        push @ro_attributes, $attribute_name;
    }
    

    no strict 'refs';
    *{$parent .'::'.$attribute_name} = $sub;
    *{$parent .'::new'} = _constructor();
    use strict;
}

sub _rw_accessor {
    my ($attribute_name, $attribute_constraint) = @_;

    return sub {
        my $self = shift;

        if (@_) {
            unlock_value(%$self, $attribute_name);
            # Accessor hat einen Constraint
            if (ref($attribute_constraint) eq 'CODE') {
                my $ok = $attribute_constraint->($_[0]);
                if ($ok) {
                    $self->{$attribute_name} = $ok;
                }
            } else {
                $self->{$attribute_name} = $_[0];
            }
        }
        lock_value(%$self, $attribute_name);
        return $self->{$attribute_name};
    };
}

sub _ro_accessor {
    my ($attribute_name) = @_;

    return sub {
        my $self = shift;
        warn "Accessor $attribute_name is read only" if (@_);
        lock_value(%$self, $attribute_name);
        return $self->{$attribute_name};
    };
}


sub _constructor {
    
    return sub {
        my ($class, $args) = @_;

        my $self = {};
        bless $self, $class;

        # Run the appropriate setter foreach argument at $args
        foreach(keys %$args) {

            my $is_ro = 0;

            foreach my $ro (@ro_attributes) {
                if ($_ eq $ro) {
                    $is_ro = 1;
                    last;
                }
            }

            # if a Attribute is Read Only we will set it directly in the constructor.
            # Calling the "setter" on it wont do anything since its just a getter
            if ($is_ro) {
                unlock_value(%$self, $_);
                $self->{$_} = $args->{$_};
                lock_value(%$self, $_);
            } else {# read write attribute
                if (exists &{$parent.'::'.$_}){
                    my $setter = \&{$parent.'::'.$_};
                    $setter->($self, $args->{$_});
                }
            }
        }

        # Call Custom Constructor
        if (exists &{$parent.'::__construct'}) {
            _unlock_all_values($self);
            my $constructor = \&{$parent.'::__construct'};
            $constructor->($self);
            _lock_all_values($self);
        }

        return $self;
    };
}

# Unlocks all Values of a hashref $hash
#
sub _unlock_all_values {
    my ($hash) = @_;

    foreach(keys %$hash) {
        unlock_value(%$hash, $_);
    }
}

# locks all values of a hashref $hash
#
sub _lock_all_values {
    my ($hash) = @_;

    foreach(keys %$hash) {
        lock_value(%$hash, $_);
    }
}


1;