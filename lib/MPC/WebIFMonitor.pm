package MPC::WebIFMonitor;

use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use MPC::Status qw(:constants);
use Time::HiRes qw( gettimeofday tv_interval );

sub new {
    my $self = bless {}, shift;
    my %opts = @_;

    $opts{port} ||= 13579;
    $opts{url} ||= "http://localhost:$opts{port}/variables.html";
    $opts{requestAgent} ||= "MyApp/0.1";
    $opts{requestTimeout} ||= 5;
    $opts{offlineTimeout} ||= 30;

    $opts{na} ||= sub {};
    $opts{offline} ||= sub {};
    $opts{online} ||= sub {};
    $opts{start} ||= sub {};
    $opts{stop} ||= sub {};
    $opts{pause} ||= sub {};
    $opts{resume} ||= sub {};

    $self->{opts} = \%opts;
    $self->{stats} = {};
    return $self;
}

sub stats { shift->{stats} }

sub init {
    my $self = shift;

    $self->{UserAgent} = LWP::UserAgent->new;
    $self->{UserAgent}->agent($self->{opts}{requestAgent});

    $self->{opts}{url} or die "No url";
    # Create a request
    $self->{HttpRequest} = HTTP::Request->new(GET => $self->{opts}{url});

    $self->{UserAgent}->timeout($self->{opts}{requestTimeout} || 30);
    #~ $self->{sensitivity} = 1;

    $self->{d_timeout} = 0;
    return $self;
}

sub poll {
    my $self = shift;

    my $prevStatus = $self->{prevStatus} = $self->{status} // new MPC::Status;
    my $prevState = $prevStatus->state;
    my $currStatus = $self->{status} = $self->getStatus;
    my $currState = $currStatus->state;
    #~ $currStatus->{prevStatus} = $prevStatus; # NOT REMOVED FROM MEMORY, NEEDS CLEANUP

    #~ printf "%s %s %s %s\n", $prevState, $currState,
    #~     $prevStatus->filepath, $currStatus->filepath;

    #~ $self->otherFilePlaying($prevStatus, $currStatus);
    if ($prevState == PLAYING || $prevState == PAUSED) {
        my $prevFile = $prevStatus->filepath;
        #~ print "$prevFile ne\n$currStatus->{filepath}\n";
        if ($prevFile && $prevFile ne $currStatus->filepath) {
            # started playing another file
            $self->_stop($prevStatus);
            $prevState = $prevStatus->{state} = STOPPED;
        }
    }
    if ($self->skippedPosition($currStatus)) {
        $self->_stop($currStatus);
        $self->_start($currStatus);
    }

    if ($prevState == $currState) {
        # no state change
        return;
    } elsif ($prevState == OFFLINE) {
        # program start/online
        if (! $self->{t_online}) { # need to check because prevStatus is kept if currState == NA
            #~ $self->_online();
            $self->{t_online} = time;
            $self->{opts}{online}->($currStatus, $self->{stats});
        }
    } elsif ($currState == OFFLINE) {
        # program exit/offline
        if ($prevState != STOPPED) {
            $self->_stop($currStatus);
        }
        #~ $self->_offline($state, $prevState);
        $self->_offline();
        return;
    }

    if ($currState == NA) {
        # wait for state, keep previous status
        if (! $self->{waitingForState}) {
            $self->{opts}{na}->($currStatus, $self->{stats});
            $self->{waitingForState} = 1;
        }
        $self->{status} = $prevStatus;
    } else {
        $self->{waitingForState} = 0;
        if ($currState == PLAYING) {
            if ($prevState == PAUSED) {
                $self->{opts}{resume}->($self->{status}, $self->{stats});
            }
            #~ $self->_start($self->{status});
        } elsif ($currState == PAUSED) {
            $self->{opts}{pause}->($self->{status}, $self->{stats});
            if ($prevState != STOPPED) {
                #~ $self->_stop($self->{status});
            }
        } elsif ($currState == STOPPED) {
            $self->_stop($self->{status});
        }
    }
}

sub skippedPosition {
    my ($self, $currStatus) = @_;
    $currStatus->state == PLAYING ||
    $currStatus->state == PAUSED || return;

    my $ct = [gettimeofday];
    my $cp = $currStatus->position;
    my $s;
    if (my $pt = $self->{stats}{prevtime}) {
        my $pp = $self->{stats}{prevpos};
        my $pdiff = ($cp - $pp) / 1000;
        my $lm;
        if ($pdiff) {
            $self->{stats}{lastmove} = $pp;
        } elsif ($lm = $self->{stats}{lastmove}) {
            $pdiff = ($cp - $lm) / 1000;
        }
        if ($pdiff) {
            my $td = tv_interval($pt, $ct);
            $ct = $pt if $lm; # keep time of lastmove
            my $d = $td / $pdiff;
            printf "Duration $td / $pdiff = $d\n";
            $s = $d < .01 || $d > 1000;
        }
    }
    $self->{stats}{prevtime} = $ct;
    $self->{stats}{prevpos} = $cp;
    return $s;
}

sub getStatus {
    my $self = shift;
    my $status = new MPC::Status;

    # Pass request to the user agent and get a response back
    my $res = $self->{UserAgent}->request($self->{HttpRequest});
    $status->{time} = time;

    # Check the outcome of the response
    if ($res->is_success) {
        #~ print substr($res->content,0,1000);
        foreach (split /^/, $res->content) {
            if (m|<p id="(\w+)">(.+)</p>|) {
                $status->{$1} = $2;
                utf8::decode $status->{$1};
            }
        }
    }
    return $status;
}

sub _online {
    my ($self, $currState, $prevState) = @_;

    if ($currState == PLAYING) {
        if ($prevState == PAUSED) {
        #~     #~ if ($self->{t_pause}) {
        #~     # end pause timing
        #~     $self->{d_pause} += time - $self->{t_pause};
        #~     $self->_calculateTimes;
        #~     undef $self->{t_pause};
            $self->{opts}{resume}->($self->{status}, $self->{stats});
        } else {
        #~ # begin file open timing
        #~ $self->{t_start} = time;
        #~ $self->{d_pause} = 0;
            $self->_start($self->{status});
        }
    } elsif ($currState == PAUSED) {
        #~ # begin pause timing
        #~ $self->{t_pause} = time;
        #~ $self->_calculateTimes;
        $self->{opts}{pause}->($self->{status}, $self->{stats});
    } elsif ($currState == STOPPED) {
        $self->_stop($self->{status});
    }
}

sub _offline {
    my $self = shift;

    $self->{opts}{offline}->($self->{status}, $self->{stats});
    #~ $self->{t_offline} = time;

    #~ if ($self->{t_offline} + $self->{opts}{offlineTimeout} <= time) {
    #~     $self->{d_timeout} = $self->{opts}{offlineTimeout};
    #~     $self->{d_timeout} = 0;
    #~     undef $self->{t_offline};
    #~ }

    undef $self->{t_online};
}

# start -> pause -> resume -> stop
# t_start  t_pause
#          \___d_pause___/
# \____________d_total___________/
# d_play = d_total - d_pause

sub _start {
    my ($self, $status) = @_;
    $self->{t_start} = time;
    $self->{stats}{start} = $status->position;
    $self->{stats}{duration} = 0;
    $self->{opts}{start}->($status, $self->{stats});
}

sub _stop {
    my ($self, $status) = @_;
    return unless $self->{t_start};

    #~ # end pause timing
    #~ if ($self->{t_pause}) {
    #~     $self->{d_pause} += time - $self->{t_pause};
    #~     undef $self->{t_pause};
    #~ }

    #~ $self->_calculateTimes;
    #~ $self->{stats}{playingtimeTotal} =
    #~ $self->{playingtimeTotal} += $self->{stats}{playingtime};

    $self->{stats}{duration} = time - $self->{t_start};
    undef $self->{t_start};

    $self->{opts}{stop}->($status, $self->{stats});
}

#~ sub _calculateTimes {
#~     my $self = shift;

#~     my $d_total = time - $self->{t_start} - $self->{d_timeout};
#~     $self->{stats}{opentime} = $d_total;
#~     $self->{stats}{pausedtime} = $self->{d_pause};

#~     my $d_play = $d_total - $self->{d_pause};
#~     $self->{stats}{playingtime} = $d_play;
#~ }

1;
