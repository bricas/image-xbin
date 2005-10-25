package Image::XBin::Font;

=head1 NAME

Image::XBin::Font - Manipulate XBin font data

=head1 SYNOPSIS

	use Image::XBin::Font;

	# Create a new font
	my $fnt = Image::XBin::Font->new;

	# Set all of the chars
	$fnt->chars( $chars );

	# Set one of them
	$fnt->char( 65, $char );

	# Accessors
	my $width  = $fnt->width;
	my $height = $fnt->height;
	my $chars  = $fnt->characters;

	# Get output suitable for saving...
	my $out = $fnt->as_string;

	# Clear the data
	$fnt->clear;

=head1 DESCRIPTION

Xbin images can contain font data. This module will allow you to create, and manipulate that data.

=cut

use strict;
use warnings;

use GD;
use File::Temp;

our $VERSION = '0.04';

=head1 METHODS

=head2 new( [$chars] )

Creates a new Image::XBin::Font object.

=cut

sub new {
	my $class = shift;
	my $self  = {};

	bless $self, $class;

	$self->clear;
	$self->chars( @_ ) if @_;

	return $self;
}

=head2 chars( [$chars] )

sets the character set. $chars should be an array (either 256 or 512 [the number of
characters]) of arrays (from 1 to 32 [1 bitmask per scanline]).

=cut

sub chars {
	my $self  = shift;
	my $chars = $_[ 0 ];

	if( @_ ) {
		if( @$chars == 0 ) {
			$self->{ _CHARS } = [];
			$self->height( 0 );
		}
		else {
			for( 0..@$chars - 1 ) {
				$self->char( $_, $chars->[ $_ ] );
			}
		}
	}

	return $self->{ _CHARS };
}

=head2 as_string( )

Returns the font as a pack()'ed string - suitable for saving in an XBin.

=cut

sub as_string {
	my $self = shift;

	my $output;

	for my $char ( @{ $self->chars } ) {
		$output .= pack( 'C', $_ ) for @{ $char };
	}

	return $output;	
}

=head2 as_gd( )

Returns a GD::Font object.

=cut

sub as_gd {
	my $self = shift;
	my $temp = File::Temp->new;

	binmode( $temp );

	print $temp pack( 'LLLL', $self->characters, 0, $self->width, $self->height );
	for my $char ( @{ $self->chars } ) {
		print $temp pack( 'C*', split( //, sprintf( '%08b', $_ ) ) ) for @$char;
	}
	close $temp;

	return GD::Font->load( $temp->filename );
}

=head2 clear( )

Clears any in-memory data.

=cut

sub clear {
	my $self = shift;

	$self->chars( [] );
}

=head2 width( )

Returns "8".

=cut

sub width {
	return 8;
}

=head2 char( $index, [$char] )

Get / set a char in the font.

=cut

sub char {
	my $self  = shift;
	my $index = shift;
	my $char  = $_[ 0 ];

	if( @_ ) {
		$self->{ _CHARS }->[ $index ] = $char;
		$self->height( scalar @$char );
	}
	
	return $self->{ _CHARS }->[ $index ];
}

=head2 characters( )

returns the number of characters in the font

=cut

sub characters {
	return scalar @{ $_[ 0 ]->chars };
}

=head2 height( [$height] )

returns the number of scanlines in each of the characters in the font

=cut

sub height {
	my $self   = shift;
	my $height = $_[ 0 ];

	if( @_ ) {
		$self->{ _HEIGHT } = $height;
	}

	return $self->{ _HEIGHT };
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