use v5.16;
package CPAN::Mini::Inject::Config;

use strict;
use warnings;

our $VERSION = '0.38';

use Carp;
use File::Spec::Functions qw(rootdir catfile);

=head1 NAME

CPAN::Mini::Inject::Config - Config for CPAN::Mini::Inject

=head1 SYNOPSIS

	my $config = CPAN::Mini::Inject::Config->new;

=head1 DESCRIPTION

=head2 Configuration

This is the default class dealing with the default L<CPAN::Mini::Inject>
config. The simplest config is a key-value file:

	local: t/local/CPAN
	remote : http://localhost:11027
	repository: t/local/MYCPAN
	dirmode: 0775
	passive: yes

This module digests that and returns it as a hash reference. Any module
that wants to use a different sort of config structure needs to return
the same hash:

	{
	local      => 't/local/CPAN',
	remote     => 'http://localhost:11027',
	repository => 't/local/MYCPAN',
	dirmode    => '0775',
	passive    => 'yes',
	}

=over 4

=item * default_authorid

The authorid to use if you don't specify one with C<--add>.

=item * dirmode

Set the permissions of created directories to the specified mode. The default
value is based on umask if supported.

=item * local

location to store local CPAN::Mini mirror (*REQUIRED*)

=item * passive

Enable passive FTP.

=item * remote

CPAN site(s) to mirror from. Multiple sites can be listed space separated.
(*REQUIRED*)

=item * repository

Location to store modules to add to the local CPAN::Mini mirror.

=back

=head2 Methods

=over 4

=item C<new>

=cut

sub new { bless { file => undef }, $_[0] }

=item C<< config_file( [FILE] ) >>

=cut

sub config_file {
  my ( $self, $file ) = @_;

  if ( @_ == 2 ) {
    croak( "Could not read file [$file]!" ) unless -r $file;
    $self->{file} = $file;
  }

  $self->{file};
}

=item C<< load_config() >>

loadcfg accepts a L<CPAN::Mini::Inject> config file or if not defined
will search the following four places in order:

=over 4

=item * file pointed to by the environment variable C<MCPANI_CONFIG>

=item * F<$HOME/.mcpani/config>

=item * F</usr/local/etc/mcpani>

=item * F</etc/mcpani>

=back

loadcfg sets the instance variable cfgfile to the file found or undef if
none is found.

 print "$mcpi->{cfgfile}\n"; # /etc/mcpani

=cut

sub load_config {
  my( $self, $file ) = @_;

  my $cfgfile = $file || $self->_find_config;

  croak 'Unable to find config file' unless $cfgfile;
  $self->config_file( $cfgfile );

  return $cfgfile;
}

sub _config_files {
  my @files = (
    $ENV{MCPANI_CONFIG},
    (
      defined $ENV{HOME}
      ? catfile( $ENV{HOME}, qw(.mcpani config) )
      : ()
    ),
    catfile( rootdir(), qw(usr local etc mcpani) ),
    catfile( rootdir(), qw(etc mcpani) ),
  );
}

sub _find_config {
  for my $file ( _config_files() ) {
    next unless defined $file;
    next unless -r $file;

    return $file;
  }

  return;
}

=item C<< parse_config() >>

parsecfg reads the config file stored in the instance variable cfgfile and
creates a hash in config with each setting.

  $mcpi->{config}{remote} # CPAN sites to mirror from.

parsecfg expects the config file in the following format:

 local: /www/CPAN
 remote: ftp://ftp.cpan.org/pub/CPAN ftp://ftp.kernel.org/pub/CPAN
 repository: /work/mymodules
 passive: yes
 dirmode: 0755

If either local or remote are not defined parsecfg croaks.

=cut

sub parse_config {
  my $self = shift;

  my $file = shift;

  my %required = map { $_, 1 } qw(local remote);

  $self->load_config( $file ) unless $self->config_file;

  if ( -r $self->config_file ) {
    open my ( $fh ), "<", $self->config_file
     or croak( "Could not open config file: $!" );

    while ( <$fh> ) {
      next if /^\s*#/;
      $self->{$1} = $2 if /^\s*([^:\s]+)\s*:\s*(.*?)\s*$/;
      delete $required{$1} if defined $required{$1};
    }

    close $fh;

    croak 'Required parameter(s): '
     . join( ' ', keys %required )
     . ' missing.'
     if keys %required;
  }

  return $self;
}

=item C<< get( DIRECTIVE ) >>

Return the value for the named configuration directive.

=cut

sub get { $_[0]->{ $_[1] } }

=item C<< set( DIRECTIVE, VALUE ) >>

Sets the value for the named configuration directive.

=cut

sub set { $_[0]->{ $_[1] } = $_[2] }

=back

=cut

1;
