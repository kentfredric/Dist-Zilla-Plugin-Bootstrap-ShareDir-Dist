
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4202"
  },
  "configure_requires" => {
    "Module::Build" => "0.4202"
  },
  "dist_abstract" => "Use a C<share> directory on your dist during bootstrap",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-Bootstrap-ShareDir-Dist",
  "dist_version" => "0.3.0",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla::Role::Bootstrap" => 0,
    "Moose" => 0,
    "MooseX::AttributeShortcuts" => 0,
    "Test::File::ShareDir::Object::Dist" => 0,
    "lib" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Cwd" => 0,
    "Dist::Zilla::Plugin::Bootstrap::lib" => "0.04000000",
    "File::Copy::Recursive" => 0,
    "File::ShareDir" => 0,
    "Path::FindDev" => 0,
    "Path::Tiny" => 0,
    "Test::DZil" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Cwd" => 0,
  "Dist::Zilla::Plugin::Bootstrap::lib" => "0.04000000",
  "File::Copy::Recursive" => 0,
  "File::ShareDir" => 0,
  "Module::Build" => "0.4202",
  "Path::FindDev" => 0,
  "Path::Tiny" => 0,
  "Test::DZil" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
