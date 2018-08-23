package MPC::SnapshotMonitor;

use strict;
use warnings;
use MPC::Snapshot;
use MPC::WebIFMonitor;
use ProcessList;

use Class::AccessorMaker {
    snapshotDir => undef,
    workingDir => undef,
    port => undef,
    url => undef,
    requestAgent => undef,
    requestTimeout => undef,
    offlineTimeout => undef,
};

sub init {
    my $self = shift;

    $self->reset;

    $self->{webIFMon} = new MPC::WebIFMonitor(
        port => $self->{port},
        url => $self->{url},
        requestAgent => $self->{requestAgent},
        requestTimeout => $self->{requestTimeout},
        offlineTimeout => $self->{offlineTimeout},
    )->init;

    return $self;
}


sub reset {
    my $self = shift;
    %{$self->{prevSnapshots}} =
        MPC::Snapshot::GetSnapshots($self->{snapshotDir});
}

sub getStatus {
    my $self = shift;
    $self->{webIFMon}->getStatus;
}

sub poll {
    my ($self, $newSnapshotCallback) = @_;
    my %snapshots = MPC::Snapshot::GetSnapshots($self->{snapshotDir});
    while (my ($file, $ss) = each %snapshots) {
        next if $self->{prevSnapshots}{$file};
        $newSnapshotCallback->($self->getSnapshotInfo($ss));
    }
    $self->{prevSnapshots} = \%snapshots;
}

sub getSnapshotInfo {
    my ($self, $snapshot) = @_;

    my $ssInfo = {
        dir => undef,
        image => $snapshot->imageFile,
        file => $snapshot->file,
        path => undef,
        taken => $snapshot->taken,
        status => undef,
    };

    # lookup file path and dir

    # file in working directory
    if (-e "$self->{workingDir}\\$ssInfo->{file}") {
        $ssInfo->{path} = "$self->{workingDir}\\$ssInfo->{file}";
        $ssInfo->{dir} = $self->{workingDir};

    # file in dir in dir history
    } elsif ($ssInfo->{dir} = $self->lookupInDirHistory($ssInfo->{file})) {
        $ssInfo->{path} = "$ssInfo->{dir}\\$ssInfo->{file}";

    # get path from window title listed in process list
    } elsif (my @procs = ProcessList::GetProcessList("^mpc")) {
        foreach my $proc (@procs) {
            #~ print "$proc->{WindowTitle}\n" if $opts{verbose};
            if ($proc->{WindowTitle} =~ /\Q$ssInfo->{file}\E$/) {
                warn "Multiple matches" if $ssInfo->{path};
                $ssInfo->{path} = $proc->{WindowTitle};
                $ssInfo->{dir} = $proc->{WindowTitle};
                $ssInfo->{dir} =~ s/\\\Q$ssInfo->{file}\E$//;
            }
        }
    }

    # get status info using web interface
    if ($ssInfo->{status} = $self->{webIFMon}->getStatus) {
        unless ($ssInfo->{path}) {
            $ssInfo->{path} = $ssInfo->{status}{filepath};
            print "$ssInfo->{path}\n";
            print "$ssInfo->{file}\n";
            if ($ssInfo->{path} =~ /\Q$ssInfo->{file}\E$/) {
                $ssInfo->{dir} = $ssInfo->{status}{filedir};
            }
        }
    }

    if ($ssInfo->{dir}) {
        $self->addToDirHistory($ssInfo->{dir});
    }

    return $ssInfo;
}

sub addToDirHistory {
    my ($self, $dir) = @_;
    $self->{dirHistory}{$dir} = 1;
}

sub lookupInDirHistory {
    my ($self, $file) = @_;
    foreach my $dir (keys %{$self->{dirHistory}}) {
        return $dir if -e "$dir/$file";
    }
    return undef;
}

1;
