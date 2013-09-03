use strict;
use warnings;

package Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist;
BEGIN {
  $Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist::VERSION = '0.1.0';
}

# ABSTRACT: Use a C<share> directory on your dist during bootstrap

use Moose;
use MooseX::AttributeShortcuts;


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


has distname => ( is => ro =>, lazy => 1, builder => sub { $_[0]->zilla->name; }, );


has _cwd => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Path::Tiny;
    require Cwd;
    return Path::Tiny::path( Cwd::cwd() );
  },
);


has try_built => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return },
);


has fallback => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return 1 },
);


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


has dir => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    return 'share';
  },
);


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

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist - Use a C<share> directory on your dist during bootstrap

=head1 VERSION

version 0.1.0

=head1 METHODS

=head2 C<do_bootstrap_sharedir>

This is where all the real work is done, and its called via a little glue around C<plugin_from_config>

=head1 ATTRIBUTES

=head2 C<distname>

=head2 C<try_built>

=head2 C<fallback>

=head2 C<dir>

=head1 PRIVATE ATTRIBUTES

=head2 C<_cwd>

=head2 C<_bootstrap_root>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Bootstrap::ShareDir::Dist",
    "interface":"class",
    "does":"Dist::Zilla::Role::Plugin",
    "inherits":"Moose::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
