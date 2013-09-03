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

use Moo 1.000008;

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

has distname => ( is => ro =>, lazy => 1, builder => sub { $_[0]->zilla->name; } );
has cwd => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require Path::Tiny;
    require Cwd;
    return Path::Tiny::path(Cwd::cwd);
  }
);
has try_built => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    return unless $self->has_no_try_built;
    return !$self->no_try_built;
  }
);
has no_try_built => (
  is        => ro =>,
  lazy      => 1,
  predicate => 'has_no_try_built',
  builder   => sub {
    return;
  }
);
has fallback => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    return unless $self->has_no_fallback;
    return !$self->no_fallback;
  }
);
has no_fallback => (
  is        => ro =>,
  lazy      => 1,
  predicate => 'has_no_fallback',
  builder   => sub {
    return;
  }
);
has bootstrap_root => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    if ( not $self->try_built ) {
      return $self->cwd;
    }
    my $distname = $self->distname;
    my (@candidates) = grep { $_->basename =~ /^\Q$distname\E-/ } grep { $_->is_dir } $self->cwd->children;

    if ( scalar @candidates == 1 ) {
      return $candidates[0];
    }
    $self->log_debug( [ 'candidate: %s', $_->basename ] ) for @candidates;

    if ( not $self->fallback ) {
      $self->log( [ 'candidates for bootstrap (%s) != 1, and fallback disabled. not bootstrapping', 0 + @candidates ] );
      return;
    }

    $self->log( [ 'candidates for bootstrap (%s) != 1, fallback to boostrapping <distname>/', 0 + @candidates ] );
    return $self->cwd;
  }
);
has dir => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    return 'share';
  }
);

has halt_after_setup => ( is => ro =>, lazy => 1, builder => sub { return ; } );

sub do_bootstrap_sharedir {
  my ( $self, ) = @_;

  my $root = $self->bootstrap_root;

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
  $object->_install_dist( $self->distname );
  require lib;
  lib->import( $object->_tempdir . '' );
  $self->log_debug( [ 'Sharedir for %s installed to %s', $self->distname, $object->_tempdir . '' ] );
  if ( $self->halt_after_setup ) {
      $self->log("Tempdir is " . $object->_tempdir ); 
      system('bash');
  }
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

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
