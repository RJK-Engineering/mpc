package MPC::Playlist;

use strict;
use warnings;

use List;

my $firstline = "MPCPLAYLIST";

sub new {
    my $self = bless {}, shift;
    $self->{list} = new List;
    $self;
}

sub add {
    my ($self, $path, $label) = @_;
    $self->{list}->add({
        path => $path,
        label => $label,
    });
}

# File::List delegates
sub entries { $_[0]{list}->entries; }
sub clear   { $_[0]{list}->clear; }
sub isEmpty { $_[0]{list}->isEmpty; }
sub size    { $_[0]{list}->size; }
sub shuffle { $_[0]{list}->shuffle; }

sub load {
    my ($self, $file) = @_;
    $self->append($file);
}

sub append {
    my ($self, $file) = @_;
    open(F, "<$file") || return;

    my @lines = <F>;
    if ((shift @lines) !~ /$firstline/) {
        return;
    }
    foreach (@lines) {
        if ($_ =~ /^(\d+),filename,(.+)/) {
            $self->add($2);
        } elsif ($_ =~ /^(\d+),type,(.+)/) {
        } else {
            print "Unexpected line: $_";
        }
    }
    return close F;
}

sub write {
    my ($self, $out) = @_;
    return if $self->{list}->isEmpty;

    open(my $fh, ">:encoding(utf8)", $out) || die "Could not open $out";
    print $fh $firstline."\n";

    my $num = 1;
    foreach ($self->{list}->entries) {
        printf $fh "%s,type,0\n", $num;
        printf $fh "%s,label,%s\n", $num, $_->{label} if defined $_->{label};
        printf $fh "%s,filename,%s\n", $num++, $_->{path};
        if ($self->{writeDetails}) {
            printf $fh "%s,filesize,%s\n", $num++, $_->{size} if defined $_->{size};
        }
    }
    close $fh;
}

1;
