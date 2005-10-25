package Image::XBin::Util;

=head1 NAME

Image::XBin::Util - Utility functions

=head1 SYNOPSIS

	use Image::XBin::Util;
	
	my $file = create_io_object( %options );

=cut

use base qw( Exporter );

use strict;
use warnings;

use Carp;
use IO::File;
use IO::String;

our @EXPORT  = qw( create_io_object );
our $VERSION = '0.01';

=head1 METHODS

=head2 create_io_object( %options )

Generates an IO object. Uses IO::File or IO::String.

=cut

sub create_io_object {
	my %options = %{ $_[ 0 ] };
	my $perms   = $_[ 1 ];

	my $file;

	# use appropriate IO object for what we get in
	if( exists $options{ file } ) {
		$file = IO::File->new( $options{ file }, $perms ) or croak "$!";
	}
	elsif( exists $options{ string } ) {
		$file = IO::String->new( $options{ string } );
	}
	elsif( exists $options{ handle } ) {
		$file = $options{ handle };
	}
	else {
		croak( "No valid read type. Must be one of 'file', 'string' or 'handle'." );
	}

	binmode( $file );
	return $file;
}

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;