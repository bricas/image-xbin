package Image::XBin::Pixel;

=head1 NAME

Image::XBin::Pixel - Pixel object

=head1 SYNOPSIS

	$pixel = Image::XBin::Pixel->new;

	# foreground color
	$pixel->fg( $fg );

	# background color
	$pixel->bg( $bg );

	# blinking
	$pixel->blink( $blink );

	# or all 3 from an attribute byte
	$pixel->attr( $attr );

	# the character
	$pixel->char( $char );

=cut

use base qw( Class::Accessor );

use strict;
use warnings;

# Attribute byte constants
use constant ATTR_BLINK => 128;
use constant ATTR_BG    => 112;
use constant ATTR_FG    => 15;

our $VERSION = '0.06';

__PACKAGE__->mk_accessors( qw( char fg bg blink ) );

=head1 METHODS

=head2 new( %options )

Create a new pixel and set its attributes.

=cut

sub new {
	my $class   = shift;
	my %options = @_;
	my $self    = {};

	bless $self, $class;

	$self->$_( $options{ $_ } ) for keys %options;

	return $self;
}

=head2 attr( [$attr] )

Set the foreground, background and blink properties from an attribute byte.

=cut

sub attr {
	my $self = shift;
	my $attr = $_[ 0 ];

	if( @_ ) {
		$self->fg( $attr & ATTR_FG );
		$self->bg( ( $attr & ATTR_BG ) >> 4 );
		$self->blink( ( $attr & ATTR_BLINK ) >> 7 );
	}
	else {
		$attr  = 0;
		$attr |= $self->fg;
		$attr |= ( $self->bg << 4 );
		$attr |= ( $self->blink << 7 );
	}

	return $attr;
}

=head2 fg( [$fg] )

Set the foreground color

=head2 bg( [$bg] )

Set the background color

=head2 blink( [$blink] )

Set the blink property

=head2 character( [$char] )

Set the character to be displayed

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
