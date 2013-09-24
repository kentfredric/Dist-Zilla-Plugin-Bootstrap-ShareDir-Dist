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

BAIL_OUT("test setup failed to copy to tempdir") if not -e -f $tempdir->child("dist.ini");

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

