#
#===============================================================================
#
#         File:  Track.pm
#
#     ABSTRACT:  Lay out and diagnose toy train tracks
#  Description:  ---
#
#        Files:  ---
#         Bugs:  ---
#        Notes:  ---
#       Author:  Bernardo Rechea (BRB), <brbpub@gmail.com>
#      Company:  ---
#    Copyright:  Copyright (c) 2009, Bernardo Rechea
#      Version:  1.0
#      Created:  2009-11-02 16:16:19
#     Revision:  ---
#===============================================================================

package Track;
use 5.10.0;
use strict;
use warnings;
use autodie qw(:all);

use Sub::Exporter -setup => {
    exports => [
        qw(
          append_section_to
          print_path
          Pf Df
          is_closedC1
          distance
          min_angle
          to_1stCircle
          flip_label
          )
    ]
};

use YAML qw(Dump);
use List::Util qw(min);
use Math::Trig ':pi';

use constant SQR2 => 1.4142135623730950488;
use constant DEBUG => 0;


=begin Coordinate_Systems

When laying out a track and working with section i, we use the following
coordinate axis systems:

XY0: Origin at the initial end of the first section, oriented so X points in the
direction of the initial end's direction.

XY1: Origin at the initial end of section i, Pi(i) = Pf(i-1), axes parallel to
XY0.

XY2: Same origin as XY1, axes rotated by Di(i) = Df(i-1). This is the system in
which Pd and Dd are given in the section properties above.

With these axis systems defined, we have

Pf(i) = (Xf0, Yf0), the position of the final point of section i in axis system
XY0, is

  Xf0 = Xi0 + Xd1
  Yf0 = Yi0 + Yd1

where Xi0 and Yi0 are the position of the initial point of section i in system
XY0, and Xd1 and Yd1 are the position deltas of section i in system XY1. The
latter ones, in turn, are

  Xd1 = |Pd| cos t1
  Yd1 = |Pd| sin t1,

with t1 the angle of Pd with respect to axis X1. In turn,

  t1 = Di + t2

with t2 the angle of Pd with respect to axis X2, which is

  t2 = atan(Yd2/Xd2)

where Pd = (Xd, Yd) = (Xd2, Yd2).

                y1
                 ^   Pd
                 |---o
  y0  y2         |  /|\     x2
   ^  ^          | / | \    ^
   |   \         |/  |  \  / 
   |    \        |   |   \/
   |     \      /|   |   /
   |      \    / |   |  /
   |       \  /  |   | /
   |        \/   |   |/
   |         \   |   /
   |          \  |  /|
   |           \ | / |
   |            \|/Di|
   |       _..··>+-----------------------> x1
   |_..··''Pi         
   +------------------------> x0

A section laid out on a track:
  {
     type  => <sectionTypeLabel>,  # To access type features
     Pi => [ x, y ],               # Position of the initial end
     Pf => [ x, y ],               # Position of the final end
     Di => absolute angle,         # Direction of the initial end
     Df => absolute angle,         # Direction of the final end
  }

A path is an array of laid out sections. Section i will have Pi == Pf(i-1)
and Di(i) == Df(i-1)

=end Coordinate_Systems

=cut

#### Features of track section types
# <sectionTypeLabel> => {
#     Position delta and direction delta are defined with respect to a cartesian
#     axes system with origin at the initial end and oriented so that the
#     positive X axis points in the same direction as the initial end. I.e., the
#     section's start is at (0, 0) and points towards direction 0 (radians).
#
#     Position delta: position of the final end of the track section relative to
#     the initial end.
#     Pd => [ Xd, Yd ],
#
#     Direction delta: direction of the final end relative to the initial end,
#     in radians.
#     Dd => <rad>,
# }
#
my %sectFeat = (
    # Straight section of length 1.
    s1 => { Pd => [ 1,        0 ],              Dd => 0, flip => 's1' },
    # Straight section of length 2.
    s2 => { Pd => [ 2,        0 ],              Dd => 0, flip => 's2' },
    # Circular arc, left-handed, with radius 1 and subtending PI/4 radians.
    aL => { Pd => [ SQR2 / 2, 1 - SQR2 / 2 ],   Dd => pip4, flip => 'aR' },
    # Circular arc, right-handed, with radius 1 and subtending PI/4 radians.
    aR => { Pd => [ SQR2 / 2, -1 + SQR2 / 2, ], Dd => - pip4, flip => 'aL' },
);
#say "Section Features:\n", Dump(\%sectFeat);

sub flip_label {
    return $sectFeat{$_[0]}{flip};
}

# We expect a fully defined section, i.e., including Pf and Df, or none at all,
# in which case it creates a "first" section.

#### Handy Globals
my $Pi = [ 0, 0 ];
my $Di = 0;

sub append_section_to {
    my ( $sectType, $prevSect ) = @_;

    my %newSect;
    if ( defined $prevSect ) {
        %newSect = (
            type => $sectType,
            Pi   => $prevSect->{Pf},
            Di   => $prevSect->{Df},
        );
    }
    else {
        %newSect = (
            type => $sectType,
            Pi   => $Pi,
            Di   => $Di,
        );
    }
    $newSect{Pf} = Pf( \%newSect );
    $newSect{Df} = Df( \%newSect );
    say "At append_section_to(): \%newSect: ", Dump( \%newSect ) if DEBUG;

    return \%newSect;
}

sub print_path {

    return 'Path: ' . join(' ', map { $_->{type} } @_);
}


sub Pf {
    my %sect = %{ shift @_ };

    say 'At Pf(): %sect:', Dump(\%sect) if DEBUG;

    my $Xi0 = $sect{Pi}[0];
    my $Yi0 = $sect{Pi}[1];
    say "At Pf(), Xi0:$Xi0, Yi0:$Yi0" if DEBUG;

    # Project position delta Pd onto non-rotated axes X1Y1 given absolute
    # initial position Pi and direction Di.
    my $Xd2 = $sectFeat{ $sect{type} }{Pd}[0];
    my $Yd2 = $sectFeat{ $sect{type} }{Pd}[1];
    say "At Pf(): Xd2: $Xd2, Yd2:$Yd2" if DEBUG;

    my $modPd = sqrt( $Xd2 ** 2 + $Yd2 ** 2 );
    say "At Pf(): modPd:$modPd" if DEBUG;

    my $t2 = atan2($Yd2, $Xd2);

    my $t1 = $sect{Di} + $t2;

    my $Xd1 = $modPd * cos($t1);
    my $Yd1 = $modPd * sin($t1);

    # Compute final position Pf on absolute axes X0Y0.
    my $Xf0 = $Xi0 + $Xd1;
    my $Yf0 = $Yi0 + $Yd1;

    say "At Pf(): Pf: [ $Xf0, $Yf0 ]" if DEBUG;
    return [ $Xf0, $Yf0 ];
}

sub Df {
    my $sect_ref = shift;

    return $sect_ref->{Di} + $sectFeat{ $sect_ref->{type} }{Dd};
}

sub is_closedC1 {
    my $path_ref = shift;

    return 0 if ( not defined $path_ref or scalar( @{$path_ref} ) < 2 );

    if ( distance( $path_ref->[0]{Pi}, $path_ref->[-1]{Pf} ) < 0.01
           and
         min_angle( to_1stCircle( $path_ref->[0]{Di} ), to_1stCircle( $path_ref->[-1]{Df} ) ) < 0.001
       ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub distance {
    my($p1, $p2) = @_;

    my $dist = sqrt( ($p2->[0] - $p1->[0]) ** 2 + ($p2->[1] - $p1->[1]) ** 2 );
    say "At distance(): \$dist:$dist" if DEBUG;

    return $dist;
}

sub to_1stCircle {
    my $angle = shift;

    if ( abs($angle) > pi2 ) {
        return $angle - int($angle/pi2) * pi2;
    }
    else {
        return $angle;
    }
}

sub min_angle {
    my ($a1, $a2) = @_;

    my $diff  = abs( $a2 - $a1 );
    my $diff2 = abs( pi2 - $diff );

    return min($diff, $diff2);
}


1;


=head1 SYNOPSIS

This module supports the command-line application 'track', and is not intended
for end users.

To find all good layouts (paths) that can be made with a set of pieces, say

    $ track paths <yaml_file>

For example, given file examples/pieces-medium.yaml:

    ---
    s1: 2   # 2 straights of length 1
    aR: 12  # 12 right-hand arcs

this command:

    $ track paths exampes/pieces-medium.yaml

produces this output:

    Path: s1 aR aR aR aR s1 aR aR aR aR  (closed)
    Path: s1 aR aR aR aR s1 aR aL aR aR aR aR aR aL  (closed)
    Path: s1 aR aR aR aR s1 aL aR aR aR aR aR aL aR  (closed)
    Path: s1 aR aR aR aR aR aL s1 aR aR aR aR aR aL  (closed)
    Path: s1 aR aR aR aR aL aR s1 aR aR aR aR aL aR  (closed)
    Path: s1 aR aR aR aL aR aR s1 aR aR aR aL aR aR  (closed)
    Path: s1 aR aR aL aR aR aR s1 aR aR aL aR aR aR  (closed)
    Path: s1 aR aL aR aR aR aR s1 aR aL aR aR aR aR  (closed)
    Path: s1 aR aL aL aL aL aL s1 aR aL aL aL aL aL  (closed)
    Path: aR aR aR aR aR aR aR aR  (closed)
    Path: aR aR aR aR aR aL aR aR aR aR aR aL  (closed)
 
To diagnose a path, say

    $ track diagnose <yaml_file>

For example, given file examples/path1.yaml:

    ---
    - s2
    - aR
    - aR
    - aR
    - aL
    - aR
    - aR
    - aR
    - aL
    - aR
    - s1
    - aR
    - aR
    - s1
    - aR

this command:

    $ track diagnose examples/path-1.yaml

produces this output:

    Path: s2 aR aR aR aL aR aR aR aL aR s1 aR aR s1 aR
    Closed C1?: no
    First-last distance: 0.585786437626905
    First-last min angle: 0


=head1 DESCRIPTION
 
My daughters' wooden train set has track sections that seem to follow a module
of 8 inches: straight segments are 8" long (or multiples of that), and the
radius of curves (to the centerline of the track) is 8".

Section joints are made with some play, so some layouts that are not strictly
geometrically kosher can be made.

 
=head1 BUGS AND LIMITATIONS

Works for a very barebones train set. As soon as we get switches, crossings,
etc., I'm screwed.

The code is terrible, slow and ugly.

=head1 TO DO

Option to output track layout diagrams.
 
