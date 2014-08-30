use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.003001 qw(dztest);
require Dist::Zilla::Plugin::Bootstrap::lib;
require Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist;
require Moose;
require File::ShareDir;
require Path::Tiny;

my $t = dztest();
$t->add_file(
  'dist.ini' => simple_ini(
    {
      name => 'E'
    },
    'Bootstrap::lib',
    'Bootstrap::ShareDir::Dist',
    'MetaConfig',
    'MetaJSON',
    'GatherDir',
    '=E',
    'PruneCruft'
  )
);
$t->add_file( 'share/example.txt', q[ ] );
$t->add_file( 'lib/E.pm',          <<'EOF');
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
EOF

$t->build_ok;

note explain $t->builder->log_messages;

done_testing;
