package File::JSON;
use parent 'File::DataFile';

use strict;
use warnings;
use JSON;
use Try::Tiny;

use Exception::Class (
    'Exception',
    'File::JSON::Exception' =>
        { isa => 'Exception' },
);

my $json = JSON->new
    ->allow_nonref      # Convert a non-reference into its corresponding string,
                        # number or null JSON value
    ->convert_blessed   # Upon encountering a blessed object, will check for the
                        # availability of the TO_JSON method on the object's class.
                        # If found, it will be called in scalar context and the
                        # resulting scalar will be encoded instead of the object.
    ->canonical         # Output JSON objects by sorting their keys. This is adding
                        # a comparatively high overhead.
    ->pretty;           # Generate the most readable (or most compact) form possible.

sub read {
    my ($self, $file) = @_;
    $file //= $self->{file};

    $self->{data} = {};

    return $self unless -e $file;
    throw File::JSON::Exception("Not a file: $file") unless -f $file;
    return $self if -z $file;

    local $/; # slurp entire file
    open my $fh, '<', $file
        or throw File::JSON::Exception("$!: $file");

    try {
        $self->{data} = $json->decode(<$fh>);
    } catch {
        throw File::JSON::Exception(shift);
    };

    close $fh;

    return $self;
}

sub write {
    my ($self, $file) = @_;
    $file //= $self->{file};

    throw File::JSON::Exception("Not a file: $file")
        unless !-e $file || -f $file;

    open my $fh, '>', $file
        or throw File::JSON::Exception("$!: $file");

    try {
        print $fh $json->encode($self->{data});
    } catch {
        throw File::JSON::Exception(shift);
    };

    close $fh;

    return $self;
}

1;
