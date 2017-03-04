use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist;

our $VERSION = '1.001002';

# ABSTRACT: Use a share directory on your dist during bootstrap

# AUTHORITY

use Moose qw( with around has );

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist",
    "interface":"class",
    "does":"Dist::Zilla::Role::Bootstrap",
    "inherits":"Moose::Object"
}

=end MetaPOD::JSON

=cut

with 'Dist::Zilla::Role::Bootstrap';

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  if ( $self->meta->find_attribute_by_name('dir')->has_value($self) ) {
    $localconf->{dir} = $self->dir;
  }

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

=attr C<dir>

=cut

has dir => (
  is         => ro =>,
  lazy_build => 1,
);

sub _build_dir {
  return 'share';
}

__PACKAGE__->meta->make_immutable;
no Moose;

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
  require Test::File::ShareDir::Object::Dist;
  my $share_object = Test::File::ShareDir::Object::Dist->new( dists => { $self->distname => $sharedir } );
  for my $dist ( $share_object->dist_names ) {
    $self->log_debug(
      [
        'Installing dist %s ( %s => %s )',
        "$dist",
        $share_object->dist_share_source_dir($dist) . q{},
        $share_object->dist_share_target_dir($dist) . q{},
      ],
    );
    $share_object->install_dist($dist);
  }
  require lib;
  lib->import( $share_object->inc->tempdir . q{} );
  $self->log_debug( [ 'Sharedir for %s installed to %s', $self->distname, $share_object->inc->dist_tempdir . q{} ] );
  return;
}

=method C<bootstrap>

Called by L<<< C<< Dist::Zilla::Role::B<Bootstrap> >>|Dist::Zilla::Role::Bootstrap >>>

=cut

sub bootstrap {
  my $self = shift;
  return $self->do_bootstrap_sharedir;
}

1;

=head1 DESCRIPTION

This module allows one to load a C<Dist> styled C<ShareDir> using a C<Bootstrap>
mechanism so a distribution can use files in its own source tree when building with itself.

This is very much like the C<Bootstrap::lib> plugin in that it injects libraries into
C<@INC> based on your existing source tree, or a previous build you ran.

And it is syntactically like the C<ShareDir> plugin.

B<Note> that this is really only useful for self consuming I<plugins> and will have no effect
on the C<test> or C<run> phases of your dist. ( For that, you'll need C<Test::File::ShareDir> ).

=head1 USAGE

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
