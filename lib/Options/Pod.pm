=begin TML

---+ package Options::Pod

---++ Synopsis

<verbatim class="perl">
Options::Pod::Configure(
    "bundling",                     # if not set, long options will have
                                    # a single dash in generated POD
    "comments_included",            # indicates comments are present in
                                    # GetOptions() configuration
    "tri-state"                     # argument spec / 1 / undefined
);
Options::Pod::GetOptions(
    ['No argument name'],           # POD: =head2 No argument name
    'option1=s' => ...,             # POD: --option1 [string]
        "Description of option.",
    'option2=i' => ...,             # POD: --option2 [integer]
        "Description of option.",
    'option3=o' => ...,             # POD: --option3 [extended integer]
        "Description of option.",
    'option4=f' => ...,             # POD: --option4 [real number]
        "Description of option.",

    ['Argument name',
        "Additional POD text"
    ],
    'option5=s' => ...,             # POD: --option5 [argument name]
        [ "Set argument name.", "argument name" ],
    'option6=s' => ...,             # POD: --option6 [argument name]
        "{Argument name} in option description.",
    'option7=s' => ...,             # POD: --option7 [arg]
        [ "Set complete option description.", "", "--option7 [arg]" ],
    'tri-state:0' => ...,

    ['Pod'],
    Options::Pod::Options           # podcheck, pod2html, genpod and savepod options
)
&& Options::Pod::HandleOptions()    # handle podcheck, pod2html, genpod and savepod options
|| exit;                            # an error occurred
</verbatim>

Command Line:

<verbatim class="bash">
perl script.pl --podcheck
perl script.pl --pod2html
perl script.pl --genpod
perl script.pl --genpod --savepod
perl script.pl +tri-state
</verbatim>

---++ Description

This package adds the following functionality using
[[http://perldoc.perl.org/Getopt/Long.html][Getopt::Long]]:

   * Option to call [[http://perldoc.perl.org/podchecker.html][podchecker]].
   * Option to call [[http://perldoc.perl.org/pod2html.html][pod2html]].
   * Option to generate POD from [[http://perldoc.perl.org/Getopt/Long.html][Getopt::Long]] configuration.
   * Option to save generated POD to the script it was generated from.
   * Tri-state options.

---++ Tri-state options

When the =tri-state= option is enabled the value of options starting
with a =+= will be set to =1=.

Example:

<verbatim>
Options::Pod::Configure("tri-state");
my @options = ('tri-state:0' => ...);
</verbatim>

| *Option* | *Value* | *Meaning* |
| =-tri-state= | =0= (argument specification ":0") | disabled |
| =+tri-state= | =1= | enabled |
| not specified | =undef= or a default value | don't care |

=cut

package Options::Pod;

use strict;
use warnings;

use Getopt::Long qw();
use Pod::Checker qw(podchecker);
use Pod::Html    qw(pod2html);

my %conf;
my $header;
my %opts;
my $optConf;

my $optionSectionStart = '=for options start';
my $optionSectionEnd = '=for options end';

###############################################################################
=pod

---++ Functions

---+++ Configure(@options)

See: [[http://perldoc.perl.org/Getopt/Long.html#Configuring-Getopt%3a%3aLong][Configuring Getopt::Long]]

Additional options:

   * =comments_included= - Every 3rd element in the configuration array
     contains comments. This will be used for POD generation.
   * =tri-state= - Enable tri-state options.

=cut
###############################################################################

sub Configure {
    %conf = ();
    my @opts;
    my %confOptions = (
        'tri-state' => 1,
        comments_included => 1
    );
    foreach (@_) {
        $conf{$_} = 1;
        push @opts, $_ unless $confOptions{$_};
    }
    Getopt::Long::Configure(@opts);
}

###############################################################################
=pod

---+++ Options() -> @configuration

Returns POD functionality options.

=cut
###############################################################################

sub Options {
    'podcheck' => sub {
        my $r = podchecker($0);
        print("$0 pod syntax OK.\n") unless $r;
        exit $r;
    }, $conf{comments_included} ?
        "Run podchecker." : (),

    'pod2html|html:s' => sub {
        my $outfile = $_[1];
        if (-d $outfile) {
            my $filename = $0;
            $filename =~ s|^.*[\\\/]||;
            $filename =~ s|\.pl$||;
            $outfile = "$outfile/$filename.html";
        }
        pod2html($0, $outfile ? "--outfile=$outfile" : ());
        unlink 'pod2htmd.tmp';
        exit;
    }, $conf{comments_included} ? [
        "Run pod2html. Writes to [path] if specified. Writes to\n".
        "F<[path]/{scriptname}.html> if [path] is a directory.\n".
        "E.g. C<--html .> writes to F<./{scriptname}.html>.", "path" ] : (),

    'genpod' => \$opts{generatePod}, $conf{comments_included} ?
        "Generate POD for options." : (),
    'savepod' => \$opts{savePod}, $conf{comments_included} ?
        "Save generated POD to script file.\n".
        "The POD text will be inserted between C<$optionSectionStart> and\n".
        "C<$optionSectionEnd> tags.\n".
        "If no C<$optionSectionEnd> tag is present, the POD text will be\n".
        "inserted after the C<$optionSectionStart> tag and a\n".
        "C<$optionSectionEnd> tag will be added.\n".
        "A backup is created." : (),
}

###############################################################################
=pod

---+++ !GetOptions(@configuration or \@configuration)

See: [[http://perldoc.perl.org/Getopt/Long.html][Getopt::Long]]

=cut
###############################################################################

sub GetOptions {
    @$optConf = @_;

    if ($conf{'tri-state'}) {
        # values: 0=disabled, 1=enabled, 2=don't care
        # "-option" = disable option = value 0 (getopt spec: 'option:0')
        # "+option" = enable option = value 1
        # option not specified = default value $opts{option} = 2
        @ARGV = map { /^\+/ ? ($_, 1) : $_ } @ARGV;
    }

    my @getoptConf;
    for (my $i=0; $i<@$optConf; $i+=$conf{comments_included}?3:2) {
        if (ref $optConf->[$i]) {
            $i -= 2;
            next;
        }
        push @getoptConf, $optConf->[$i], $optConf->[$i+1];
    }

    return Getopt::Long::GetOptions(@getoptConf);
}

###############################################################################
=pod

---+++ !HandleOptions() -> $success

Use POD functionality.

=cut
###############################################################################

sub HandleOptions {
    if ($opts{generatePod}) {
        if ($optConf) {
            if ($opts{savePod}) {
                SavePod() || return;
            } else {
                print GeneratePod();
            }
        } else {
            die "No configuration, use ".__PACKAGE__."::GetOptions(..configuration..)";
        }
        exit;
    } else {
        if ($opts{savePod}) {
            print "Option --savepod without --genpod.\n";
            return;
        }
    }
    return 1;
}

sub SavePod {
    my ($sectStart, $sectEnd);

    # look for start and end strings
    open my $fh, '<', $0 or die "$!";
    while (<$fh>) {
        if (/^$optionSectionStart$/) {
            $sectStart = 1;
        } elsif (/^$optionSectionEnd$/) {
            $sectEnd = 1;
            last;
        }
    }
    close $fh;

    if (!$sectStart) {
        print STDERR "Section start tag not found, use \"$optionSectionStart\" where POD should be inserted.\n";
        return;
    }

    local ($^I, @ARGV) = ('.orig', $0);
    my $inSection;
    while (<>) {
        if ($inSection) {
            next if !/^$optionSectionEnd$/;
            print;
            undef $inSection;
        } else {
            print;
            next if !/^$optionSectionStart$/;
            print "\n", GeneratePod();
            if ($sectEnd) {
                # do not print until end tag encountered
                $inSection = 1;
            } else {
                # add missing end tag and continue printing
                print "$optionSectionEnd\n";
            }
        }
    }
    return 1;
}

###############################################################################
=pod

---+++ !GeneratePod() -> $success

Generate POD for command line options.

=cut
###############################################################################

sub GeneratePod {
    my $pod = "=over 4\n\n";

    for (my $i=0; $i<@$optConf; $i+=$conf{comments_included}?3:2) {
        if (ref $optConf->[$i]) {
            $pod .= "=back\n\n";
            $pod .= "=head2 $optConf->[$i][0]\n\n";
            $pod .= "=over 4\n\n";
            if ($optConf->[$i][1]) {
                # additional pod text
                $optConf->[$i][1] =~ s/==/=/g;
                $pod .= "$optConf->[$i][1]\n\n";
                $pod .= "=back\n\n";
                $pod .= "=over 4\n\n";
            }
            $i -= 2;
            next;
        }

        my ($optSpec, $typeSpec) = split /[!+=:]/, $optConf->[$i];
        my $comment = $conf{comments_included} ? $optConf->[$i+2] : "";
        my $opts;

        if (ref $comment) {
            ($comment, $typeSpec, $opts) = @$comment;
        } elsif ($comment =~ s/{(.+?)}/$1/g) {
            $typeSpec = lc $1;
        } elsif ($typeSpec) {
            $typeSpec =~ s/^s/string/;
            $typeSpec =~ s/^i/integer/;
            $typeSpec =~ s/^o/extended integer/;
            $typeSpec =~ s/^f/real number/;
        }

        $pod .= "=item B<";
        $pod .= $opts // join " ", map {
            $conf{bundling} && length > 1 ? "--$_" : "-$_"
        } split /\|/, $optSpec;
        $pod .= " [$typeSpec]" if $typeSpec;
        $pod .= ">\n\n";
        $pod .= "$comment\n\n" if $comment;
    }

    $pod .= "=back\n\n";
    return $pod;
}

1;
