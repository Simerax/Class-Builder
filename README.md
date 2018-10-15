# Class-Builder
A small Package to make setting up a Class in Perl easier and less tedious.

## 1.0 What does it do?

This Package creates Setters & Getters for your Class Attributes (you can also set constraints on the setter).
It creates a 'new' method automatically to initalize the Object for you. No need for you to write your own Constructor (You can still execute custom code during initalization. More on that in 1.2).
It makes your Class Object 'Read Only' and only unlocks it if you change values via a setter.

## 1.1 How to create an Attribute?


    package MyClass;

    use Class::Builder qw(has);

    has {
        var => 'MyAttribute', # Name of the Attribute
        is => 'rw', # It's a read & write Attribute; could also be 'ro' which is read only
        
        # Making a Custom Constraint. When a Setter is called this code is executed.
        # $value is the 'new' value of your Attribute.
        constraint => sub {
            my ($value) = @_;

            if ($value > 0) { 
                return $value; # Only Accept the value if its greater 0
            } else {
                return undef; # Otherwise we give undef to indicate that we dont want to change the value and keep the old one
            }
        };
    };

## 1.2 Automatic Constructor?

As soon as you create your first Attribute via 'has' there will be a constructor (named 'new') created for you.
This Constructor will handle all the initalization of Attributes for you.
It Expects a Hash Reference as Parameters and then maps the name of the keys to your attributes (Case Sensitive!) and calls the setter of it.

**But what about the stuff I need to initalize myself?**
After the Initalization of the given Attributes, it will check for a '__construct' method in your Class. If it finds it it will execute that and give you the Object Reference as Parameter.

    package MyClass;

    use Class::Builder qw(has);

    # the constructor will only be added if you have an attribute
    has {
        # ...
    };


    sub __construct {
        my ($self) = @_; # All Attributes Initalized & blessed

        # do more important initialization
    }


## Bugs Problems and Current Status

This Module is in a **very** early state. Dont expect flawless Functionality. There are still plenty of bugs.


## Todo
- Add Default Initalization value if there is none given in the constructor
- Change the Behaviour of 'constraint' in 'has' to allow undefined values (currently there is no way to undef your value)

