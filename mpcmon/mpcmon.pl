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

use MPCTools::MPCMon;
use MPCTools::MPCMonControl;

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
Options::Pod::GetOptions(
    ['OPTIONS'],
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

    ['POD'],
    Options::Pod::Options,
    ['HELP'],
    Options::Pod::HelpOptions
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
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

# quiet!
$opts{verbose} = 0 if $opts{quiet};

$opts{'Auto complete'} = 1 if $opts{completeCommand};

# array of categories
$opts{categories} = [ split /,/, $opts{categories} ];

$opts{snapshotBinDir} = "$opts{snapshotDir}\\del";
MPCTools::MPCMon::CheckDir($opts{snapshotBinDir}, $opts{verbose});

###############################################################################

my $mon = new MPCTools::MPCMon()->init(\%opts);

if ($opts{mpcstatus}) {
    if (my $mpcStatus = $mon->{snapshotMon}->getStatus) {
        print "$_\t$mpcStatus->{$_}\n" for @MPC::Status::fields;
    } else {
        print "No MPC status\n";
    }
    exit;
}

###############################################################################

my $actions = {
    '?' => \&Help,
    a => sub { $mon->autoCompleteMode },
    b => sub { $mon->bookmarkMode },
    c => sub { $mon->setCategory },
    C => sub { $mon->completeCategory },
    d => sub { $mon->deleteFiles },
    h => \&Help,
    l => sub { $mon->list },
    m => sub { $mon->moveToCategory },
    o => sub { $mon->openFile },
    O => sub { $mon->openMode },
    p => sub { $mon->pause },
    q => sub { $mon->quit },
    r => sub { $mon->reset },
    s => sub { $mon->status },
    t => sub { $mon->tag },
    u => sub { $mon->undo },
};

my $control = new MPCTools::MPCMonControl($mon)->init(\%opts, $actions);

print "Keys: ", join(" ", sort keys %$actions), "\n" if $opts{debug};

sub Help {
    pod2usage(
        -exitstatus => 'NOEXIT',
        -verbose => 99,
        -sections => "USAGE/Keys",
        -indent => 0,
        -width => $control->{console}->columns,
    );
    $control->{console}->lineUp;
}

###############################################################################

$SIG{INT} = q(Interrupt);

$control->start;

sub Interrupt {
    my ($signal) = @_;
    $mon->quit;
}

END {
    $mon->finish if $mon;
}
