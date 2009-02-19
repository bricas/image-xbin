package Image::XBin::Parser;

=head1 NAME

Image::XBin::Parser - Reads in XBin image files

=head1 SYNOPSIS

	my $parser = Image::XBin::Parser->new;
	my $xbin   = $parser->parse( file => 'xbin.xb' );

=cut

use strict;
use warnings;

use Image::XBin;
use Image::XBin::Pixel;
use Image::XBin::Palette;
use Image::XBin::Font;
use Image::XBin::Util;

use Carp;
use File::SAUCE;

# Compression type constants
use constant NO_COMPRESSION        => 0;
use constant CHARACTER_COMPRESSION => 64;
use constant ATTRIBUTE_COMPRESSION => 128;
use constant FULL_COMPRESSION      => 192;

# Compression byte constants
use constant COMPRESSION_TYPE      => 192;
use constant COMPRESSION_COUNTER   => 63;

our $VERSION        = '0.06';

my $eof_char        = chr( 26 );
my $header_template = 'A4 C S S C C';
my @header_fields   = qw( id eofchar width height fontsize flags );

=head1 METHODS

=head2 new( [%options] )

Creates a new parser object and reads in a file, handle or string.

=cut

sub new {
	my $class   = shift;
	my $self    = {};
	my %options = @_;

	bless $self, $class;

	$self->clear;

	if(
		exists $options{ file } or
		exists $options{ string } or
		exists $options{ handle }
	) {
		return $self->parse( @_ );
	}

	return $self;
}

=head2 clear( )

Clears the internal xbin object.

=cut

sub clear {
	my $self = shift;

	$self->xbin( Image::XBin->new );
}

=head2 parse( %options )

Reads in a file, handle or string

	my $parser = Image::XBin::Parser->new;

	# filename
	$xbin = $parser->parse( file => 'file.xb' );
	
	# file handle
	$xbin = $parser->parse( handle => $handle );

	# string
	$xbin = $parser->parse( string => $string );

=cut

sub parse {
	my $self    = shift;
	my %options = @_;
	my $file    = create_io_object( \%options, '<' );

	$self->clear;

	# do we have at least a minimal XBin?
	return unless ( $file->stat )[ 7 ] > 5;

	my $counter;
	my $content = do { local $/; <$file> };

	# does it start with the right data?
	return unless $content =~ /^XBIN$eof_char/;

	# store sauce rec and remove sauce from data
	$self->_parse_sauce( \$content );

	# parse header data
	$self->_parse_header( substr( $content, 0, 11 ) );

	$counter = 11;

	# read palette if it has one
	if ( $self->xbin->has_palette ) {
		$self->xbin->palette( Image::XBin::Palette->new( substr( $content, $counter, 48 ) ) );
		$counter += 48;
	}

	# read font if it has one
	if ( $self->xbin->has_font ) {
		my $fontsize = $self->xbin->fontsize;
		my $chars    = $fontsize * ( $self->xbin->has_512chars ? 512 : 256 );
		my $font     = Image::XBin::Font->new;

		my $charcnt  = 0;
		my $scanline = 1;
		my $buffer   = [];
		for my $byte ( unpack( 'C*', substr( $content, $counter, $chars ) ) ) {
			push @$buffer, $byte;
			if ( ++$scanline > $fontsize ) {
				$font->char( $charcnt, $buffer );
				$charcnt++;
				$scanline = 1;
				$buffer   = [];
			}
		}

		$self->xbin->font( $font );

		$counter += $chars;
	}

	# read compressed or uncompressed data
	if ( $self->xbin->is_compressed ) {
		$self->_parse_compressed( substr( $content, $counter ) );
	}
	else {
		$self->_parse_uncompressed( substr( $content, $counter ) );
	}

	return $self->xbin;
}

=head2 xbin( [$xbin] )

Gets / sets the internal XBin object.

=cut

sub xbin {
	my $self    = shift;
	my( $xbin ) = @_;

	if( @_ ) {
		$self->{ _XBIN } = $xbin;
	}

	return $self->{ _XBIN };
}

sub _parse_sauce {
	my $self       = shift;
	my $contentref = shift;
	my $sauce      = File::SAUCE->new( string => $$contentref );

	if( $sauce->has_sauce ) {
		$self->xbin->sauce( $sauce );
		$$contentref = $sauce->remove( string => $$contentref );
	}
}

sub _parse_header {
	my $self    = shift;
	my $content = shift;

	my %header;

	@header{ @header_fields } = unpack( $header_template, $content );

	$self->xbin->$_( $header{ $_ } ) for @header_fields;
}

sub _parse_compressed {
	my $self    = shift;
	my $content = shift;

	my @pixels  = unpack( 'C*', $content );

	my $x = 0;
	my $y = 0;

	while ( @pixels ) { 
		my $info    = shift( @pixels );
		my $type    = $info & COMPRESSION_TYPE;
		my $counter = ( $info & COMPRESSION_COUNTER ) + 1;

		my ( $char, $attr );

		while( @pixels and $counter ) {
			my $pixel = Image::XBin::Pixel->new;

			if ( $type == NO_COMPRESSION ) {
				$pixel->char( chr( shift( @pixels ) ) );
				$pixel->attr( shift( @pixels ) );
			}
			elsif ( $type == CHARACTER_COMPRESSION ) {
				$char = chr( shift( @pixels ) ) unless defined $char;

				$pixel->char( $char );
				$pixel->attr( shift( @pixels ) );
			}
			elsif ( $type == ATTRIBUTE_COMPRESSION ) {
				$attr = shift( @pixels ) unless defined $attr;

				$pixel->char( chr( shift( @pixels ) ) );
				$pixel->attr( $attr );
			}
			else { # FULL_COMPRESSION
				$char = chr( shift( @pixels ) ) unless defined $char;
				$attr = shift( @pixels ) unless defined $attr;

				$pixel->char( $char );
				$pixel->attr( $attr );
			}

			$self->xbin->putpixel( $x, $y, $pixel );

			$x++;
			if( $x == $self->xbin->width ) {
				$x = 0;
				$y++;
			}

			$counter--;
		}
	}
}

sub _parse_uncompressed {
	my $self    = shift;
	my $content = shift;

	my @pixels  = unpack( 'C*', $content );

	my $x = 0;
	my $y = 0;

	while( @pixels ) {
		my $pixel = Image::XBin::Pixel->new(
			char => chr( shift( @pixels ) ),
			attr => shift( @pixels )
		);

		$self->xbin->putpixel( $x, $y, $pixel );

		$x++;
		if( $x == $self->xbin->width ) {
			$x = 0;
			$y++;
		}
	}
}

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
