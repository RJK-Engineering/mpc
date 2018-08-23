=begin TML

---+ package Interactive
Console user i/o widgets.

=cut

package Interactive;

use strict;
use warnings;

use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = our @EXPORT_OK = qw(Ask ReadLine Confirm ItemFromList Pause);

my $handler;

sub SetClass {
    my $class = shift // 'Default';
    $class = "Interactive::$class";
    eval "require $class";
    die "Could not import $class" if $@;
    $handler = $class->new;
}

###############################################################################
=pod

---++ Ask($question, %opts) -> $answer
    =$question= - Question to be printed.
    =$opts{keys}= - Possible answers.
    =$opts{default}= - Default answer.
    =$opts{strict}= - Ask again if answer is invalid.
    =$answer= - User input.

=cut
###############################################################################

sub Ask {
    $handler || SetClass();
    $handler->ask(@_);
}

###############################################################################
=pod

---++ Confirm($question, $ok) -> $boolean
    =$question= - Question to be printed.
    =$ok= - Default return value.

Prints =$question (y/n)=.
Returns =1= if the answer is =y=, returns =$ok= otherwise.

=cut
###############################################################################

sub Confirm {
    $handler || SetClass();
    $handler->confirm(@_);
}

###############################################################################
=pod

---++ ItemFromList($list) -> $answer
    =$list= - Array reference.
    =$answer= - Value from $list.

=cut
###############################################################################

sub ItemFromList {
    $handler || SetClass();
    $handler->itemFromList(@_);
}

###############################################################################
=pod

---++ ReadChar() -> $string
Read a character.

=cut
###############################################################################

sub ReadChar {
    $handler || SetClass();
    $handler->readChar(@_);
}

###############################################################################
=pod

---++ ReadLine() -> $string
Read a line.

=cut
###############################################################################

sub ReadLine {
    $handler || SetClass();
    $handler->readLine(@_);
}

###############################################################################
=pod

---++ Pause()
Wait for any user input.

=cut
###############################################################################

sub Pause {
    $handler || SetClass();
    $handler->pause(@_);
}

1;
