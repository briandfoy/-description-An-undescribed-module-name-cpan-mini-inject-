use strict;
use warnings;

use Carp ();
use Data::Dumper;

sub write_config {
	my %defaults = qw(
		local       t/local/CPAN
		remote      http://localhost:11027
		repository: t/local/MYCPAN
		dirmode     0775
		passive     yes
		);
	my %args = (%defaults, @_);

	my $fh;
	unless( defined $args{file} ) {
		( $fh, $args{file} ) = File::Temp::tempfile();
		}

	unless( defined $fh ) {
		open $fh, '>', $args{file} or do {
			Carp::carp "Could not open <$args{file}>: $!";
			return;
			};
		}

	my $contents = <<"HERE";
local:      $args{local}
remote:     $args{remote}
repository: $args{repository}
dirmode:    $args{dirmode}
passive:    $args{passive}
HERE


	print {$fh} $contents;
	close $fh;

	return $args{file};
	}

1;
