=begin TML

---+ package MPC::Snapshot

=cut

package MPC::Snapshot;

use strict;
use warnings;
use DateTime;
use Win32;

###############################################################################
=pod

---++++ imageFile([$imageFile]) -> $imageFile
---++++ file([$file]) -> $file
---++++ position([$position]) -> $position
---++++ takenDateTime([$takenDateTime]) -> $takenDateTime
---++++ taken([$taken]) -> $taken

=cut
###############################################################################

use Class::AccessorMaker {
    imageFile => "",
    file => "",
    position => "",
    takenDateTime => "",
    taken => "",
}, "no_new";

###############################################################################
=pod

---++ Object creation

---+++ new($imageFile) -> $snapshot
Returns a new =MPC::Snapshot= object.

=cut
###############################################################################

sub new {
    my $self = bless {}, shift;
    $self->{imageFile} = shift;
    $self->{imageFile} =~
        /(.+)_snapshot_([\d\.]+)_\[(\d+)\.(\d+)\.(\d+)_(\d+)\.(\d+)\.(\d+)\]\./
        || return;

    $self->{file} = $1;
    $self->{position} = $2;

    $self->{takenDateTime} = new DateTime(
        year       => $3,
        month      => $4,
        day        => $5,
        hour       => $6,
        minute     => $7,
        second     => $8,
        time_zone  => 'Europe/Amsterdam',
    );
    $self->{taken} = $self->{takenDateTime}->epoch;

    my $c = $self->{position} =~ s/\./:/g;
    $self->{position} = "00:$self->{position}" if $c == 1;

    return $self;
}

###############################################################################
=pod

---+++ GetSnapshots($dirpath) -> \@snapshots or %snapshots
   * =$dirpath= - can be a string containing the path to the dir to read
                  filenames from or or a reference to an array of filenames.
   * =@snapshots= - List of =MPC::Snapshot= objects.
   * =%snapshots= - =MPC::Snapshot= objects hashed by filename.

=cut
###############################################################################

sub GetSnapshots {
    my ($dirpath) = @_;
    my @snapshots;

    my @files;
    if (ref $dirpath) {
        @files = @$dirpath;
    } else {
        opendir D, $dirpath or die "$!";
        @files = grep { -f "$dirpath\\$_" } readdir D;
        closedir D;
    }

    foreach my $file (@files) {
        my $filename = $file;
        my $longname;
        if (!ref $dirpath) {
            $longname = Win32::GetLongPathName("$dirpath\\$file");
            if ($longname) {
                $longname =~ s/.*\\//;
                $filename = $longname;
            }
        }
        next if $filename !~ /_snapshot_/;

        my $snapshot = new MPC::Snapshot($filename);
        if ($snapshot) {
            $snapshot->{longname} = $longname;
            $snapshot->{name} = $file;

            push @snapshots, $file if wantarray;
            push @snapshots, $snapshot;
        } else {
            warn "Invalid filename: $file";
        }
    }

    return wantarray ? @snapshots : \@snapshots;
}

1;
