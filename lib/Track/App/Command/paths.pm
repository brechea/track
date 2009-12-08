#
#===============================================================================
#
#         File:  paths.pm
#
#     ABSTRACT:  Given a set of toy train track pieces (in a YAML file), find and print all closed, continuous C1 layouts, with trivial variants filtered out.
#  Description:  
#
#        Files:  ---
#         Bugs:  ---
#        Notes:  ---
#       Author:  Bernardo Rechea (BRB), <brbpub@gmail.com>
#      Company:  ---
#    Copyright:  Copyright (c) 2009, Bernardo Rechea
#      Version:  1.0
#      Created:  2009-11-25 17:07:48
#     Revision:  ---
#===============================================================================

#------------------------------------------------------------------------------┐
#  Command 'explore'                                                           │
#------------------------------------------------------------------------------┘
package Track::App::Command::paths;
use 5.10.0;
use strict;
use warnings;
use autodie qw(:all);

use Track qw(append_section_to print_path is_closedC1 flip_label);
use Track::App -command;

use constant DEBUG => 0;

use List::Util qw(sum);
use YAML qw(LoadFile Dump);


sub usage_desc { "%c paths <yaml_file>" }

#sub opt_spec {
#    return (
#        [ "Given a set of toy train track pieces (in a YAML file), find and print all closed, continuous C1 layouts, with trivial variants filtered out." ],
#    );
#}

sub execute {
    my ($self, $opt, $args) = @_;

    initialize(LoadFile($args->[0]));
    explore_path();
}

#--- Function ------------------------------------------------------------------
#     Name:  initialize
#    Usage:  initialize(\%sectCount)
#  Purpose:  expand simple section counts adding shared counters for flipped
#            sections, and set up total counter.
#  Params.:  A hashref of <sectionTypeLabel> => <count> pairs.
#  Returns:  nothing
# Side Eff:  none
#   Throws:  no exceptions
#   Descr.:  We use anonymous scalar references, rather than plain scalars, for
#            the section counts so that they can be shared by different section
#            types. We do this because some pieces can be used in different
#            orientations, and thus can be different types. For example, a
#            left-handed arc can be flipped to be a right-handed one. If we use
#            an arc in a left-handed orientation, we want the count for the
#            right-handed arcs to be decremented simultaneously with the count
#            for the left-handed arcs.
# Comments:  ---
# See Also:  n/a
#
our %sectCount;
our $sectCount;
our %seenPath;

sub initialize {
    our %sectCount = %{ shift @_ };

    #### Inventory of sections is a hashref with pairs of the form
    #
    # <sectionTypeLabel> => anonymous scalarref
    #
    # Convert scalars to scalar refs
    while (my ($k, $v) = each %sectCount) {
        $sectCount{$k} = \$v;
    }

    ## Count total number of sections
    our $sectCount = sum( map { ${$_} } values %sectCount );
#    say "\$sectCount = $sectCount";

    ## Add flipped section types, sharing counters
    # TODO 2009-11-20, BRB: don't add aL's if there are some already.
    # Actually, check that there are either aR's or aL's but not both, and do
    # add the others.
    $sectCount{aL} = $sectCount{aR} if defined $sectCount{aR};
#    say "Inventory of Sections:\n", Dump(\%sectCount);
}

#--- Function ------------------------------------------------------------------
#     Name:  explore_path
#    Usage:  
#  Purpose:  ???
#  Params.:  ???
#  Returns:  ???
# Side Eff:  none
#   Throws:  no exceptions
#   Descr.:  Find all possible, closed, continuous C1 layouts of toy train tracks
#            given a set of track pieces, filtering out trivial variants.
#            Once a path is found, the following variants are filtered out:
#            - all rotations of the path, i.e., all identical paths starting at
#              a different piece of the current path;
#            - for each rotation, its "flipped" variant, where all pieces that can
#              be flipped (e.g., curved arcs with grooves on both sides that can
#              be left- or right-handed) are flipped;
#            - paths where sequences of smaller straight segments are
#              substituted with longer segments of the same total length, and vice
#              versa.
# Comments:  We need a path (list), even if empty.
# See Also:  Coordinate_Systems discussion in Track.pm
# 
sub explore_path {
    my @path = @_;

    if ( is_closedC1(\@path) ) {
        if ( not defined $seenPath{ join(' ', map { $_->{type} } @path ) } ) {
            say print_path(@path), '  (closed)';

            # Mark as seen trivial variants of the current path
            my @pathLabels = map { $_->{type} } @path;
            # For each rotation...
            for (0..$#pathLabels) {
                push @pathLabels, shift @pathLabels;
                # ... rembember the rotation itself,
                $seenPath{ join ' ', @pathLabels } = 1;
                # ... the flipped rotation,
                $seenPath{ join ' ', map { flip_label($_) } @pathLabels } = 1;
                # ... and the variants of straight-segment sequences
                # TODO
            }
        }
    }
#    else {
#        say print_path(@path), '  (open)';
#    }
    say Dump( \@path ) if DEBUG;

    if ( $sectCount > 0 ) {
        foreach my $sectType (keys %sectCount) {
            if ( ${ $sectCount{$sectType} } > 0 ) {
                $sectCount--;
                ${ $sectCount{$sectType} }--;

                if (defined $path[-1]) {
                    explore_path( @path, append_section_to($sectType, $path[-1]) );
                }
                else {
                    explore_path( append_section_to($sectType) );
                }

                $sectCount++;
                ${ $sectCount{$sectType} }++;
            }
        }
    }
    else {
#        say "------------------------------";
        return;
    }
}


1;
