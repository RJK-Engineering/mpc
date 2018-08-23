use strict;
use warnings;
use utf8;

BEGIN {
    # add lib paths
    use File::Basename qw(dirname);
    my $home = dirname(__FILE__);
    push @INC, $home, "$home/lib";
}

use Options::Pod;
use Pod::Usage qw(pod2usage);

use Exception::Class('Exception');
use Try::Tiny;

use Cwd qw(getcwd);
use File::Copy qw(move);
use File::Path qw(make_path);
use Number::Bytes::Human qw(format_bytes);
use Win32::Clipboard;

use Console;
use File::JSON;
use Interactive qw(Ask ReadLine Confirm);
Interactive::SetClass('Term::ReadKey');
use MPC::Playlist;
use MPC::SnapshotMonitor;
use ProcessList;

use MPCMon;

###############################################################################
=head1 DESCRIPTION

Monitor a directory and perform actions based on the snapshot
files created by Media Player Classic.

=head1 SYNOPSIS

mpcssmon.pl [options]

=head1 DISPLAY EXTENDED HELP

mpcssmon.pl -h

=head1 OPTIONS

=for options start

=over 4

=item B<-snapshot-dir [path]>

Path to snapshot directory.

=item B<-snapshot-bin [path]>

Path to snapshot bin.

=item B<-status-file [path]>

Path to status file.

=item B<-lock-file [path]>

Path to lock file.

=item B<-log-file [path]>

Path to log file.

=item B<-port [number]>

Port to web interface.

=item B<-i -polling-interval [seconds]>

Polling interval in seconds. Default: 1

=item B<-w -window-title [string]>

Window title.

=item B<-c -categories [string]>

Comma separated list of directory names.

=item B<-p -playlist-dir [path]>

Path to playlist directory.

=item B<-x -complete-cmd [string]>

Command to execute to complete F<.part> files.

=item B<-r -run>

Start monitoring. Ctrl+C = stop and exit.

=item B<-mpcstatus>

Show Media Player Classic status.

=item B<-s -open-status>

Open status file.

=item B<-l -open-log>

Open log file.

=item B<-v -verbose>

Be verbose.

=item B<-q -quiet>

Be quiet.

=item B<-debug>

Display debug information.

=back

=head2 Pod

=over 4

=item B<-podcheck>

Run podchecker.

=item B<-pod2html -html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<-genpod>

Generate POD for options.

=item B<-savepod>

Save generated POD to script file.
The POD text will be inserted between C<=for options start> and
C<=for options end> tags.
If no C<=for options end> tag is present, the POD text will be
inserted after the C<=for options start> tag and a
C<=for options end> tag will be added.
A backup is created.

=back

=head2 Help

=over 4

=item B<-h -? -help>

Display extended help.

=back

=for options end

=head1 USAGE

=head2 Keys

&del &move &complete &reset &undo
&list &open &status &pause &help(F1) &quit(Esc)

=cut
###############################################################################

my %opts = (
    run => 0,
    snapshotDir => '.',
    windowTitle => $0,
    pollingInterval => 1,
    'Directory monitor' => 1,
    'Auto complete' => 1,
    'Open mode' => 0,
    categories => "",
);
Options::Pod::Configure("comments_included");
Options::Pod::GetOptions(
    'snapshot-dir=s' => \$opts{snapshotDir}, "{Path} to snapshot directory.",
    'snapshot-bin=s' => \$opts{snapshotBinDir}, "{Path} to snapshot bin.",
    'status-file=s' => \$opts{statusFile}, "{Path} to status file.",
    'lock-file=s' => \$opts{lockFile}, "{Path} to lock file.",
    'log-file=s' => \$opts{logFile}, "{Path} to log file.",

    'port=i' => \$opts{port}, [ "Port to web interface.", 'number' ],
    'i|polling-interval=i' => \$opts{pollingInterval},
        "Polling interval in {seconds}. Default: $opts{pollingInterval}",

    'w|window-title=s' => \$opts{windowTitle}, "Window title.",
    'c|categories=s' => \$opts{categories}, "Comma separated list of directory names.",
    'p|playlist-dir=s' => \$opts{playlistDir}, "{Path} to playlist directory.",
    'x|complete-cmd=s' => \$opts{completeCommand},
        "Command to execute to complete F<.part> files.",

    'r|run' => \$opts{run}, "Start monitoring. Ctrl+C = stop and exit.",
    'mpcstatus' => \$opts{mpcstatus}, "Show Media Player Classic status.",
    's|open-status' => \$opts{openStatus}, "Open status file.",
    'l|open-log' => \$opts{openLog}, "Open log file.",

    'v|verbose' => \$opts{verbose}, "Be verbose.",
    'q|quiet' => \$opts{quiet}, "Be quiet.",
    'debug' => \$opts{debug}, "Display debug information.",

    ['Pod'],
    Options::Pod::Options,

    ['Help'],
    'h|?|help' => sub {
        pod2usage(
            -exitstatus => 0,
            -verbose => 99,
            -sections => "DESCRIPTION|SYNOPSIS|OPTIONS",
        );
    }, "Display extended help.",
)
&& Options::Pod::HandleOptions()
|| pod2usage(
    -verbose => 99,
    -sections => "DISPLAY EXTENDED HELP",
);

exit Edit($opts{statusFile}) if $opts{openStatus};
exit Edit($opts{logFile}) if $opts{openLog};
sub Edit {
    my $file = shift;
    return unless system $file;
    system $ENV{EDITOR}, $file;
}

# required options and/or arguments
$opts{run} ||
$opts{mpcstatus} || pod2usage(
    -verbose => 99,
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

# quiet!
$opts{verbose} = 0 if $opts{quiet};

$opts{'Auto complete'} = 1 if $opts{completeCommand};

# array of categories
$opts{categories} = [ split /,/, $opts{categories} ];

$opts{snapshotBinDir} = "$opts{snapshotDir}\\del";
if (CheckDir($opts{snapshotBinDir})) {
    print "Created $opts{snapshotBinDir}\n" if $opts{verbose};
}

###############################################################################

my $cwd = getcwd;
$cwd =~ s|/|\\|g;
$cwd =~ s|(.)|\u$1|;

my $snapshotMon = new MPC::SnapshotMonitor(
    snapshotDir => $opts{snapshotDir},
    workingDir => $cwd,
    port => $opts{port},
    url => $opts{url},
    requestAgent => $opts{requestAgent},
    requestTimeout => $opts{requestTimeout},
    offlineTimeout => $opts{offlineTimeout},
)->init;

if ($opts{mpcstatus}) {
    if (my $mpcStatus = $snapshotMon->getStatus) {
        print "$_\t$mpcStatus->{$_}\n" for @MPC::Status::fields;
    } else {
        print "No MPC status\n";
    }
    exit;
}

###############################################################################

if (-e $opts{lockFile}) {
    open my $fh, '<', $opts{lockFile} or die "$!: $opts{lockFile}";
    my $pid = <$fh>;
    chomp $pid;
    close $fh;

    my $proc = ProcessList::GetPid($pid);
    if ($proc) {
        print "$0 is already running.\n" unless $opts{quiet};
        undef $opts{lockFile}; # do not remove file in END block
        exit 1;
    } else {
        print "$0 was not closed properly, old lock file found.\n" unless $opts{quiet};
    }
}
# create lock file
open my $fh, '>', $opts{lockFile} or die "$!: $opts{lockFile}";
print $fh $$; # write pid
close $fh;

END {
    unlink $opts{lockFile} if $opts{lockFile};
}

###############################################################################

my $clip = Win32::Clipboard();
my $console = new Console();

my $statusFile;
my $status = {};
if ($opts{statusFile}) {
    $statusFile = new File::JSON($opts{statusFile})->read;
    $status = $statusFile->data;
}

sub WriteStatus {
    $statusFile->write if $statusFile;
}

$SIG{'INT'} = q(Interrupt);

###############################################################################

my $prevPath;
my $actions = {
    '?' => \&Help,
    a => \&AutoCompleteMode,
    b => \&BookmarkMode,
    c => \&SetCategory,
    C => \&CompleteCategory,
    d => \&Delete,
    h => \&Help,
    l => \&List,
    m => \&Move,
    o => \&Open,
    O => \&OpenMode,
    p => \&Pause,
    q => \&Quit,
    r => \&Reset,
    s => \&Status,
    t => \&Tag,
    u => \&Undo,
};

print "keys: ", join(" ", sort keys %$actions), "\n" if $opts{debug};

###############################################################################

sub Help {
    pod2usage(
        -exitstatus => 'NOEXIT',
        -verbose => 99,
        -sections => "USAGE/Keys",
        -indent => 0,
        -width => $console->columns,
    );
    $console->lineUp;
}

sub Quit {
    print "Bye\n" unless $opts{quiet};
    exit;
}

sub AutoCompleteMode {
    if ($opts{completeCommand}) {
        Switch("Auto complete");
    } else {
        print "No complete command configured\n";
    }
}
sub BookmarkMode {
    Switch("Bookmark mode");
}
sub SetCategory {
    print "Category: ";
    my $cat = ReadLine();
    return if !$cat;
    if ($prevPath) {
        $status->{$prevPath}{cat} = $cat;
    } else {
        print "No history\n";
        Confirm("Apply to all?") || return;
        foreach (keys %$status) {
            next if $_ eq 'unresolved';
            $status->{$_}{cat} = $cat;
        }
    }
    WriteStatus();
}
sub CompleteCategory {
    print "Category: ";
    my $cat = ReadLine();
    return if !$cat;

    my $cwd = getcwd;
    if (chdir $cat) {
        Complete();
        chdir $cwd;
    } else {
        print "$!: $cat\n";
    }
}
sub Delete {
    Confirm("Delete?") || return;

    my %stats = (
        deleteCount => 0,
        deleteSize => 0,
        deleteFailCount => 0,
    );
    while (my ($file, $data) = each %$status) {
        next if $file eq "unresolved";
        next unless $data->{cat} && $data->{cat} eq "delete";
        my $fsize = -s $file;

        Log("Delete $file");
        try {
            UnlinkFile($file);
            delete $status->{$file};

            print "Deleted $file\n" if $opts{verbose};
            $stats{deleteCount}++;
            $stats{deleteSize} += $fsize;

            DeleteSnapshots($data->{snapshots});
        } catch {
            print "$_[0]\n";
            $stats{deleteFailCount}++;
        };
    }

    unless ($opts{quiet}) {
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
sub List {
    my $c = 0;
    my $list = "";
    foreach my $path (sort keys %$status) {
        next if $path eq "unresolved";
        #~ next unless $status->{$path}{dir};
        my $ss = $status->{$path}{snapshots} // [];
        $status->{$path}{cat} //= GetCategory($ss);
        printf "%-10.10s %s\n", $status->{$path}{cat}, $path;
        $list .= "$path\n";
        $c++;
    }
    $clip->Set($list);
    printf "%d file%s\n", $c, $c == 1 ? "" : "s" unless $opts{quiet};
}
sub Move {
    Confirm("Move files?") || return;
    MoveFiles();
    WriteStatus();
}
sub Open {
    OpenFile($prevPath);
}
sub OpenMode {
    Switch("Open mode");
}
sub Pause {
    Switch("Directory monitor")
    &&
    $snapshotMon->reset; # reset if started
}
sub Reset {
    Confirm("Reset?") || return;
    %$status = ();
    $prevPath = undef;
    WriteStatus();
    print "Cleared data\n";
}
sub Status {
    print "Categories: @{$opts{categories}}\n";
    for ('Directory monitor','Auto complete','Open mode') {
        print "$_: ", $opts{$_} ? "on" : "off", "\n";
    }
    try {
        my $path = GetOpenFilePath();
        print "Open: $path\n";
    } catch {
        print "$_[0]\n";
    };
    $cwd = getcwd;
    print "Working directory: $cwd\n";
}
sub Tag {
    my $tags = ReadLine();
    my @tags = split /\s+/, $tags;
    my $tf = TagFile()->new->add(@tags)->write;
}
sub Undo {
    if ($prevPath) {
        print "Undo $prevPath\n";
        # remove key from status hash
        delete $status->{$prevPath};
        WriteStatus();
    } else {
        print "No history\n";
    }
}

###############################################################################

$console->title("$opts{windowTitle} | $cwd");
if ($opts{verbose}) {
    printf "Polling every %u second%s\n",
        $opts{pollingInterval},
        $opts{pollingInterval} == 1 ? "" : "s";
}

Status();
Help();

while (1) {
    if ($opts{'Directory monitor'}) {
        print "Poll\n" if $opts{debug};
        $snapshotMon->poll(\&NewSnapshot);
    }
    HandleInput();
} continue {
    sleep $opts{pollingInterval};
}

###############################################################################

sub NewSnapshot {
    my $snapshot = shift;

    print "Snapshot: $snapshot->{file}\n" if $opts{debug};

    if ($snapshot->{dir}) {
        my $path = delete $snapshot->{path};
        print "File: $path\n" if $opts{verbose};

        if ($opts{'Bookmark mode'}) {
            Bookmark($snapshot);
        } elsif ($opts{'Open mode'}) {
            OpenFile($path);
            DeleteSnapshot($snapshot);
        } else {
            my $data = $status->{$path} ||= {};
            # TODO: check values if already defined!
            $data->{dir} = delete $snapshot->{dir};
            $data->{file} = delete $snapshot->{file};

            my $status = delete $snapshot->{status};
            $snapshot->{duration} = int ($status->{duration} // -1);
            $snapshot->{durationstring} = $status->{durationstring};
            $snapshot->{position} = int ($status->{position} // -1);
            $snapshot->{positionstring} = $status->{positionstring};

            #~ my $timecode = delete $snapshot->{timecode};
            #~ $snapshot->{position} ||= $timecode->{seconds} * 1000;
            #~ $snapshot->{positionstring} ||= $timecode->{position};

            my $snapshots = $data->{snapshots} ||= [];
            push @$snapshots, $snapshot;
            $data->{cat} = GetCategory($snapshots);

            printf "%-10.10s %s\n", $data->{cat}, $path;
            $clip->Set($path);

            DeleteSnapshot($snapshot);
        }

        $prevPath = $path;

    } else {
        Bell();
        print "File not playing\n";

        push @{$status->{unresolved}}, $snapshot;
        DeleteSnapshot($snapshot);
    }

    WriteStatus();
}

sub HandleInput {
    while ($console->getEvents) {
        my @event = $console->input;
        next if !@event or $event[0] != 1 or !$event[1];
        print "@event\n" if $opts{debug};
        if ($event[5]) {                    # ASCII
            Quit() if $event[5] == 27;      # Esc
            my $key = chr $event[5];
            if ($actions->{$key}) {
                $actions->{$key}->();
            } elsif ($key =~ /^\w$/) {
                print "Not an action key: $key\n" unless $opts{quiet};
            }
        } elsif ($event[3] == 112) {        # F1
            Help();
        }
    }
    $console->flush;    # empty buffer
}

###############################################################################

sub Bookmark {
    my $snapshot = shift;
    my $file = "$opts{snapshotDir}\\$snapshot->{image}";
    if (MoveToDir($file, $snapshot->{dir})) {
        print "$snapshot->{path}\n";
    } else {
        print "Error moving snapshot to $snapshot->{dir}\n";
    }
}

sub OpenFile {
    my $file = shift;
    if (system "cmd", "/c", "of -o \"$file\"") {
        print "Program execution failed\n";
    }
}

sub Switch {
    my $switch = shift;
    if ($opts{$switch} = ! $opts{$switch}) {
        print "$switch enabled\n";
    } else {
        print "$switch disabled\n";
    }
    return $opts{$switch};
}

sub DeleteSnapshots {
    my $snapshots = shift;
    # purge snapshots
    foreach (@$snapshots) {
        my $file = "$opts{snapshotBinDir}\\$_->{image}";
        try {
            UnlinkFile($file);
            print "Deleted $file\n" if $opts{verbose};
        } catch {
            print "$_[0]\n";
        };
    }
}

sub DeleteSnapshot {
    my $snapshot = shift;
    my $file = "$opts{snapshotDir}\\$snapshot->{image}";
    if (MoveToDir($file, $opts{snapshotBinDir})) {
        print "Snapshot moved to bin\n" if $opts{verbose};
    } else {
        print "Error moving snapshot to bin\n";
    }
}

sub MoveFiles {
    my %dirs;
    my ($c, $e) = (0)x2;
    while (my ($file, $data) = each %$status) {
        next if $file eq "unresolved";
        next if $data->{cat} && $data->{cat} eq 'delete';

        my $dir = "$data->{dir}/$data->{cat}";
        if (MoveToDir($file, $dir)) {
            print "Move ok: $file -> $dir\n" if $opts{verbose};

            # remove key from status hash
            delete $status->{$file};
            Log("Move $file $dir");

            # remember dir
            $dirs{$dir} = 1;

            $c++;

        } else {
            print "Move failed: $file -> $dir\n" if $opts{verbose};

            $e++;
        }
    }

    foreach (keys %dirs) {
        if (chdir $_) {
            Complete() if $opts{'Auto complete'};
        } else {
            print "$!: $_\n";
        }
    }

    chdir $cwd;

    unless ($opts{quiet}) {
        print "$c moved";
        if ($e) {
            print ", $e failed";
        }
        print "\n";
    }
}

sub MoveToDir {
    my ($file, $dir) = @_;
    print "Move $file -> $dir\n" if $opts{verbose};
    try {
        if (CheckDir($dir)) {
            print "Created $dir\n" if $opts{verbose};
        }
    } catch {
        print "$_[0]\n";
    };

    unless (move $file, $dir) {
        print "$!: $file -> $dir\n";
        return 0;
    }
    return 1;
}

sub Complete {
    if (!$opts{completeCommand}) {
        print "No complete command configured\n";
        return;
    }
    if (system "start", "cmd", "/c", $opts{completeCommand}) {
        print "Program execution failed\n";
    }
}

###############################################################################

sub GetCategory {
    my $snapshots = shift;
    if (@$snapshots <= @{$opts{categories}}) {
        return $opts{categories}[@$snapshots-1];
    } else {
        return scalar @$snapshots;
    }
}

sub CheckDir {
    my $dir = shift;
    if (-e $dir) {
        unless (-d $dir) {
            throw Exception("Not a directory: $dir");
        }
        return 0;
    }
    unless (make_path $dir) {
        throw Exception("$!: $dir");
    }
    return 1;
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

sub GetOpenFilePath {
    if (my $mpcStatus = $snapshotMon->getStatus) {
        return $mpcStatus->filepath;
    } else {
        throw Exception("No MPC status");
    }
}

sub Bell {
    print chr(7);
}

sub Log {
    return unless defined $opts{logFile};
    my $text = shift || return;
    my @t = localtime();
    open my $fh, '>>', $opts{logFile} or die "$!: $opts{logFile}";
    printf $fh "%2.2u-%2.2u-%2.2u %2.2u:%2.2u:%2.2u %s\n",
        $t[3], $t[4]+1, $t[5]-100, $t[2], $t[1], $t[0], $text;
    close $fh;
}

sub Interrupt {
    my ($signal) = @_;
    Quit();
}
