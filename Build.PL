
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4007"
  },
  "configure_requires" => {
    "Module::Build" => "0.4007"
  },
  "dist_abstract" => "Use a C<share> directory on your dist during bootstrap",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-Bootstrap-ShareDir-Dist",
  "dist_version" => "0.2.1",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla::Role::Bootstrap" => 0,
    "Moose" => 0,
    "MooseX::AttributeShortcuts" => 0,
    "Test::File::ShareDir::TempDirObject" => 0,
    "lib" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Cwd" => 0,
    "File::Copy::Recursive" => 0,
    "File::ShareDir" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Path::FindDev" => 0,
    "Path::Tiny" => 0,
    "Test::More" => "0.98"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
