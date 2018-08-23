=begin TML

---+ package Interactive::Term::ReadKey
Console user i/o widgets using Term::ReadKey.

=cut

package Interactive::Term::ReadKey;
use parent 'Interactive::Default';

use strict;
use warnings;

use Term::ReadKey ();

sub print {
    my $self = shift;
    chomp $_[-1];
    print @_, "\n";
}

###############################################################################
=pod

---++ readChar() -> $string
See =Interactive::ReadChar()=.

=cut
###############################################################################

sub readChar {
    my $k = Term::ReadKey::ReadKey(2**28); # wait for 8.5 years
    print "$k\n";
    return $k;
}

1;
