
use strict;
use warnings;

package E;

# ABSTRACT: Fake dist stub

use Moose;
use File::ShareDir qw( dist_file );
use Path::Tiny qw( path );

with 'Dist::Zilla::Role::Plugin';

our $content = path( dist_file( 'E', 'example.txt' ) )->slurp;

1;

