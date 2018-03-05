###############################################################################
=begin TML

---+ package File::Ini
Read and write INI files.

=cut
###############################################################################

package File::Ini;

use strict;
use warnings;
use PropertyList;
use Data::Compare;
use File::IniCompareResult;

###############################################################################
=pod

---++ Object Creation

---+++ new($path) -> $ini
   * =$path= - path to ini file
   * =$ini= - new =File::Ini= object

=cut
###############################################################################

sub new {
    my $self = bless {}, shift;
    $self->{file} = shift;
    return $self;
}

###############################################################################
=pod

---++ INI Sections

---+++ sections() -> @array or $array
   * =@array= - section names
   * =$array= - reference to @array

---+++ totalSections() -> $numberOfSections

---+++ newSection($section) -> $propertyList
   * =$section= - section name
   * =$propertyList= - =PropertyList= object for new
     section or =undef= if section already exists

---+++ setSection($ini, $section) -> $propertyList
   * =$ini= - =File::Ini= object to reference to
   * =$section= - section name
   * =$propertyList= - =PropertyList= object for the section

Set reference to a section in another =File::Ini= object.

---+++ allSections() -> %hash or $hash
   * =%hash= - section => property => value
   * =$hash= - reference to %hash

Return all sections as a hash.

=cut
###############################################################################

sub sections {
    wantarray ? @{$_[0]{sections}} : $_[0]{sections};
}

sub totalSections {
    scalar @{$_[0]{sections}};
}

sub newSection {
    my ($self, $section) = @_;
    return if $self->getPropertyList($section);
    $self->_newSection($section);
}

sub _newSection {
    my ($self, $section) = @_;
    push @{$self->{sections}}, $section;
    $self->{keys}{$section} = [];
    return $self->{properties}{$section} = new PropertyList;
}

# no deep copy!
sub setSection {
    my ($self, $section, $ini) = @_;
    my $pl = $self->getPropertyList($section) || $self->_newSection($section);
    $self->{keys}{$section} = $ini->{keys}{$section};
    $self->{properties}{$section} = $ini->{properties}{$section};
}

sub allSections {
    my ($self, $type) = @_;
    my %all;
    foreach my $section (@{$self->{sections}}) {
        $all{$section} = $self->getPropertyList($section)->hash;
    }
    return wantarray ? %all : \%all;
}

###############################################################################
=pod

---++ Section Properties
Properties are key/value pairs.

---+++ getPropertyList($section) -> $propertyList
   * =$section= - section name
   * =$propertyList= - =PropertyList= object for the section

---+++ getKeys($section) -> @array or $array
   * =$section= - section name
   * =@array= - key array
   * =$array= - reference to @array

---+++ getValues($section) -> @array or $array
   * =$section= - section name
   * =@array= - value array
   * =$array= - reference to @array

---+++ getSection($section) -> $hash or %hash
   * =$section= - section name
   * =$hash= - property hash reference
   * =%hash= - property hash

---+++ get($section, $key) -> $value
   * =$section= - section name
   * =$key= - key name
   * =$value= - property value

=cut
###############################################################################

sub getPropertyList {
    my $properties = $_[0]{properties};
    exists $properties->{$_[1]} || return;
    return $properties->{$_[1]};
}

# ordered list
sub getKeys {
    my $keys = $_[0]{keys};
    exists $keys->{$_[1]} || return;
    return wantarray ? @{$keys->{$_[1]}} : $keys->{$_[1]};
}

sub getValues {
    my $pl = $_[0]->getPropertyList($_[1]) || return;
    return wantarray ? $pl->values : [ $pl->values ];
}

sub getSection {
    my $pl = $_[0]->getPropertyList($_[1]) || return;
    return wantarray ? %{$pl->hash} : $pl->hash;
}

sub get {
    my $pl = $_[0]->getPropertyList($_[1]) || return;
    return $pl->get($_[2]);
}

###############################################################################
=pod

---+++ set($section, $key, $value) -> $value
Set property.
Add property to end of section if not existing.

---+++ append($section, $key, $value) -> $propertyList
Add property to end of section.
Does not check for existing property, may result in duplicates.

---+++ prepend($section, $key, $value) -> $propertyList
Add property to beginning of section.
Does not check for existing property, may result in duplicates.

=cut
###############################################################################

sub set {
    my ($self, $section, $key, $value) = @_;
    my $pl = $self->getPropertyList($section) || $self->_newSection($section);
    push @{$self->{keys}{$section}}, $key if ! $pl->has($key);
    $pl->set($key, $value);
}

sub prepend {
    my ($self, $section, $key, $value) = @_;
    my $pl = $self->getPropertyList($section) || $self->_newSection($section);
    unshift @{$self->{keys}{$section}}, $key;
    $pl->set($key, $value);
}

sub append {
    my ($self, $section, $key, $value) = @_;
    my $pl = $self->getPropertyList($section) || $self->_newSection($section);
    push @{$self->{keys}{$section}}, $key;
    $pl->set($key, $value);
}

###############################################################################
=pod

---++ INI File

---+++ file() -> $path
Returns the ini file path.

---+++ read($path) -> $ini
Uses path passed to =new= if =$path= is <code>undef</code>ined.%BR%
Returns the object it's been called on or =undef= on failure.%BR%

---+++ write($path) -> $ini
Uses path passed to =new= if =$path= is <code>undef</code>ined.%BR%
Returns the object it's been called on or =undef= on failure.%BR%

=cut
###############################################################################

sub file {
    return $_[0]{file};
}

sub read {
    my ($self, $file) = @_;
    $file //= $self->{file};
    $self->{separator} //= "_";

    open (my $in, '<', $file) || return $self;
    $self->clear();

    my ($pl, $keys);
    while (<$in>) {
        chomp;
        if (/^\[(.+)\]/) {
            $pl = $self->_newSection($1);
            $keys = $self->{keys}{$1};
        } else {
            if (/^(.+?)=(.*)/) {
                # scalar property
                $pl->set($1, $2);
                push @$keys, $1;
            }
        }
    }
    close $in;
    return $self;
}

sub clear {
    my $self = shift;
    $self->{sections} = [];   # sections
    $self->{keys} = {};       # section => [ keys ]
    $self->{properties} = {}; # section => PropertyList{key => value}
    return $self;
}

sub write {
    my ($self, $file, $sort) = @_;
    $file //= $self->{file} // \*STDOUT;

    my $fh;
    if (ref $file && ref $file eq 'GLOB') {
        $fh = $file;
    } else {
        open ($fh, '>', $file) || return;
    }

    my @sections = $sort ? sort @{$self->{sections}}
                         : @{$self->{sections}};

    foreach my $section (@sections) {
        my $pl = $self->getPropertyList($section) || return;
        print $fh "[$section]\n" or return;
        foreach my $name (@{$self->{keys}{$section}}) {
            printf $fh "%s=%s\n", $name, $pl->get($name) or return;
        }
    }
    return $self;
}

###############################################################################
=pod

---++ Data Structures

---+++ parse($section, $key, $default) -> $data
   * =$section= - section name
   * =$key= - name of key to add to hashes, pointing to hash id (either a key or an index number)
   * =$default= - default hash entries to add

Interprets four kinds of data structures within a section.%BR%
Returns a hash with the following keys: =namedLists hashList array namedHashes namedHashesLHS=
containing the interpreted data.

   1. array (anonymous list)
      [index]=[value]
      example: 0=val1 1=val2 ...
      access: getList(section)->[index]
   2. named list
      [name][index]=[value]
      example: foo0=val1 foo1=val2 bar0=val3 bar1=val4 ...
      access: getLists(section)->{name}[index]
      or:     getList(section, name)->[index]
   3. list of hashes
      [key][index]=[value]
      example: foo0=val1 bar0=val2 foo1=val3 bar1=val4 ...
      access: getHashList(section)->[index]{key}
   4. named hashes
      4(a). key on rhs
         [name]_[key]=[value]
         example: foo_keya=val1 foo_keyb=val2 bar_keya=val1 bar_keyb=val2 ...
         access: getHashes(section)->{name}{key}
         or:     getHash(section, name)->{key}
      4(b). key on lhs
         [key]_[name]=[value]
         example: key1_foo=val1 key2_foo=val2 key1_bar=val1 key2_bar=val2 ...
         access: getHashesLHS(section)->{name}{key}
         or:     getHashLHS(section, name)->{key}

=cut
###############################################################################

sub parse {
    my ($self, $section, $key, $default) = @_;
    my $pl = $self->getPropertyList($section) || return;
    my @keys = $self->getKeys($section);
    my $data;

    foreach (@keys) {
        my $value = $pl->get($_);
        # lists
        if (/^(.*?)(\d+)$/) {
            if ($1) {
                # 2) name => [ values ]
                $data->{namedLists}{$1}[$2] = $value;
                # 3) [ key => value ]
                $data->{hashList}[$2] ||= {%$default} if $default;
                $data->{hashList}[$2]{$1} = $value;
                $data->{hashList}[$2]{$key} = $2 if $key;
            } else {
                # 1) [ values ]
                $data->{array}[$2] = $value;
            }
        # hashes
        } elsif (/^(.+)$self->{separator}(.+)$/) {
            # 4) name => key => value
            if (! $data->{namedHashes}{$1} && $default) {
                $data->{namedHashes}{$1} = {%$default};
                $data->{namedHashesLHS}{$2} = {%$default};
            }
            $data->{namedHashes}{$1}{$2} = $value;
            $data->{namedHashesLHS}{$2}{$1} = $value;
            if ($key) {
                $data->{namedHashes}{$1}{$key} = $1;
                $data->{namedHashesLHS}{$2}{$key} = $2;
            }
        }
    }
    return $data;
}

###############################################################################
=pod

---+++ getList($section, $name) -> @array or $array
   * =$section= - section name
   * =$name= - list name
   * =@array= - the list
   * =$array= - reference to @array

Get values from a section containing an anonymous or a named list.%BR%
Get values from a named list if =$name= is defined.%BR%
Returns a list of values.%BR%

---+++ getLists($section) -> ( $name => $array ) or { $name => $array }
Returns a hash of lists.%BR%

---+++ getHashList($section) -> ( $hash ) or [ $hash ]
Returns a list of hashes.%BR%

---+++ getHash($section, $name) -> $hash or %hash
Returns a hash of values.%BR%

---+++ getHashLHS($section, $name) -> $hash or %hash
Returns a hash of values.%BR%

---+++ getHashes($section) -> ( $name => $hash ) or { $name => $hash }
Returns a hash of hashes.%BR%

---+++ getHashesLHS($section) -> ( $name => $hash ) or { $name => $hash }
Returns a hash of hashes.%BR%

---+++ setList($section, $array, $name) -> $propertyList
Create an anonymous or a named list with the values from =$array=.%BR%
Creates a named list if =$name= is defined.%BR%
Returns a =PropertyList= object for the section.%BR%

---+++ setHashList($section, $array, \@keys) -> $propertyList
Create a hash list with the values from =$array=.%BR%
Only use keys in =\@keys= if defined, order is preserved.%BR%
Returns a =PropertyList= object for the section.%BR%

=cut
###############################################################################

sub getList {
    my ($self, $section, $name) = @_;
    my $data = $self->parse($section) || return;
    if ($name) {
        exists $data->{namedLists}{$name} || return;
        $data = $data->{namedLists}{$name};
    } else {
        $data = $data->{array};
    }
    return wantarray ? @$data : $data;
}

sub getLists {
    my ($self, $section) = @_;
    my $data = $self->parse($section) || return;
    $data = $data->{namedLists};
    return wantarray ? @$data : $data;
}

sub getHashList {
    my ($self, $section, $key, $default) = @_;
    my $data = $self->parse($section, $key, $default) || return;
    $data = $data->{hashList};
    shift @$data unless defined $data->[0]; # when list starts at 1
    return wantarray ? @$data : $data;
}

sub getHash {
    my ($self, $section, $name) = @_;
    my $data = $self->parse($section) || return;
    exists $data->{namedHashes}{$name} || return;
    $data = $data->{namedHashes}{$name};
    return wantarray ? %$data : $data;
}

sub getHashLHS {
    my ($self, $section, $name) = @_;
    my $data = $self->parse($section) || return;
    exists $data->{namedHashesLHS}{$name} || return;
    $data = $data->{namedHashesLHS}{$name};
    return wantarray ? %$data : $data;
}

sub getHashes {
    my ($self, $section, $key) = @_;
    my $data = $self->parse($section, $key) || return;
    $data = $data->{namedHashes};
    return wantarray ? %$data : $data;
}

sub getHashesLHS {
    my ($self, $section, $key) = @_;
    my $data = $self->parse($section, $key) || return;
    $data = $data->{namedHashesLHS};
    return wantarray ? %$data : $data;
}

sub setList {
    my ($self, $section, $array, $name) = @_;
    my $pl = $self->getPropertyList($section) || $self->_newSection($section);

    my @keys = $name ? map { "$name$_" } 0 .. @$array-1
                     :                   0 .. @$array-1;
    $self->{keys}{$section} = \@keys;

    $pl->clear;
    for (my $i=0; $i<@$array; $i++) {
        $pl->set($keys[$i], $array->[$i]) foreach @$array;
    }
    return $pl;
}

sub setHashList {
    my ($self, $section, $array, $keys) = @_;
    my $pl = $self->getPropertyList($section) || $self->_newSection($section);
    $pl->clear;
    my @propertyKeys;
    for (my $i=1; $i<=@$array; $i++) {
        my $hash = $array->[$i-1];
        foreach ($keys ? @$keys : keys %$hash) {
            $hash->{$_} // next;
            $pl->set("$_$i", $hash->{$_});
            push @propertyKeys, "$_$i";
        }
    }
    $self->{keys}{$section} = \@propertyKeys;
    return $pl;
}

###############################################################################
=pod

---++ Compare

---+++ sectionEquals($ini, $section) -> $result
   * =$ini= - =File::Ini= object to compare to
   * =$section= - section name
   * =$result= - boolean

---+++ compare($ini) -> $result
   * =$ini= - =File::Ini= object to compare to
   * =$result= - [[ViewEmbeddedDoc?module=File::IniCompareResult][File::IniCompareResult]]

=cut
###############################################################################

sub sectionEquals {
    my ($self, $ini, $section) = @_;
    my $p1 = $self->getSection($_[1]) || return;
    my $p2 = $ini->getSection($_[1]) || return;
    return Compare($p1, $p2);
}

sub compare {
    my ($left, $right) = @_;

    my $res = new File::IniCompareResult();

    foreach my $section (@{$left->sections}) {
        if (exists $right->{properties}{$section}) {
            $res->properties->{$section} =
                $left->{properties}{$section}->compare(
                    $right->{properties}{$section},
                    orderLeft => $left->getKeys($section),
                    orderRight => $right->getKeys($section),
                );

            if ($res->properties->{$section}->hasDifferences) {
                push @{$res->sections->unequal}, $section;
            } else {
                push @{$res->sections->equal}, $section;
            }
        } else {
            push @{$res->sections->left}, $section;
        }
    }

    foreach my $section (@{$right->sections}) {
        if (! exists $left->{properties}{$section}) {
            push @{$res->sections->right}, $section;
        }
    }

    return $res;
}

1;
