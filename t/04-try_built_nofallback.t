use strict;
use warnings;

use Test::More;
use Path::FindDev qw( find_dev );
use Path::Tiny;
use Cwd qw( cwd );
use File::Copy::Recursive qw( rcopy );

my $dist    = 'fake_dist_04';
my $source  = find_dev('./')->child('corpus')->child($dist);
my $tempdir = Path::Tiny->tempdir;

rcopy( "$source", "$tempdir" );

my $dist_ini = $tempdir->child('dist.ini');
BAIL_OUT("test setup failed to copy to tempdir") if not -e $dist_ini and -f $dist_ini;

use Test::Fatal;
use Test::DZil;

isnt(
  exception {

    Builder->from_config( { dist_root => "$tempdir" } )->build;

  },
  undef,
  "dzil build ran ok"
);

done_testing;

