=begin TML

---+ package Console

Console input/output functionality.

=cut

package Console;

###############################################################################
=pod

---++ Object creation

---+++ new() -> $console
Returns a new =Console= object.

=cut
###############################################################################

sub new {
    my $self = bless {}, shift;

    if ($^O eq 'MSWin32') {
        use Win32::Console; #FIXME using "use" conditionally has "no use" :)~
        require Win32::Console::ANSI;
        $self->{wcStdOut} = new Win32::Console(STD_OUTPUT_HANDLE);
        $self->{wcStdIn} = new Win32::Console(STD_INPUT_HANDLE);
    } else {
        die "Console not supported";
    }

    $self->{grid} = undef;
    $self->{print} = 1;
    return $self;
}

###############################################################################
=pod

---++ Info

---+++ columns()
First element in array returned by
=[[http://search.cpan.org/~jdb/Win32-Console-0.10/Console.pm][Win32::Console]]::Info=.
---+++ title()
See =[[http://search.cpan.org/~jdb/Win32-Console-0.10/Console.pm][Win32::Console]]::Title=.
---+++ getEvents()
See =[[http://search.cpan.org/~jdb/Win32-Console-0.10/Console.pm][Win32::Console]]::GetEvents=.

=cut
###############################################################################

sub columns   { ($_[0]->{wcStdOut}->Info)[0] }
sub cursor    { shift->{wcStdOut}->Cursor(@_) }
sub row       { ($_[0]->{wcStdOut}->Cursor)[1] }
sub title     { $_[0]->{wcStdOut}->Title($_[1]) }
sub getEvents { $_[0]->{wcStdIn}->GetEvents() }

###############################################################################
=pod

---++ Write

---+++ write()
See =[[http://search.cpan.org/~jdb/Win32-Console-0.10/Console.pm][Win32::Console]]::Write=.
---+++ flush()
See =[[http://search.cpan.org/~jdb/Win32-Console-0.10/Console.pm][Win32::Console]]::Flush=.

=cut
###############################################################################

sub write     { $_[0]->{wcStdOut}->Write($_[1]) }
sub flush     { $_[0]->{wcStdIn}->Flush() }

sub pauseIfNoPrompt {
    my $self = shift;
    return if $ENV{PROMPT} || $ENV{PS1};
    while (1) {
        my @event = $self->{wcStdIn}->Input();
        last if $event[0]
            and $event[0] == 1 # keyboard
            and $event[1] # key pressed
            and $event[5] > 0; # any key
    }
}

sub askConfirm {
    my ($self, $question) = @_;
    my $key = '';

    $self->{wcStdOut}->Write("$question ");
    while (1) {
        my @event = $self->{wcStdIn}->Input();

        if ($event[0]
        and $event[0] == 1 # keyboard
        and $event[1] # key pressed
        ) {
            $key = chr($event[5]); # ascii char
            last if $event[5] > 0;
        }
    }
    print "$key\n" if $self->{print};
    return lc $key eq 'y'
}

sub ask {
    my ($self, $question, $choices) = @_;

    $self->{wcStdOut}->Write("$question (");
    $self->{wcStdOut}->Write(join "/", map { $_->[1] } @$choices);
    $self->{wcStdOut}->Write(") ");

    my %retvals = map { $_->[0] => $_->[2] } @$choices;
    my $key = chr(0);
    do {
        my @event = $self->{wcStdIn}->Input();
        if (@event && $event[0] == 1 and $event[1]) {
            $key = chr $event[5];
        }
    } while (! grep { /$key/ } keys %retvals);

    $self->{wcStdOut}->Write("$key\n");

    my $ret = $retvals{$key};
    return ref $ret && ref $ret eq 'CODE' ? $ret->() : $ret;
}

sub select {
    my ($self, $choices) = (shift, shift);
    my %opts = @_;

    my $i = 0x31;
    foreach (@$choices) {
        $self->{wcStdOut}->Write(chr($i) . ". $_\n");
        die if ++$i > 0x31 + 9; # 1-9
    }

    my $key = 0;
    while (1) {
        my @event = $self->{wcStdIn}->Input();
        if (@event && $event[0] == 1 and $event[1]) {
            $key = $event[5];
            if ($key >= 0x31 and $key < 0x31 + @$choices) {
                $key -= 0x31;
                last;
            } elsif ($key == 27 && ! $opts{required}) {
                $key = undef;
                last;
            }
        }
    }
    return $key;
}

sub question {
    my ($self, $question, $value) = @_;

    my $c = $self->{wcStdOut};
    my $columns = ($c->Info)[0];
    return if 10 + length $question > $columns; # not enough columns
    $value = substr $value, 0, $columns - 2 - length $question; # chop value to fit on line

    $c->Write($question);
    my @startCursor = $c->Cursor;
    my $homePos = $startCursor[0];

    $c->Write($value);
    my $endPos = $startCursor[0] + length $value;

    my $key = 0;
    my $prevKey = 0;
    do {
        my @event = $self->{wcStdIn}->Input();
        if (@event && $event[0] == 1 and $event[1]) {
            $key = $event[5];
            my @c = $c->Cursor;
            my $pos = $c[0];
            if ($event[3] == 8) { # backspace
                if ($c[0] > $homePos) {
                    my $r = $c->ReadChar($endPos - $c[0] + 1, @c[0..1]);
                    $c[0]--;
                    $c->Cursor(@c);
                    $c->Write($r . " ");
                    $endPos--;
                }
            } elsif ($event[3] == 27) { # escape
                # reset
                $c->Cursor(@startCursor);
                $c->Write(" " x ($endPos - $homePos));
                $c->Cursor(@startCursor);
                $endPos = $startCursor[0];
                if ($prevKey != 27) {
                    $c->Write($value);
                    $endPos += length $value;
                }
                $c[0] = $endPos;
            } elsif ($event[3] == 35) { # end
                $c[0] = $endPos;
            } elsif ($event[3] == 36) { # home
                $c[0] = $homePos;
            } elsif ($event[3] == 37) { # left
                if ($c[0] > $homePos) {
                    $c[0]--;
                }
            } elsif ($event[3] == 39) { # right
                if ($c[0] < $endPos) {
                    $c[0]++;
                }
            } elsif ($event[3] == 46) { # delete
                if ($c[0] < $endPos) {
                    $c[0]++;
                    my $r = $c->ReadChar($endPos - $c[0] + 1, @c[0..1]);
                    $c[0]--;
                    $c->Cursor(@c);
                    $c->Write($r . " ");
                    $endPos--;
                }
            } elsif ($key >= 20) {
                if ($endPos < $columns - 2) { # multi-line edit not supported
                    $c->Write(chr($key) . $c->ReadChar($endPos - $c[0] + 1, @c[0..1]));
                    $c[0]++;
                    $endPos++;
                }
            }
            $c->Cursor(@c);
            $prevKey = $prevKey == 27 ? 0 : $event[3];
            #~ print "$event[3]\n";
        }
    } while ($key != 13); # enter

    my $input = $c->ReadChar($endPos - $homePos, @startCursor[0..1]);
    print "\n";

    return $input;
}

###############################################################################
=pod

---+++ newline()
Ensure we're on a new line, i.e. if we're not at the
start of a line, go to the start of the next.

=cut
###############################################################################

sub newline {
    my ($self) = @_;
    my @c = $self->{wcStdOut}->Cursor;
    if ($c[0] > 0) {
        $c[0] = 0;
        $c[1]++;
        $self->{wcStdOut}->Cursor(@c);
    }
}

###############################################################################
=pod

---+++ printLine($string, $trim)
Print string after ensuring we're on a new line (see =newline()=).
Trims string to fit on one line if =$trim= has a true value.
Appends a newline character.

=cut
###############################################################################

sub printLine {
    my ($self, $str, $trim) = @_;
    $self->newline;
    my $columns = ($self->{wcStdOut}->Info)[0];
    print substr($str, 0, $columns); # chop string to fit on line
    print "\n" if length $str < $columns;
}

###############################################################################
=pod

---+++ updateLine($string, $trim)
Clears current line and prints string from the start of the line.
Trims string to fit on one line if =$trim= has a true value.

=cut
###############################################################################

sub updateLine {
    my ($self, $str, $trim) = @_;

    # get cursor position
    my @c = $self->{wcStdOut}->Cursor;
    my $x = $c[0];

    # adjust string
    if ($trim || $x) {
        # chomp newlines
        my $chomped = 0;
        $chomped++ while chomp $str;

        my $columns = ($self->{wcStdOut}->Info)[0] - 1;
        my $length = length $str;

        if ($trim) {
            # trim to console width
            if ($columns < $length) {
                $str = substr $str, 0, $columns;
                $length = $columns;
            }
        }

        if ($x) {
            # erase previous text
            my $b = $x - $length;
            if ($b > 0) {
                $c[0] = $length;
                $self->{wcStdOut}->Cursor(@c);
                $self->{wcStdOut}->Write(" " x $b);
            }
            # go to start of line
            $c[0] = 0;
            $self->{wcStdOut}->Cursor(@c);
        }

        # append chomped newlines
        $str .= "\n" x $chomped;
    }

    $self->{wcStdOut}->Write($str);
}

###############################################################################
=pod

---+++ lineUp()

=cut
###############################################################################

sub lineUp {
    my $self = shift;
    my @c = $self->{wcStdOut}->Cursor;
    $c[1]--;
    $self->{wcStdOut}->Cursor(@c);
}

###############################################################################
=pod

---++ Input

---+++ input()
See =[[http://search.cpan.org/~jdb/Win32-Console-0.10/Console.pm][Win32::Console]]::Input=.

=cut
###############################################################################

sub input     { $_[0]->{wcStdIn}->Input() }

###############################################################################
=pod

---++ Other methods

=cut
###############################################################################

sub setGrid {
    my ($self, $class, $template, $values) = @_;
    $self->{grid} = $class->new($self->{wcStdOut});
    $self->{grid}->setup($template, $values);
}

sub updateGrid {
    my ($self, $values) = @_;
    $self->{grid}->update($values);
}

1;
