package Image::XBin::Palette;

=head1 NAME

Image::XBin::Palette - Manipulate XBin palette data

=head1 SYNOPSIS

	use Image::XBin::Palette;

	# Read the data...
	my $pal = Image::XBin::Palette->new( $data );

	# Get
	my $rgb = $pal->get( $index );

	# Set
	$pal->set( $index, $rgb );

	# Get data suitable for saving...
	my $out = $pal->as_string;

	# Clear the data
	$pal->clear;

=head1 DESCRIPTION

Xbin images can contain palette (16 indexes) data. This module will allow you to create, and manipulate that data.

=cut

use strict;
use warnings;

our $VERSION = '0.06';

=head1 METHODS

=head2 new( [$data] )

Creates a new Image::XBin::Palette object. Unpacks 16 rgb triples.

=cut

sub new {
	my $class = shift;
	my $data  = shift;
	my $self  = {};

	bless $self, $class;

	$self->clear;
	$self->read( $data ) if $data;

	return $self;
}

=head2 read( $data )

Explicitly reads in data.

=cut

sub read {
	my $self    = shift;
	my $data    = shift;

	$self->{ data } = $data if ref( $data ) eq 'ARRAY';

	my @palette = unpack( 'C*', $data );

	my $palette = [];
	for my $i ( 0..15 ) {
		push @$palette, [];
		for my $j ( 0..2 ) {
			push @{ $palette->[ $#{ $palette } ] }, $palette[ $i * 3 + $j ];
		}
	}

	$self->{ data } = $palette;
}

=head2 as_string( )

Returns the palette as a pack()'ed string - suitable for saving in an XBin.

=cut

sub as_string {
	my $self = shift;

	my $output;

	for my $color ( @{ $self->{ data } } ) {
		$output .= pack( 'C', $_ ) for @{ $color };
	}

	return $output;
}

=head2 get( $index )

Get the rgb triple at index $index

=cut

sub get {
	my $self  = shift;
	my $index = shift;

	return $self->{ data }->[ $index ]; 
}

=head2 set( $index, $rgb )

Write an rgb triple at index $index

=cut

sub set {
	my $self = shift;
	my ( $index, $rgb ) = @_;

	$self->{ data }->[ $index ] = $rgb; 
}

=head2 clear( )

Clears any in-memory data.

=cut

sub clear {
	my $self = shift;

	$self->{ data } = [];
}

=head1 TODO

=over 4

=item * write some useful methods :)

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
