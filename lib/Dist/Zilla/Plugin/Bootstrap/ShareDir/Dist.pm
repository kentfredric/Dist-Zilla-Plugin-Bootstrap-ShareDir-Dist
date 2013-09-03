use strict;
use warnings;

package Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist;

# ABSTRACT: Use a C<share> directory on your dist during bootstrap

use Moose;
use MooseX::AttributeShortcuts;

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist",
    "interface":"class",
    "does":"Dist::Zilla::Role::Plugin",
    "inherits":"Moose::Object"
}

=end MetaPOD::JSON

=cut

with 'Dist::Zilla::Role::Plugin';

around 'dump_config' => sub {
  my ( $orig, $self, @args ) = @_;
  my $config    = $self->$orig(@args);
  my $localconf = {};
  for my $var (qw( try_built no_try_built fallback no_fallback dir )) {
    my $pred = 'has_' . $var;
    if ( $self->can($pred) ) {
      next unless $self->$pred();
    }
    if ( $self->can($var) ) {
      $localconf->{$var} = $self->$var();
    }
  }
  $config->{ q{} . __PACKAGE__ } = $localconf;
  return $config;
};

=attr C<distname>

=cut

has distname => ( is => ro =>, lazy => 1, builder => sub { $_[0]->zilla->name; }, );

=p_attr C<_cwd>

=cut

has _cwd => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Path::Tiny;
    require Cwd;
    return Path::Tiny::path( Cwd::cwd() );
  },
);

=attr C<try_built>

=cut

has try_built => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return },
);

=attr C<fallback>

=cut

has fallback => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return 1 },
);

=p_attr C<_bootstrap_root>

=cut

has _bootstrap_root => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    if ( not $self->try_built ) {
      return $self->_cwd;
    }
    my $distname = $self->distname;
    my (@candidates) = grep { $_->basename =~ /\A\Q$distname\E-/msx } grep { $_->is_dir } $self->_cwd->children;

    if ( scalar @candidates == 1 ) {
      return $candidates[0];
    }
    $self->log_debug( [ 'candidate: %s', $_->basename ] ) for @candidates;

    if ( not $self->fallback ) {
      $self->log( [ 'candidates for bootstrap (%s) != 1, and fallback disabled. not bootstrapping', 0 + @candidates ] );
      return;
    }

    $self->log( [ 'candidates for bootstrap (%s) != 1, fallback to boostrapping <distname>/', 0 + @candidates ] );
    return $self->_cwd;
  },
);

=attr C<dir>

=cut

has dir => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    return 'share';
  },
);

=method C<do_bootstrap_sharedir>

This is where all the real work is done, and its called via a little glue around C<plugin_from_config>

=cut

sub do_bootstrap_sharedir {
  my ( $self, ) = @_;

  my $root = $self->_bootstrap_root;

  if ( not defined $root ) {
    $self->log( ['Not bootstrapping'] );
    return;
  }
  my $sharedir = $root->child( $self->dir );
  $self->log( [ 'Bootstrapping %s for sharedir for %s', "$sharedir", $self->distname ] );
  require Test::File::ShareDir::TempDirObject;
  my $object = Test::File::ShareDir::TempDirObject->new(
    {
      -share => {
        -dist => {
          $self->distname => $sharedir
        }
      }
    }
  );
  for my $dist ( $object->_dist_names ) {
    $self->log_debug(
      [
        'Installing dist %s ( %s => %s )',
        "$dist",
        $object->_dist_share_source_dir($dist) . q{},
        $object->_dist_share_target_dir($dist) . q{},
      ]
    );
    $object->_install_dist($dist);
  }
  require lib;
  lib->import( $object->_tempdir . q{} );
  $self->log_debug( [ 'Sharedir for %s installed to %s', $self->distname, $object->_tempdir . q{} ] );
  return;
}

around plugin_from_config => sub {
  my ( $orig, $plugin_class, $name, $payload, $section ) = @_;

  my $instance = $plugin_class->$orig( $name, $payload, $section );

  $instance->do_bootstrap_sharedir;

  return $instance;
};

1;

