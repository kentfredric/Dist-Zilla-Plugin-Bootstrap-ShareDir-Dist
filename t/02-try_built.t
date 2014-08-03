use strict;
use warnings;

use Test::More;
use Path::Tiny;
use File::Copy::Recursive qw( rcopy );

my $dist    = 'fake_dist_02';
my $source  = Path::Tiny->cwd->child('corpus')->child($dist);
my $tempdir = Path::Tiny->tempdir;

rcopy( "$source", "$tempdir" );

my $dist_ini = $tempdir->child('dist.ini');
BAIL_OUT("test setup failed to copy to tempdir") if not -e $dist_ini and -f $dist_ini;

use Test::Fatal;
use Test::DZil;

is(
  exception {

    Builder->from_config( { dist_root => "$tempdir" } )->build;

  },
  undef,
  "dzil build ran ok"
);

done_testing;

