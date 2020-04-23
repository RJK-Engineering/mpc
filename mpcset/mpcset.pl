use strict;
use warnings;

BEGIN {
    # add lib paths
    use File::Basename qw(dirname);
    my $home = dirname(__FILE__);
    push @INC, $home, "$home/lib";
}

use Options::Pod;
use Pod::Usage qw(pod2usage);

use File::Copy qw(copy);

use File::Ini;
use File::JSON;

###############################################################################
=head1 DESCRIPTION

View and change Media Player Classic settings.

=head1 SYNOPSIS

tweak.pl [options] [setting] [value]

=over 4

=item Displays current setting if [value] is not specified.

=back

=head1 DISPLAY EXTENDED HELP

tweak.pl -h

=head1 OPTIONS

=for options start

=over 4

=item B<-i --ini-file [path]>

Path to MPC INI file.

=item B<-w --write>

Write changes to MPC INI.

=item B<-o --open-ini>

Open MPC INI.

=item B<-s --settings>

List all settings.

=back

=head2 Profiles

=over 4

The profile named C<last> stores the latest setting values
written to MPC INI.

=back

=over 4

=item B<--profile-file [path]>

Path to file containing profiles.

=item B<-p --profile [name]>

Select profile. Lists available profiles of [name] is not specified.

=item B<-d --delete>

Delete selected profile.

=item B<-e --edit-profiles>

Open profiles.

=back

=head2 Pod

=over 4

=item B<--podcheck>

Run podchecker.

=item B<--pod2html --html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<--genpod>

Generate POD for options.

=item B<--savepod>

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

=item B<-h -? --help>

Display extended help.

=back

=for options end

=cut
###############################################################################

my %opts = (
    iniFile => 'mpc-hc64.ini',
    profileFile => 'mpctweak.json',
);
Options::Pod::GetOptions(
    ['OPTIONS'],
    'i|ini-file=s' => \$opts{iniFile}, "{Path} to MPC INI file.",
    'w|write' => \$opts{writeIni}, "Write changes to MPC INI.",
    'o|open-ini' => \$opts{openIni}, "Open MPC INI.",
    's|settings' => \$opts{settings}, "List all settings.",

    ['Profiles',
        "The profile named C<last> stores the latest setting values\n".
        "written to MPC INI."
    ],
    'profile-file=s' => \$opts{profileFile}, "{Path} to file containing profiles.",
    'p|profile:s' => \$opts{profile},
        "Select profile. Lists available profiles of [{name}] is not specified.",
    'd|delete' => \$opts{deleteProfile}, "Delete selected profile.",
    'e|edit-profiles' => \$opts{editProfiles}, "Open profiles.",

    #~ 'v|verbose' => \$opts{verbose}, "Be verbose.",
    #~ 'q|quiet' => \$opts{quiet}, "Be quiet.",
    #~ 'debug' => \$opts{debug}, "Display debug information.",
);

exit system $opts{profileFile} if $opts{editProfiles};
exit system $opts{iniFile} if $opts{openIni};

# required options and/or arguments
defined $opts{profile} ||
defined $opts{settings} ||
@ARGV || pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

my ($setting, $value) = @ARGV;

###############################################################################

my $ini = new File::Ini($opts{iniFile})->read;

if ($opts{settings}) {
    foreach ($ini->getKeys('Settings')) {
        printf "%s=%-.60s\n", $_, $ini->get('Settings', $_);
    }
}

my $conf = new File::JSON($opts{profileFile})->read;
my $profiles = $conf->data;

if (defined $opts{profile}) {
    if ($opts{profile}) {
        my $profile = GetProfile($opts{profile});
        Profile($profile);
    } else {
        ListProfiles();
    }
} elsif ($setting) {
    my $currValue = GetValue($setting);
    if (defined $value) {
        SetValue($setting, $value, $currValue);
        WriteIni();
    } else {
        printf "%s=%s\n", $setting, $currValue;
    }
}

sub GetProfile {
    my $name = shift;
    return $profiles->{$name} if $profiles->{$name};

    my @profiles;
    foreach (keys %$profiles) {
        next if !/^$name/i;
        push @profiles, $_;
    }

    if (@profiles == 1) {
        print "Profile: $profiles[0]\n";
        $opts{profile} = $profiles[0];
        return $profiles->{$profiles[0]};
    } elsif (@profiles) {
        print "Profiles: @profiles\n";
        exit;
    }

    return $profiles->{$name} = {};
}

sub Profile {
    my $profile = shift;

    if (!keys %$profile) {
        if ($setting) {
            print "New profile: $opts{profile}\n";
        } else {
            die "No such profile: $opts{profile}";
        }
    }

    if ($setting) {
        # set value for profile from argument or from ini
        my $profValue = $value // GetValue($setting);

        if (defined $profile->{$setting}) {
            # profile already has setting
            if ($profile->{$setting} eq $profValue) {
                printf "=%s=%s\n", $setting, $profValue;
            } else {
                printf "-%s=%s\n", $setting, $profile->{$setting};
                printf "+%s=%s\n", $setting, $profValue;
            }
        } else {
            # new setting for profile
            printf "+%s=%s\n", $setting, $profValue;
        }

        # set and write
        SetProfile($profile, $profValue);
        $conf->write;
    } elsif ($opts{deleteProfile}) {
        delete $profiles->{$opts{profile}};
        print "Profile deleted: $opts{profile}\n";
        $conf->write;
    } else {
        foreach my $setting (sort keys %$profile) {
            SetValue($setting, $profile->{$setting});
        }
        WriteIni();
    }
}

sub SetProfile {
    my ($profile, $profValue) = @_;
    # string to number
    $profValue = 1 * $profValue if $profValue =~ /^(?:\d+|\d*\.\d+)$/;
    $profile->{$setting} = $profValue;
}

sub GetValue {
    my $setting = shift;
    $ini->get('Settings', $setting)
        // die "No such setting: $setting";
}

sub SetValue {
    my ($setting, $newValue, $currValue) = @_;
    $currValue //= $ini->get('Settings', $setting);
    if ($currValue eq $newValue) {
        printf "=%s=%s\n", $setting, $currValue;
    } else {
        printf "-%s=%s\n", $setting, $currValue;
        printf "+%s=%s\n", $setting, $newValue;
        $ini->set('Settings', $setting, $newValue);
    }

    # remember last values written to ini
    if ($opts{writeIni}) {
        SetProfile($profiles->{last}, $newValue);
        $conf->write;
    }
}

sub ListProfiles {
    foreach (sort keys %$profiles) {
        print "[$_]\n";
        my $profile = $profiles->{$_};
        foreach my $setting (sort keys %$profile) {
            printf "%s=%s\n", $setting, $profile->{$setting};
        }
    }
}

sub WriteIni {
    $opts{writeIni} || return;
    copy $opts{iniFile}, "c:\\temp\\mpc.ini.".time()
        or die "Backup failed";
    $ini->write;
}
