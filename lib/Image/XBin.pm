package Image::XBin;

=head1 NAME

Image::XBin - (DEPRECATED) Load, create, manipulate and save XBin image files

=head1 DEPRECATION NOTICE

    This module has been replaced by Image:TextMode.

=head1 SYNOPSIS

	use Image::XBin;

	# Read in a file...
	my $img = Image::XBin->new( file => 'myxbin.xb' );

	# Image width and height
	my $w = $img->width;
	my $h = $img->height;

	# get and put "pixels"
	my $pixel = $img->getpixel( $x, $y );
	$img->putpixel( $x, $y, $pixel );

	# font (XBin::Font)
	my $font = $img->font;

	# palette (XBin::Palette)
	my $palette = $img->palette;

	# save the data to a file
	$img->write( file => 'x.xb' );

=head1 DESCRIPTION

XBin stands for "eXtended BIN" -- an extention to the normal raw-image BIN files.

XBin features:

=over 4 

=item * allows for binary images up to 65536 columns wide, and 65536 lines high

=item * can have an alternate set of palette colors either in blink or in non-blink mode

=item * can have different textmode fonts from 1 to 32 scanlines high, consisting of either 256 or 512 different characters

=item * can be compressed

=back

XBin file stucture:

	+------------+
	| Header     |
	+------------+
	| Palette    |
	+------------+
	| Font       |
	+------------+
	| Image Data |
	+------------+

Note, the only required element is a header. See the XBin specs for for information.
http://www.acid.org/info/xbin/xbin.htm

=head1 INSTALLATION

To install this module via Module::Build:

	perl Build.PL
	./Build         # or `perl Build`
	./Build test    # or `perl Build test`
	./Build install # or `perl Build install`

To install this module via ExtUtils::MakeMaker:

	perl Makefile.PL
	make
	make test
	make install

=cut

use base qw( Class::Accessor );

use strict;
use warnings;

use Carp;
use Image::XBin::Parser;
use Image::XBin::Util;
use Image::XBin::Palette::Default;
use Image::XBin::Font::Default;
use GD;

our $VERSION = '0.06';

use constant XBIN_ID          => 'XBIN';

# Header byte constants
use constant PALETTE          => 1;
use constant FONT             => 2;
use constant COMPRESSED       => 4;
use constant NON_BLINK        => 8;
use constant FIVETWELVE_CHARS => 16;

my $header_template = 'A4 C S S C C';
my @header_fields   = qw( id eofchar width height fontsize flags );
my $eof_char        = chr( 26 );

__PACKAGE__->mk_accessors( @header_fields );

=head1 METHODS

=head2 new( %options )

Creates a new XBin image. Currently only reads in data.

	# filename
	$xbin = Image::XBin->new( file => 'file.xb' );
	
	# file handle
	$xbin = Image::XBin->new( handle => $handle );

	# string
	$xbin = Image::XBin->new( string => $string );

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
		return $self->read( @_ );
	}
	else {
		# create new using options
	}

	return $self;
}

=head2 clear(  )

Clears any in-memory data.

=cut

sub clear {
	my $self = shift;

	$self->id( XBIN_ID );
	$self->eofchar( $eof_char );
	$self->fontsize( undef );
	$self->flags( 0 );
	$self->width( 0 );
	$self->height( 0 );
	$self->font( undef );
	$self->palette( undef );
	$self->sauce( undef );
	$self->{ image } = undef;
}

=head2 read( %options )

Explicitly reads in an XBin.

=cut

sub read {
	my $self    = shift;
	my %options = @_;
	$self       = Image::XBin::Parser->new( %options );

	return $self;
}

=head2 write( %options )

Write the XBin data to a file, handle of string.

=cut

sub write {
	my $self    = shift;
	my %options = @_;
	my $file    = create_io_object( \%options, '>' );

	print $file $self->as_string;
}

=head2 as_string( )

Returns the XBin data as a string - suitable for saving.

=cut

sub as_string {
	my $self = shift;

	my $output;

	# must set header to uncompressed because we don't have a compression alg yet.
	# set old value back when done.
	# this is temporary!!!
	my $compressed = $self->is_compressed;
	$self->compress( 0 );

	# header
	$output .= pack( $header_template, map { $self->$_ } @header_fields );

	# palette
	if( $self->has_palette ) {
		$output .= $self->palette->as_string;
	}

	# font
	if( $self->has_font ) {
		$output .= $self->font->as_string;
	}

	# image
	if( $self->is_compressed ) {
		# RLE compression alg.
	}
	else {
		for my $y ( 0..$self->height - 1 ) {
			for my $x ( 0..$self->width - 1 ) {
				my $pixel = $self->getpixel( $x, $y );
				$output .= pack( 'C*', ord( $pixel->char ), $pixel->attr );
			}
		}
	}

	if( $self->sauce ) {
		$output .= $self->sauce->as_string;
	}

	# set old value
	$self->compress( $compressed );

	return $output;
}

=head2 as_png( [%options] )

Returns a binary PNG version of the image.

	# Thumbnail -- Default
	$xbin->as_png( mode => 'thumbnail' );

	# Full size
	$xbin->as_png( mode => 'full' );

This function is just a wrapper around as_png_thumbnail() and as_png_full().

=cut

sub as_png {
	my $self    = shift;
	my %options = @_;

        $options{ mode } = 'thumbnail' unless defined $options{ mode } and $options{ mode } eq 'full';

        if( $options{ mode } eq 'full' ) {
                return $self->as_png_full( @_ );
        }
        else {
                return $self->as_png_thumbnail( @_ );
	}
}

=head2 as_png_thumbnail( [%options] )

Creates a thumbnail version of the XBin.

=cut

sub as_png_thumbnail {
	my $self = shift;
	croak( "Not implemented" );
}

=head2 as_png_full( [%options] )

Creates a full-size replica of the image. You can pass a "crop" option to
crop the image at certain height.

	# Crop it after 25 (text-mode) rows
	$xbin->as_png_full( crop => 25 );

=cut

sub as_png_full {
	my $self    = shift;
	my %options = @_;
	my $crop    = ( defined $options{ crop } and $options{ crop } > 0 and $options{ crop } < $self->height ) ? $options{ crop } : $self->height;

	my $palette = $self->has_palette ? $self->palette : Image::XBin::Palette::Default->new;
	my $font    = $self->has_font ? $self->font : Image::XBin::Font::Default->new;

	my $image   = GD::Image->new( $self->width * 8, $crop * $font->height );

	my @colors;
        for( 0..15 ) {
		push @colors, $image->colorAllocate(
			map {
				$_->[ 0 ] / 63 * 255,
				$_->[ 1 ] / 63 * 255,
				$_->[ 2 ] / 63 * 255 
			} $palette->get( $_ )
		);
        }

	my $gdfont = $font->as_gd;

	# Create the png
	for my $y ( 0..$crop - 1 ) {
		for my $x ( 0..$self->width - 1 ) {
			my $pixel = $self->getpixel( $x, $y );
			if( $pixel->bg ) {
				$image->filledRectangle( $x * $font->width, $y * $font->height, ( $x + 1 ) * $font->width, ( $y + 1 ) * $font->height - 1, $colors[ $pixel->bg ] );
			}

			$image->string( $gdfont, $x * $font->width, $y * $font->height, $pixel->char, $colors[ $pixel->fg ] );
		}
	}

	return $image->png;
}

=head2 has_palette( )

Returns true if the file has a palette defined.

=cut

sub has_palette {
	return $_[ 0 ]->flags & PALETTE;
}

=head2 has_font( )

Returns true if the file has a font defined.

=cut

sub has_font {
	return ( $_[ 0 ]->flags & FONT ) >> 1;
}

=head2 is_compressed( )

Returns true if the data was (or is to be) compressed

=cut

sub is_compressed {
	my $self = shift;
	return $self->compress;
}

=head2 is_nonblink( )

Returns true if the file is in non-blink mode.

=cut

sub is_nonblink {
	return ( $_[ 0 ]->flags & NON_BLINK ) >> 3;
}

=head2 has_512chars( )

Returns true if the font associated with the XBin has 512 characters

=cut

sub has_512chars {
	return ( $_[ 0 ]->flags & FIVETWELVE_CHARS ) >> 4;
}

=head2 sauce( [File::SAUCE] )

Gets / sets the SAUCE object associated with the XBin.

=cut

sub sauce {
	my $self  = shift;
	my $sauce = shift;

	if( ref $sauce eq 'File::SAUCE' ) {
		$self->{ sauce } = $sauce;
	}
	elsif( $sauce ) {
		$self->{ sauce } = undef;

	}

	return $self->{ sauce };
}

=head2 putpixel( $x, $y, $pixel )

Sets the pixel at $x, $y with $pixel (which should be an Image::XBin::Pixel).

=cut

sub putpixel {
	my $self = shift;
	return $self->pixel( @_ );
}

=head2 getpixel( $x, $y )

Returns the Image::XBin::Pixel object at $x, $y (or undef).

=cut

sub getpixel {
	my $self = shift;
	return $self->pixel( @_ );
}

=head2 pixel( [$x, $y, $pixel] )

Generic get / set method used by both getpixel and putpixel.

=cut

sub pixel {
	my $self = shift;
	my( $x, $y, $pixel ) = @_;

	if( defined $pixel ) {
		$self->{ image }->[ $y * $self->width + $x ] = $pixel;
	}

	return $self->{ image }->[ $y * $self->width + $x ];
}

=head2 font( [Image::XBin::Font] )

Gets or sets the font. Must be of type Image::XBin::Font. Passing anything but that type
will remove the font and change related header data.

=cut

sub font {
	my $self = shift;
	my $font = $_[ 0 ];

	# set palette and header flags if it's a valid object
	if( @_ and ref $font eq 'Image::XBin::Font' ) {
		$self->{ font } = $font;
		$self->flags( $self->flags | FONT );
		$self->flags( $self->flags | FIVETWELVE_CHARS ) if $font->characters == 512;
	}
	# clear data otherwise
	elsif( @_ ) {
		$self->flags( $self->flags & ~FONT );
		$self->flags( $self->flags & ~FIVETWELVE_CHARS );
		$self->{ font } = undef;
	}

	return $self->{ font };
}

=head2 palette( [Image::XBin::Palette] )

Gets or sets the palette. Must be of type Image::XBin::Palette. Passing anything but that type
will remove the font and related header data.

=cut

sub palette {
	my $self    = shift;
	my $palette = $_[ 0 ];
	use Data::Dumper;

	# set palette and header flags if it's a valid object
	if( @_ and ref $palette eq 'Image::XBin::Palette' ) {
		$self->{ palette } = $palette;
		$self->flags( $self->flags | PALETTE );
	}
	# clear data otherwise
	elsif( @_ ) {
		$self->flags( $self->flags & ~PALETTE );
		$self->{ palette } = undef;
	}

	return $self->{ palette };
}

=head2 compress( [true or false] )

Get / sets the compression header value to true or false. Affect the
output from as_string() and write().

=cut

sub compress {
	my $self     = shift;
	my $compress = $_[ 0 ];

	# if $compress is true, set it in the flags. else, unset it
	if( @_ and $compress ) {
		$self->flags( $self->flags | COMPRESSED );
	}
	elsif( @_ ) {
		$self->flags( $self->flags & ~COMPRESSED );
	}

	return ( $self->flags & COMPRESSED ) >> 2;
}

=head2 width( )

Returns the image width.

=head2 height( )

Returns the image height.

=head1 TODO

=over 4

=item * fix write() method to include compression

=item * use new()'s options to create a new file from scratch

=back

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
