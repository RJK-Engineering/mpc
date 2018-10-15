=begin TML

---+ package MPC::Status

HTML

<verbatim class="html">
    <p id="filepatharg">C%3a%5ctemp%5cNOS%20Studio%20Sport_20160130_1600.ts</p>
    <p id="filepath">C:\temp\NOS Studio Sport_20160130_1600.ts</p>
    <p id="filedirarg">C%3a%5ctemp</p>
    <p id="filedir">C:\temp</p>
    <p id="state">2</p>
    <p id="statestring">Playing</p>
    <p id="position">5161021</p>
    <p id="positionstring">01:26:01</p>
    <p id="duration">7617080</p>
    <p id="durationstring">02:06:57</p>
    <p id="volumelevel">85</p>
    <p id="muted">0</p>
    <p id="playbackrate">1</p>
    <p id="reloadtime">0</p>
</verbatim>

   * [durationstring] if file is a Live set string to "Live"
   * [duration] file length in seconds (Live = -1)
   * [state] state of playback (paused = 1, playing = 2, stopped = 0, Buffering %x = (-x-1) ) (x=(-1to-101))
   * [playbackrate] rate of playback, any float, setting to 0 is the same as state=0
   * [reloadtime] reload of the page, use for when the client is buffering (eta in seconds)
   * [muted] (nosound=-1, muted=0, notmuted = 1)
   * [volumelevel] (0->255)

=cut

package MPC::Status;

use strict;
use warnings;

use constant {
    PAUSED => 1,
    PLAYING => 2,
    STOPPED => 0,
    NA => -1,
    OFFLINE => -2,
};

our @ISA = qw( Exporter );
use Exporter ();
our @EXPORT_OK = qw(PAUSED PLAYING STOPPED NA OFFLINE);
our %EXPORT_TAGS = (constants => [qw(PAUSED PLAYING STOPPED NA OFFLINE)]);

our @fields;

BEGIN {
    @fields = qw(
        file filepatharg filepath filedirarg filedir state statestring
        position positionstring duration durationstring
        volumelevel muted playbackrate size reloadtime version
        time
    );
}

use Class::AccessorMaker {
    map { $_ => $_ eq 'state' ? OFFLINE : "" } @fields,
};

sub online {
    shift->state != OFFLINE;
}

sub TO_JSON {
    my $hash = {%{shift()}};
    return $hash;
}

1;
