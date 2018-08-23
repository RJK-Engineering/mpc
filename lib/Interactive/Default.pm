=begin TML

---+ package Interactive::Default
Default functionality for class Interactive.

=cut

package Interactive::Default;

use strict;
use warnings;

sub new {
    return bless {}, shift;
}

sub print {
    my $self = shift;
    print @_;
}

###############################################################################
=pod

---++ ask($question, %opts) -> $answer
See =Interactive::Ask()=.

=cut
###############################################################################

sub ask {
    my ($self, $question, %opts) = @_;

    $self->print("$question ");
    my $a = $self->readChar;
    if ($opts{keys}) {
        my @answers = keys %{$opts{keys}};
        my $valid;
        foreach (@answers) {
            next if $a !~ /^$_$/i;
            $valid = 1;
            last if !$opts{keys}{$_};
            $opts{keys}{$_}->();
            last;
        }
        if ($opts{strict} && !$valid) {
            $self->print("Invalid answer\n");
        }
    }
    return $a;
}

###############################################################################
=pod

---++ confirm($question, $ok) -> $boolean
See =Interactive::Confirm()=.

=cut
###############################################################################

sub confirm {
    my ($self, $question, $ok) = @_;
    $question //= "Are you sure?";
    $question = "$question (y/n)" if $question;
    $self->ask($question, keys => { y => sub { $ok = 1 } });
    return $ok;
}

###############################################################################
=pod

---++ itemFromList($list) -> $answer
See =Interactive::ItemFromList()=.

=cut
###############################################################################

sub itemFromList {
    my ($self, $list) = @_;
    my $i = 1;
    foreach (@$list) {
        $self->print($i++, ") $_\n");
        last if $i==9;
    }
    my $n = $self->readChar;

    if ($n =~ /^\d+$/ && $n>0 && $n<=@$list) {
        return $list->[$n-1];
    }
}

###############################################################################
=pod

---++ readChar() -> $string
See =Interactive::ReadChar()=.

=cut
###############################################################################

sub readChar {
    my $self = shift;
    # no standard way of reading a character, read a line
    return substr $self->readLine, 0, 1;
}

###############################################################################
=pod

---++ readLine() -> $string
See =Interactive::ReadLine()=.

=cut
###############################################################################

sub readLine {
    local $_ = <STDIN>;
    chomp;
    return $_;
}

###############################################################################
=pod

---++ pause()
See =Interactive::Pause()=.

=cut
###############################################################################

sub pause {
    my $self = shift;
    $self->readChar;
}

1;
