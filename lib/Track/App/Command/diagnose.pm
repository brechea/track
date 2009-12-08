#
#===============================================================================
#
#         File:  diagnose.pm
#
#     ABSTRACT:  Given a path of toy train track piece labels (in a YAML file), tell whether it's good (closed, continuous C1), and how far off it's from a good one.
#  Description:  If you come up with a layout that can be made to fit by
#                "wiggling" it (wooden track sections are intentionally made
#                with some play at the joints), 'diagnose' will tell you if it's
#                a "real" layout, or, if not, just how much off it is from a
#                real one.
#
#        Files:  ---
#         Bugs:  ---
#        Notes:  ---
#       Author:  Bernardo Rechea (BRB), <brbpub@gmail.com>
#      Company:  ---
#    Copyright:  Copyright (c) 2009, Bernardo Rechea
#      Version:  1.0
#      Created:  2009-11-25 17:27:59
#     Revision:  ---
#===============================================================================

#-------------------------------------------------------------------------------
#  Command 'diagnose'
#-------------------------------------------------------------------------------
package Track::App::Command::diagnose;
use 5.10.0;
use strict;
use warnings;
use autodie qw(:all);

use Track
  qw(append_section_to print_path is_closedC1 distance min_angle);
use Track::App -command;

use constant DEBUG => 0;

use YAML qw(LoadFile Dump);


sub usage_desc { "%c diagnose <yaml_file>" }

#--- Function ------------------------------------------------------------------
#     Name:  execute
#    Usage:  
#  Purpose:  ???
#  Params.:  ???
#  Returns:  ???
# Side Eff:  none
#   Throws:  no exceptions
#   Descr.:  execute 'diagnose' command
# Comments:  ---
# See Also:  n/a
#
sub execute {
    my ($self, $opt, $args) = @_;

    diagnose_path_typeList( @{ LoadFile($args->[0]) } );
}


#--- Function ------------------------------------------------------------------
#     Name:  diagnose_path_typeList
#    Usage:  diagnose_path_typeList(@list_of_type_labels)
#  Purpose:  ???
#  Params.:  ???
#  Returns:  ???
# Side Eff:  none
#   Throws:  no exceptions
#   Descr.:  report whether a sequence of track sections, given by their labels,
#            is a closed and continuous C1 path, and the distance and angle
#            between the last and first sections.
# Comments:  ---
# See Also:  n/a
#
sub diagnose_path_typeList {
    my @sectTypes = @_;

    my @path = ();
    push @path, append_section_to(shift @sectTypes);
    for my $sectType (@sectTypes) {
        push @path, append_section_to($sectType, $path[-1]);
    }
#    say Dump(\@path);

    say print_path(@path);
    say 'Closed C1?: ', ( is_closedC1(\@path) ? 'yes' : 'no' );
    say 'First-last distance: ', distance( $path[0]{Pi}, $path[-1]{Pf} );
    say 'First-last min angle: ', min_angle( $path[0]{Di}, $path[-1]{Df} );
}


1;
