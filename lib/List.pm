package List;
use List::Util;
use strict;

# Author: Rob Klinkhamer
# $Revision: 1.13 $
# $Date: 2017/06/28 14:26:09 $
# $Source: c:\data\cvs\scripts/perllib/List.pm,v $

sub new {
    my $self = bless {}, shift;
    $self->{entries} = [@_];
    $self;
}

sub add {
    push @{$_[0]{entries}}, @_[1..$#_];
}

sub entries {
    @{$_[0]{entries}};
}

sub clear {
    $_[0]{entries} = [];
}

sub size {
    scalar @{$_[0]{entries}};
}

sub isEmpty {
    ! @{$_[0]{entries}};
}

sub index {
    my ($self, $keys) = @_;

    my %h;
    if (UNIVERSAL::isa($keys, 'ARRAY')) {
        my ($key1, $key2) = @$keys;
        map { push @{$h{ $_->{$key1} }{ $_->{$key2} }}, $_
            } @{$self->{entries}};
    } else {
        map { push @{$h{ $_->{$keys} }}, $_
            } @{$self->{entries}};
    }
    return \%h;
}

sub uniqueindex {
    my ($self, $keys) = @_;

    my %h;
    if (ref $keys eq 'ARRAY') {
        my ($key1, $key2) = @$keys;
        %h = map { $_->{$key1} => $_->{$key2} => $_ } @{$self->{entries}};
    } else {
        %h = map { $_->{$keys} => $_ } @{$self->{entries}};
    }
    return \%h;
}

sub sum {
    my $s = 0;
    $s += $_->{$_[1]}
        foreach @{$_[0]{entries}};
    $s;
}

sub sort {
    my ($self, $key, $cmpsub) = @_;
    my $key2;
    if (UNIVERSAL::isa($key, 'HASH')) {
        ($key, $key2) = each %$key;
    }
    if ($cmpsub && ref $cmpsub) {
        $self->{entries} = [
            $self->_sortSub($self->{entries}, $key,  $cmpsub)
        ];
    } elsif ($self->_isNumeric($self->{entries}, $key, $cmpsub)) {
        $self->{entries} = [
            $self->_sortNum($self->{entries}, $key)
        ];
    } else {
        if ($key2) {
            $self->{entries} = [
                $self->_sortStr2($self->{entries}, $key, $key2)
            ];
        } else {
            $self->{entries} = [
                $self->_sortStr($self->{entries}, $key)
            ];
        }
    }
}

sub shuffle {
    @{$_[0]{entries}} = List::Util::shuffle(@{$_[0]{entries}});
}

sub group {
    my ($self, $keys, $minsize) = @_;
    $self->{minGroupsize} = $minsize || 1;
    $self->{entries} =
        $self->subgroups([$self], $keys);
}

sub subgroups {
    my ($self, $groups, $keys) = @_;
    my $subgroups = [];
    my $key = shift @$keys;
    foreach (@$groups) {
        push @$subgroups,
            $self->groupElements($_->{entries}, $key);
    }
    return $subgroups unless @$keys;
    $self->subgroups($subgroups, $keys);
}

sub groupElements {
    my ($self, $aref, $keyopts) = @_;
    @$aref || return;
    my ($key, $cmpsub, $simsub, $simsubArg) = @$keyopts;

    # sorting
    my @sa;
    my $numeric;
    if ($cmpsub && ref $cmpsub) {
        @sa = $self->_sortSub($aref, $key, $cmpsub);
    } elsif ($numeric = $self->_isNumeric($aref, $key, $cmpsub)) {
        @sa = $self->_sortNum($aref, $key);
    } else {
        @sa = $self->_sortStr($aref, $key);
    }

    # grouping
    if ($simsub && ref $simsub) {
        $self->_groupSub(\@sa, $key, $simsub, $simsubArg);
    } elsif ($numeric) {
        $self->_groupNum(\@sa, $key);
    } else {
        $self->_groupStr(\@sa, $key);
    }
}

sub flatten {
    my $e = [];
    push @$e, @{$_->{entries}}
        foreach @{$_[0]{entries}};
    $_[0]{entries} = $e;
}

sub sim_numapp {
    abs($_[0] - $_[1]) < $_[2];
}
sub _isNumeric {
    my ($type, $aref, $key, $cmpsub) = @_;
    $cmpsub && $cmpsub eq 'numeric'
    or !$cmpsub && @$aref && defined $aref->[0]->{$key} && $aref->[0]->{$key} =~
        /^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/;
        # regular expression for perl numbers, taken from perlretut
}

sub _sortSub {
    my ($type, $aref, $key, $cmpsub) = @_;
    sort {
        defined $a->{$key}
            and defined $b->{$key}
                and $cmpsub->($a->{$key},
                              $b->{$key})
        or not defined $a->{$key}
            and not defined $b->{$key}
                and 0
        or defined $a->{$key}
                and 1
        or defined $b->{$key}
                and -1
    } @$aref;
}

sub _sortNum {
    my ($type, $aref, $key) = @_;
    sort {
        defined $a->{$key}
            and defined $b->{$key}
                and $a->{$key} <=> $b->{$key}
        or not defined $a->{$key}
            and not defined $b->{$key}
                and 0
        or defined $a->{$key}
                and 1
        or defined $b->{$key}
                and -1
    } @$aref;
}

sub sort2 {
    my $self = shift;
    $self->{entries} = [
        $self->sortElements($self->{entries}, _keysFromArgs(@_))
    ];
}

# args := key
#       | [ key ], [ key ]+
# key := hashkeyname*
#      | hashkeyname, cmpsub
#      | [ hashkeyname* ], cmpsub?
sub _keysFromArgs {
    unless (@_) {
        [ [[], 0] ];
    } elsif (UNIVERSAL::isa($_[1], 'ARRAY')) {
        #~ print "[ key ], [ key ]+\n";
        [ map {_getkey(@$_)} @_ ];
    } elsif (UNIVERSAL::isa($_[0], 'CODE')) {
        [ [[], $_[0]] ];
    } else {
        [ _getkey(@_) ];
    }
}

sub _getkey {
    if (UNIVERSAL::isa($_[0], 'ARRAY')) {
        #~ print "key := [ hashkeyname* ], cmpsub?\n";
        [ @_ ];
    } else {
        if (UNIVERSAL::isa($_[1], 'CODE')) {
            #~ print "key := hashkeyname, cmpsub\n";
            [[$_[0]], pop];
        } else {
            #~ print "key := hashkeyname*\n";
            map { [[$_], 0] } @_;
        }
    }
}

sub sortElements {
    my ($self, $aref, $keys) = @_;
    #~ print "---\n";
    my $cmp;
    my $i = 0;
    foreach my $key (@$keys) {
        #~ foreach (@{$key->[0]}) {
            #~ print "$_ ";
        #~ }
        #~ print "($key->[1])" if $key->[1];
        #~ print "\n";

        my $kstr = '';
        foreach (@{$key->[0]}) {
            $kstr .= "->{$_}";
        }
        $cmp .= ' or ' if $cmp;
        if (ref $key->[1] eq 'CODE') {
            if ($key->[1] == \&numeric) {
                $cmp .= "\$a$kstr <=> \$b$kstr";
            } else {
                $cmp .= "\$keys->[$i][1]->(\$a$kstr, \$b$kstr)";
            }
        #~ } elsif (
            #~ eval '
                #~ foreach (@$aref) {
                    #~ return unless
                    #~ defined $_'.$kstr.'
                    #~ && $_'.$kstr.' =~
                    #~ /^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/
                #~ }1'
            # regular expression for perl numbers, taken from perlretut
        #~ ) {
            #~ $cmp .= "\$a$kstr <=> \$b$kstr";
        } else {
            $cmp .= "\$a$kstr cmp \$b$kstr";
        }
    } continue {
        $i++;
    }
    #~ my $s;
    #~ if ('undefs') {
        #~ $s =
#~ "defined \$a$key
    #~ and defined \$b$key
        #~ and $cmp
#~ or not defined \$a$key
    #~ and not defined \$b$key
        #~ and 0
#~ or defined \$a$key
        #~ and 1
#~ or defined \$b$key
        #~ and -1";
    #~ } else {
        #~ $s = $cmp;
    #~ }
    #~ print "sort {\n$cmp} \@\$aref\n";
    eval "sort {$cmp} \@\$aref";
}

sub numeric { }

sub _sortStr {
    my ($type, $aref, $key) = @_;
    sort {
        defined $a->{$key}
            and defined $b->{$key}
                and $a->{$key} cmp $b->{$key}
        or not defined $a->{$key}
            and not defined $b->{$key}
                and 0
        or defined $a->{$key}
                and 1
        or defined $b->{$key}
                and -1
    } @$aref;
}
sub _sortStr2 {
    my ($type, $aref, $key1, $key2) = @_;
    sort {
        defined $a->{$key1}{$key2}
            and defined $b->{$key1}{$key2}
                and $a->{$key1}{$key2} cmp $b->{$key1}{$key2}
        or not defined $a->{$key1}{$key2}
            and not defined $b->{$key1}{$key2}
                and 0
        or defined $a->{$key1}{$key2}
                and 1
        or defined $b->{$key1}{$key2}
                and -1
    } @$aref;
}

sub _groupSub {
    my ($self, $a, $key, $simsub, $simsubArg) = @_;
    my @groups;
    my $match = 1;
    for (my $i=1; $i<@$a; $i++) {
        if (    defined $a->[$i  ]->{$key}
            and defined $a->[$i-1]->{$key} # compare if both values are defined
            and $simsub->($a->[$i  ]->{$key}, # using custom comparison sub
                          $a->[$i-1]->{$key},
                          $simsubArg)
        or      not defined $a->[$i  ]->{$key}
            and not defined $a->[$i-1]->{$key}) # two undefined values are also equal
        {
            $match++;
        } else {
            if ($match >= $self->{minGroupsize}) {
                push @groups,
                    new List([@$a[$i-$match..$i-1]]);
            }
            $match = 1;
        }
    }
    if ($match >= $self->{minGroupsize}) {
        push @groups,
            new List([@$a[@$a-$match..@$a-1]]);
    }
    @groups;
}

sub _groupNum {
    my ($self, $a, $key) = @_;
    my @groups;
    my $match = 1;
    for (my $i=1; $i<@$a; $i++) {
        if (    defined $a->[$i  ]->{$key}
            and defined $a->[$i-1]->{$key} # compare if both values are defined
            and $a->[$i]->{$key} == $a->[$i-1]->{$key} # using numeric comparison
        or      not defined $a->[$i  ]->{$key}
            and not defined $a->[$i-1]->{$key}) # two undefined values are also equal
        {
            $match++;
        } else {
            if ($match >= $self->{minGroupsize}) {
                push @groups,
                    new List([@$a[$i-$match..$i-1]]);
            }
            $match = 1;
        }
    }
    if ($match >= $self->{minGroupsize}) {
        push @groups,
            new List([@$a[@$a-$match..@$a-1]]);
    }
    @groups;
}

# XXX NOT TESTED!!
sub _groupStr {
    my ($self, $a, $key) = @_;
    my @groups;
    my $match = 1;
    my $addGroup = 0;
    # lookahead by 1
    for (my $i=0; $i<@$a-1; $i++) {
        if (    defined $a->[$i  ]->{$key}
            and defined $a->[$i+1]->{$key} # compare if both values are defined
            and $a->[$i]->{$key} eq $a->[$i+1]->{$key} # using string comparison
        or      not defined $a->[$i  ]->{$key}
            and not defined $a->[$i+1]->{$key}) # two undefined values are also equal
        {
            # i=0=1 i+1=1=1 @$a=2 match=2
            $match++;
            $addGroup = $i == @$a-2; # addGroup if end of list
        } else {
            # i=0=0 i+1=1=1 @$a=2 match=1
            $addGroup = 1;
        }
        if ($addGroup) {
            if ($match >= $self->{minGroupsize}) {
                push @groups,
                    new List([@$a[$i+2-$match .. $i+1]]); # creates copy?
            }
            $match = 1;
            $addGroup = 0;
        }
    }
    return @groups;
}

1;

__END__

$l->sort($cmpsub)           # sort elements using cmp sub
$key = [@keynames, $cmpsub] # key to element value, optional cmp sub
$l->sort(@keys);            # sort by key
$l->sort([@keys]);          # sort by key[0] or key[1] or ..

$a = [];
$l = new List($a);
$l->sort();
$l->sort(\&List::numeric);          # Explicit numeric sorting
$l->sort('key');                    # sort by $_->{key}
$l->sort(['key', \&List::numeric]); # sort by $_->{key}, numeric
$l->sort(['key', \&mycmp]);         # sort by $_->{key}, custom cmp sub
$l->sort('keyA', 'keyB');           # sort by $_->{keyA}{keyB}
$l->sort([['keyA', 'keyB'],         # sort by $_->{keyA}{keyB}, numeric
    \&List::numeric]);
$l->sort(['key1', 'key2']);         # sort by $_->{key1} or $_->{key2}
$l->sort(['key1', \&List::numeric], # sort by $_->{key1} (numeric) or $_->{key2}
         ['key2']);

$l->group(
    [['key',  undef, \&List::sim_numapp, .02 ],
     ['key2', \&List::numeric]
    ], 2
);
