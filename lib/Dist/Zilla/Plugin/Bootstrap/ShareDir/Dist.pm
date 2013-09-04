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
    "does":"Dist::Zilla::Role::Bootstrap",
    "inherits":"Moose::Object"
}

=end MetaPOD::JSON

=cut

=head1 SYNOPSIS

This module is the logical intersection of C<ShareDir> and C<Bootstrap::lib> plug-ins.

    [Bootstrap::lib]

    [Bootstrap::ShareDir::Dist]
    dir = share

    [ShareDir]
    dir = share

The only significant difference between this module and C<ShareDir> is this module exists to make C<share> visible to
plugins for the distribution being built, while C<ShareDir> exists to export the C<share> directory visible after install time.

Additionally, there are two primary attributes that are provided by L<< C<Dist::Zilla::Role::Bootstrap>|Dist::Zilla::Role::Bootstrap >>, See L<< Dist::Zilla::Role::Bootstrap/ATTRIBUTES >>

For instance, this bootstraps C<ROOT/Your-Dist-Name-$VERSION/share> if it exists and there's only one C<$VERSION>,
otherwise it falls back to simply bootstrapping C<ROOT/share>

    [Bootstrap::ShareDir::Dist]
    dir = share
    try_built = 1

=cut

with 'Dist::Zilla::Role::Bootstrap';

around 'dump_config' => sub {
  my ( $orig, $self, @args ) = @_;
  my $config    = $self->$orig(@args);
  my $localconf = {};
  for my $var (qw( dir )) {
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

This is where all the real work is done.

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

=method C<bootstrap>

Called by L<<< C<< Dist::Zilla::Role::B<Bootstrap> >>|Dist::Zilla::Role::Bootstrap >>>

=cut

sub bootstrap {
  my $self = shift;
  return $self->do_bootstrap_sharedir;
}

__PACKAGE__->meta->make_immutable;
no Moose;
no MooseX::AttributeShortcuts;

1;

