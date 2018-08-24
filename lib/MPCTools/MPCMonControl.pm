package MPCTools::MPCMonControl;

use strict;
use warnings;

use Cwd qw(getcwd);

use Console;

sub new {
    my $self = bless {}, shift;
    $self->{mpcMon} = shift;
    $self->{console} = new Console();
    return $self;
}

sub init {
    my $self = shift;
    $self->{opts} = shift;
    $self->{actions} = shift;
    return $self;
}

sub start {
    my $self = shift;

    my $cwd = getcwd;
    $self->{console}->title("$self->{opts}{windowTitle} | $cwd");
    if ($self->{opts}{verbose}) {
        printf "Polling every %u second%s\n",
            $self->{opts}{pollingInterval},
            $self->{opts}{pollingInterval} == 1 ? "" : "s";
    }

    $self->{mpcMon}->status;

    while (1) {
        if ($self->{opts}{'Directory monitor'}) {
            print "Poll\n" if $self->{opts}{debug};
            $self->{mpcMon}->poll;
        }
        $self->handleInput;
    } continue {
        sleep $self->{opts}{pollingInterval};
    }
}

sub handleInput {
    my $self = shift;
    while ($self->{console}->getEvents) {
        my @event = $self->{console}->input;
        next if !@event or $event[0] != 1 or !$event[1];
        print "@event\n" if $self->{opts}{debug};
        if ($event[5]) {                    # ASCII
            Quit() if $event[5] == 27;      # Esc
            my $key = chr $event[5];
            if ($self->{actions}{$key}) {
                $self->{actions}{$key}->();
            } elsif ($key =~ /^\w$/) {
                print "Not an action key: $key\n" unless $self->{opts}{quiet};
            }
        } elsif ($event[3] == 112) {        # F1
            Help();
        }
    }
    $self->{console}->flush;    # empty buffer
}

1;
