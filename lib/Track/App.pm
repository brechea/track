#
#===============================================================================
#
#         File:  App.pm
#
#     ABSTRACT:  Main Track application class
#  Description:  ---
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
#         File:  find_track-layouts.pl
#
#  Description:  Find all possible closed non-crossing layouts of toy train
#                tracks given a set of track pieces.
#                For simplicity I'm modeling things as simple (non-crossing)
#                polygons, but they can be concave or convex.
#===============================================================================

package Track::App;
use 5.10.0;
use strict;
use warnings;
use autodie qw(:all);

use App::Cmd::Setup -app;


1;
