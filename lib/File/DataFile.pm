package File::DataFile;

use strict;
use warnings;

sub new {
    my $self = bless {}, shift;
    $self->{file} = shift;
    return $self;
}

sub file {
    return $_[0]->{file};
}

# data is a HASH, ARRAY or SCALAR ref
sub data {
    return $_[0]->{data};
}

sub reset {
    my $self = shift;
    my $ref = $self->{data};
    return unless $ref;

    if (UNIVERSAL::isa($ref, 'HASH')) {
        %$ref = ();
    } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {
        @$ref = ();
    } elsif (UNIVERSAL::isa($ref, 'SCALAR')) {
        $$ref = "";
    } else {
        die "Type error";
    }
}

sub isEmpty {
    my $self = shift;
    my $ref = $self->{data};
    return unless $ref;

    if (UNIVERSAL::isa($ref, 'HASH')) {
        return keys %$ref == 0;
    } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {
        return @$ref == 0;
    } elsif (UNIVERSAL::isa($ref, 'SCALAR')) {
        return $$ref ne "";
    } else {
        die "Type error";
    }
}

sub read {}
sub write {}

1;
