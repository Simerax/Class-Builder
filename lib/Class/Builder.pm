=head1 NAME

Class::Builder - A small Package to make setting up a Class in Perl easier and less tedious.

=head1 SYNOPSIS

    package MyClass;

    use Class::Builder qw(has :CONSTANTS);

    # Create a new Attribute for MyClass with the Name 'abc'
    has {
        var => 'abc',
        is => RW,   # its ReadWrite

        # we only want values that are greater 0
        constraint => sub {
            my $value = shift;
            if ($value > 0) {
                return $value;
            } else {
                return undef;
            }
        }
    };

    # ...

    use MyClass;

    my $instance = MyClass->new({
        abc => 25,
    });

    $instance->abc(19);

=head1 DESCRIPTION

This Package creates Setters & Getters for your Class Attributes as well as a 'new' Method automatically.
Your Class is also being forced to use the Setters & Getters. Direct access like C<$self-E<gt>{a} = 5> is not possible.
Your Class Attributes are locked via L<Hash::Util>'s 'lock_value' and can only be manipulated with the appropriate Setter.

=head2 Functions

=head3 has({})

This Function is the core of this Module.
Everything is done within this Function, except for custom Constructors (but those are only used if there is at least one C<has>).

=head4 Parameters

=over 4

=item var

Mandatory Key. This specifies the Name of your attribute.

=item is

Type of your Attribute. Will default to C<READ_WRITE> if not given.

=item constraint

Here you can specify custom validation of your values when they are being set (or tried to being set).
This needs to be a Code-Reference.

=back

=head2 Custom Constructor

If you have at least created one Attribute via C<has>, L<Class::Builder> will call the Function C<__construct> inside the Package it was used.
This Function gets the unlocked Class Instance C<$self> as Parameter. You can freely manipulate your Object inside this Method. 

    package MyClass;

    use Class::Builder qw(has);

    has {
        var => 'abc',
    };

    sub __construct {
        my ($self) = @_;

        $self->{'abc'} = 50; # totally legal here you can bypass the Setter if you want.
    }

=head2 Exports

Nothing is exported by L<Class::Builder> by default. You have to import whatever you need by yourself. 
This is because most functions/Constants in this module are very short and there is a great chance of overlapping.



=head3 Functions

The Function you will use in every Project is C<has>. You will usally import it like so:

    use Class::Builder qw(has);

=head3 Constants

You can import Attribute Type Constants

    use Class::Builder qw(:CONSTANTS);

These will give you


=over 2

=item RO and READ_ONLY

Read-Only Attribute Type

    has {
        var 'a',
        is => READ_ONLY # or short RO
    };

=item RW and READ_WRITE

Read & Write Attribute Type

    has {
        var 'a',
        is => READ_WRITE # or short RW
    };

=back

=cut




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
                READ_WRITE
                RO
                READ_ONLY
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
    READ_WRITE => RW,
    RO => 'ro',
    READ_ONLY => RO,
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