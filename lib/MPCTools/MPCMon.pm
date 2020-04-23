package MPCTools::MPCMon;

use strict;
use warnings;

use Exception::Class('Exception');
use Try::Tiny;

use Cwd qw(getcwd);
use File::Copy qw(move);
use File::Path qw(make_path);
use Number::Bytes::Human qw(format_bytes);
use Win32::Clipboard;

use File::JSON;
use Interactive qw(Ask ReadLine Confirm);
Interactive::SetClass('Term::ReadKey');

#~ use MPC::Playlist;
use MPC::SnapshotMonitor;
use ProcessList;

sub new {
    my $self = bless {}, shift;
    return $self;
}

sub init {
    my $self = shift;
    $self->{opts} = shift;

    if ($self->{opts}{statusFile}) {
        $self->{statusFile} = new File::JSON($self->{opts}{statusFile})->read;
        $self->{status} = $self->{statusFile}->data;
    }

    $self->checkExistingLock();
    $self->createLock();

    $self->setupMonitors();

    $self->{clipboard} = Win32::Clipboard();

    return $self;
}

sub poll {
    my $self = shift;
    $self->{snapshotMon}->poll(sub { $self->newSnapshot(@_) });
}
sub finish {
    my $self = shift;
    unlink $self->{opts}{lockFile} if $self->{opts}{lockFile};
}

sub checkExistingLock {
    my $self = shift;
    if (-e $self->{opts}{lockFile}) {
        open my $fh, '<', $self->{opts}{lockFile} or die "$!: $self->{opts}{lockFile}";
        my $pid = <$fh>;
        chomp $pid;
        close $fh;

        my $proc = ProcessList::GetPid($pid);
        if ($proc) {
            print "$0 is already running.\n" unless $self->{opts}{quiet};
            undef $self->{opts}{lockFile}; # do not remove file when calling finish()
            exit 1;
        } else {
            print "$0 was not closed properly, old lock file found.\n" unless $self->{opts}{quiet};
        }
    }
}

sub createLock {
    my $self = shift;

    my $dir = $self->{opts}{lockFile} || die "No lock file configured";
    $dir =~ s/[\\\/]+[^\\\/]+$//;
    CheckDir($dir, $self->{opts}{verbose});

    open my $fh, '>', $self->{opts}{lockFile} or die "$!: $self->{opts}{lockFile}";
    print $fh $$; # write pid
    close $fh;
}

sub setupMonitors {
    my $self = shift;

    my $cwd = getcwd;
    $cwd =~ s|/|\\|g;
    $cwd =~ s|(.)|\u$1|;

    $self->{snapshotMon} = new MPC::SnapshotMonitor(
        snapshotDir => $self->{opts}{snapshotDir},
        workingDir => $cwd,
        port => $self->{opts}{port},
        url => $self->{opts}{url},
        requestAgent => $self->{opts}{requestAgent},
        requestTimeout => $self->{opts}{requestTimeout},
        offlineTimeout => $self->{opts}{offlineTimeout},
    )->init;
}

###############################################################################

sub quit {
    my $self = shift;
    print "Bye\n" unless $self->{opts}{quiet};
    exit;
}

sub autoCompleteMode {
    my $self = shift;
    if ($self->{opts}{completeCommand}) {
        $self->switch("Auto complete");
    } else {
        print "No complete command configured\n";
    }
}

sub bookmarkMode {
    my $self = shift;
    $self->switch("Bookmark mode");
}

sub setCategory {
    my $self = shift;
    print "Category: ";
    my $cat = ReadLine();
    return if !$cat;
    if ($self->{prevPath}) {
        $self->{status}{$self->{prevPath}}{cat} = $cat;
    } else {
        print "No history\n";
        Confirm("Apply to all?") || return;
        foreach (keys %{$self->{status}}) {
            next if $_ eq 'unresolved';
            $self->{status}{$_}{cat} = $cat;
        }
    }
    WriteStatus();
}

sub completeCategory {
    my $self = shift;
    print "Category: ";
    my $cat = ReadLine();
    return if !$cat;

    if (chdir $cat) {
        my $cwd = getcwd;
        Complete();
        chdir $cwd;
    } else {
        print "$!: $cat\n";
    }
}

sub deleteFiles {
    my $self = shift;
    Confirm("Delete?") || return;

    my %stats = (
        deleteCount => 0,
        deleteSize => 0,
        deleteFailCount => 0,
    );
    while (my ($file, $data) = each %{$self->{status}}) {
        next if $file eq "unresolved";
        next unless $data->{cat} && $data->{cat} eq "delete";
        my $fsize = -s $file;

        Log("Delete $file");
        try {
            UnlinkFile($file);
            delete $self->{status}{$file};

            print "Deleted $file\n" if $self->{opts}{verbose};
            $stats{deleteCount}++;
            $stats{deleteSize} += $fsize;

            DeleteSnapshots($data->{snapshots});
        } catch {
            print "$_[0]\n";
            $stats{deleteFailCount}++;
        };
    }

    unless ($self->{opts}{quiet}) {
        printf "%u (%s) deleted",
            $stats{deleteCount},
            format_bytes($stats{deleteSize});

        if ($stats{deleteFailCount}) {
            print ", $stats{deleteFailCount} failed";
        }
        print "\n";
    }

    WriteStatus();
}

sub list {
    my $self = shift;
    my $c = 0;
    my $list = "";
    foreach my $path (sort keys %{$self->{status}}) {
        next if $path eq "unresolved";
        #~ next unless $self->{status}{$path}{dir};
        my $ss = $self->{status}{$path}{snapshots} // [];
        $self->{status}{$path}{cat} //= GetCategory($ss);
        printf "%-10.10s %s\n", $self->{status}{$path}{cat}, $path;
        $list .= "$path\n";
        $c++;
    }
    $self->{clipboard}->Set($list);
    printf "%d file%s\n", $c, $c == 1 ? "" : "s" unless $self->{opts}{quiet};
}

sub openFile {
    my $self = shift;
    OpenFile($self->{prevPath});
}

sub openMode {
    my $self = shift;
    $self->switch("Open mode");
}

sub pause {
    my $self = shift;
    $self->switch("Directory monitor")
    &&
    $self->{snapshotMon}->reset; # reset if started
}

sub reset {
    my $self = shift;
    Confirm("Reset?") || return;
    %{$self->{status}} = ();
    $self->{prevPath} = undef;
    WriteStatus();
    print "Cleared data\n";
}

sub status {
    my $self = shift;
    print "Categories: @{$self->{opts}{categories}}\n";
    for ('Directory monitor','Auto complete','Open mode') {
        print "$_: ", $self->{opts}{$_} ? "on" : "off", "\n";
    }
    try {
        my $path = $self->getOpenFilePath();
        print "Open: $path\n";
    } catch {
        print "$_[0]\n";
    };
    my $cwd = getcwd;
    print "Working directory: $cwd\n";
}

sub tag {
    my $self = shift;
    my $tags = ReadLine();
    my @tags = split /\s+/, $tags;
    my $tf = TagFile()->new->add(@tags)->write;
}

sub undo {
    my $self = shift;
    if ($self->{prevPath}) {
        print "Undo $self->{prevPath}\n";
        # remove key from status hash
        delete $self->{status}{$self->{prevPath}};
        WriteStatus();
    } else {
        print "No history\n";
    }
}

###############################################################################

sub newSnapshot {
    my ($self, $snapshot, $opts) = @_;

    print "Snapshot: $snapshot->{file}\n" if $self->{opts}{debug};

    if ($snapshot->{dir}) {
        my $path = delete $snapshot->{path};
        print "File: $path\n" if $self->{opts}{verbose};

        if ($self->{opts}{'Bookmark mode'}) {
            Bookmark($snapshot);
        } elsif ($self->{opts}{'Open mode'}) {
            OpenFile($path);
            DeleteSnapshot($snapshot);
        } else {
            my $data = $self->{status}{$path} ||= {};
            # TODO: check values if already defined!
            $data->{dir} = delete $snapshot->{dir};
            $data->{file} = delete $snapshot->{file};

            my $self->{status} = delete $snapshot->{status};
            $snapshot->{duration} = int ($self->{status}{duration} // -1);
            $snapshot->{durationstring} = $self->{status}{durationstring};
            $snapshot->{position} = int ($self->{status}{position} // -1);
            $snapshot->{positionstring} = $self->{status}{positionstring};

            #~ my $timecode = delete $snapshot->{timecode};
            #~ $snapshot->{position} ||= $timecode->{seconds} * 1000;
            #~ $snapshot->{positionstring} ||= $timecode->{position};

            my $snapshots = $data->{snapshots} ||= [];
            push @$snapshots, $snapshot;
            $data->{cat} = GetCategory($snapshots);

            printf "%-10.10s %s\n", $data->{cat}, $path;
            $self->{clipboard}->Set($path);

            DeleteSnapshot($snapshot);
        }

        $self->{prevPath} = $path;

    } else {
        Bell();
        print "File not playing\n";

        push @{$self->{status}{unresolved}}, $snapshot;
        DeleteSnapshot($snapshot);
    }

    WriteStatus();
}

###############################################################################

sub bookmark {
    my $self = shift;
    my $snapshot = shift;
    my $file = "$self->{opts}{snapshotDir}\\$snapshot->{image}";
    if (MoveToDir($file, $snapshot->{dir})) {
        print "$snapshot->{path}\n";
    } else {
        print "Error moving snapshot to $snapshot->{dir}\n";
    }
}

sub switch {
    my $self = shift;
    my $switch = shift;
    if ($self->{opts}{$switch} = ! $self->{opts}{$switch}) {
        print "$switch enabled\n";
    } else {
        print "$switch disabled\n";
    }
    return $self->{opts}{$switch};
}

sub deleteSnapshots {
    my $self = shift;
    my $snapshots = shift;
    # purge snapshots
    foreach (@$snapshots) {
        my $file = "$self->{opts}{snapshotBinDir}\\$_->{image}";
        try {
            UnlinkFile($file);
            print "Deleted $file\n" if $self->{opts}{verbose};
        } catch {
            print "$_[0]\n";
        };
    }
}

sub deleteSnapshot {
    my $self = shift;
    my $snapshot = shift;
    my $file = "$self->{opts}{snapshotDir}\\$snapshot->{image}";
    if (MoveToDir($file, $self->{opts}{snapshotBinDir})) {
        print "Snapshot moved to bin\n" if $self->{opts}{verbose};
    } else {
        print "Error moving snapshot to bin\n";
    }
}

sub moveToCategory {
    my $self = shift;

    Confirm("Move files?") || return;

    my %dirs;
    my ($c, $e) = (0)x2;
    while (my ($file, $data) = each %{$self->{status}}) {
        next if $file eq "unresolved";
        next if $data->{cat} && $data->{cat} eq 'delete';

        my $dir = "$data->{dir}/$data->{cat}";
        if (MoveToDir($file, $dir)) {
            print "Move ok: $file -> $dir\n" if $self->{opts}{verbose};

            # remove key from status hash
            delete $self->{status}{$file};
            Log("Move $file $dir");

            # remember dir
            $dirs{$dir} = 1;

            $c++;

        } else {
            print "Move failed: $file -> $dir\n" if $self->{opts}{verbose};

            $e++;
        }
    }

    my $cwd = getcwd;

    foreach (keys %dirs) {
        if (chdir $_) {
            Complete() if $self->{opts}{'Auto complete'};
        } else {
            print "$!: $_\n";
        }
    }

    chdir $cwd;

    unless ($self->{opts}{quiet}) {
        print "$c moved";
        if ($e) {
            print ", $e failed";
        }
        print "\n";
    }

    WriteStatus();
}

sub moveToDir {
    my $self = shift;
    my ($file, $dir) = @_;
    print "Move $file -> $dir\n" if $self->{opts}{verbose};
    CheckDir($dir, $self->{opts}{verbose});

    unless (move $file, $dir) {
        print "$!: $file -> $dir\n";
        return 0;
    }
    return 1;
}

sub complete {
    my $self = shift;
    if (!$self->{opts}{completeCommand}) {
        print "No complete command configured\n";
        return;
    }
    if (system "start", "cmd", "/c", $self->{opts}{completeCommand}) {
        print "Program execution failed\n";
    }
}

###############################################################################

sub getCategory {
    my $self = shift;
    my $snapshots = shift;
    if (@$snapshots <= @{$self->{opts}{categories}}) {
        return $self->{opts}{categories}[@$snapshots-1];
    } else {
        return scalar @$snapshots;
    }
}

sub getOpenFilePath {
    my $self = shift;
    if (my $mpcStatus = $self->{snapshotMon}->getStatus) {
        return $mpcStatus->filepath;
    } else {
        throw Exception("No MPC status");
    }
}

sub log {
    my $self = shift;
    return unless defined $self->{opts}{logFile};
    my $text = shift || return;
    my @t = localtime();
    open my $fh, '>>', $self->{opts}{logFile} or die "$!: $self->{opts}{logFile}";
    printf $fh "%02u-%02u-%02u %02u:%02u:%02u %s\n",
        $t[3], $t[4]+1, $t[5]-100, $t[2], $t[1], $t[0], $text;
    close $fh;
}

sub writeStatus {
    my $self = shift;
    $self->{statusFile}->write if $self->{statusFile};
}

###############################################################################

sub CheckDir {
    my ($dir, $verbose) = @_;
    if (-e $dir) {
        unless (-d $dir) {
            throw Exception("Not a directory: $dir");
        }
        return 0;
    }
    unless (make_path $dir) {
        throw Exception("$!: $dir");
    }
    print "Created $dir\n" if $verbose;
    return 1;
}

sub OpenFile {
    my $file = shift;
    if (system "cmd", "/c", "of -o \"$file\"") {
        print "Program execution failed\n";
    }
}

sub UnlinkFile {
    my $file = shift;
    unless (defined $file) {
        throw Exception("No file defined");
    }
    if (-e $file && ! -f $file) {
        throw Exception("Not a file: $file");
    }
    if (! unlink $file) {
        throw Exception("$!: $file");
    }
    return 1;
}

sub Bell {
    print chr(7);
}

1;
