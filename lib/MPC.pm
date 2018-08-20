=begin TML

---+ package MPC

=cut

package MPC;

use strict;
use warnings;
use File::Ini;

use Exception::Class (
    'Exception',
    'MPC::Exception' =>
        { isa => 'Exception' },
);

my $ini;

###############################################################################
=pod

---++ IniPath() -> $path
Return path to ini file.

---++ GetCommandMods() -> %mods or \%mods
Throws =MPC::Exception=.

---++ GetIds() -> %ids or \%ids
Throws =MPC::Exception=.

---++ GetDescriptions() -> %description or \%description
Throws =MPC::Exception=.

---++ GetCommands() -> @commands or \@commands
Throws =MPC::Exception=.

---++ GetVirtualKeys() -> %keys or \%keys
Throws =MPC::Exception=.

---++ GetVirtualKeyCodes() -> %codes or \%codes
Throws =MPC::Exception=.

=cut
###############################################################################

sub Ini {
    my $path = shift;
    return new File::Ini($path)->read
        || throw MPC::Exception("$!: $path");
}

sub IniPath { $ini && $ini->file || '' }

sub GetCommandMods {
    my $file = shift;
    my %mods;
    $ini = Ini($file);
    foreach ($ini->getList('Commands2', 'CommandMod')) {
        my @mod = split /\s/;
        $mod[3] =~ s/"//g;
        $mods{$mod[0]} = {
            id => $mod[0],
            modif => $mod[1],
            key => $mod[2],
            remoteCmd => $mod[3],
            repCnt => $mod[4],
            mouseWindowed => $mod[5],
            appCommand => $mod[6],
            mouseFullscreen => $mod[7],
        };
    }
    return wantarray ? %mods : \%mods;
}

sub SetCommandMods {
    my ($file, $mods) = @_;
    $ini = Ini($file);
    $ini->setList('Commands2', $mods, 'CommandMod');
    $ini->write();
}

sub GetIds {
    my $file = shift;
    my %ids;

    open (my $fh, '<', $file) || throw MPC::Exception("$!: $file");
    while (<$fh>) {
        if (/^#define (ID_\w+)\s+(\d+)$/) {
            $ids{$1} = $2;
        }
    }
    close $fh;

    return wantarray ? %ids : \%ids;
}

sub GetDescriptions {
    my $file = shift;
    my %descr;

    open (my $fh, '<', $file) || throw MPC::Exception("$!: $file");
    while (<$fh>) {
        if (/^    (\w+)\s+"([^"]+)"$/) {
            $descr{$1} = $2;
        }
    }
    close $fh;

    return wantarray ? %descr : \%descr;
}

sub GetCommands {
    my ($file, $resourceH) = @_;
    my @commands;
    my %ids = GetIds($resourceH);

    open (my $fh, '<', $file) || throw MPC::Exception("$!: $file");
    while (<$fh>) {
        chomp;
        next unless $_ eq 'static constexpr wmcmd_base default_wmcmds[] = {';
        while (<$fh>) {
            chomp;
            last if $_ eq '};';
            if (my @cmd = /{ (\w+)(?: \+ \d+)?,\s+('?\w+'?), (\w+(?: \| \w+)*),\s+(\w+)/) {
                if ($cmd[1]) {
                    $cmd[1] =~ s/'//g;
                } else {
                    $cmd[1] = undef;
                }
                push @commands, {
                    id => $ids{ $cmd[0] },
                    cmd => $cmd[0],
                    key => $cmd[1],
                    flags => [ split / \| /, $cmd[2] ],
                    name => $cmd[3],
                };
            } elsif (/\S/) {
                warn "Unmatched line: $_\n";
            }
        }
        last;
    }
    close $fh;

    return wantarray ? @commands : \@commands;
}

sub GetVirtualKeys {
    my $file = shift;
    my %keys;

    open (my $fh, '<', $file) || throw MPC::Exception("$!: $file");
    while (<$fh>) {
        chomp;
        my @v = split /\t/;
        $keys{$v[0]} = \@v;
    }
    close $fh;

    return wantarray ? %keys : \%keys;
}

sub GetVirtualKeyNames {
    my $file = shift;
    my %keys;

    open (my $fh, '<', $file) || throw MPC::Exception("$!: $file");
    while (<$fh>) {
        chomp;
        my @v = split /\t/;
        $keys{$v[1]} = $v[2];
    }
    close $fh;

    return wantarray ? %keys : \%keys;
}

sub GetVirtualKeyCodes {
    my $file = shift;
    my %codes;

    open (my $fh, '<', $file) || throw MPC::Exception("$!: $file");
    while (<$fh>) {
        chomp;
        my @v = split /\t/;
        $codes{$v[2]} = $v[0] if defined $v[2]
    }
    close $fh;

    return wantarray ? %codes : \%codes;
}

sub _GetVirtualKeyDescriptions {
    my $file = shift;
    my %descr;

    open (my $fh, '<', $file) || throw MPC::Exception("$!: $file");
    while (<$fh>) {
        chomp;
        my @v = split /\t/;

        $v[3] = $v[2];
        $v[2] = "";

        # match key description
        if ($v[3] =~ /'(.+)' key/) {
            $v[2] = $1;
        } elsif ($v[3] =~ /(.+keypad.+?) key/) {
            $v[2] = $1;
        } elsif ($v[3] =~ /(.+?) key/) {
            if (length $1 < 24) {
                $v[2] = $1;
            }
        } elsif ($v[3] =~ /(spacebar)/i) {
            $v[2] = $1;
        }

        $v[0] =~ s/^0x//;
        $v[3] //= "";
        $descr{uc $v[0]} = \@v;
    }
    close $fh;

    return wantarray ? %descr : \%descr;
}

1;
