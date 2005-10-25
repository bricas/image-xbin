package Image::XBin::Palette::Default;

=head1 NAME

Image::XBin::Palette::Default - The default palette

=head1 SYNOPSIS

	$pal = Image::XBin::Palette::Default->new;

=cut

use base qw( Image::XBin::Palette );

use strict;
use warnings;

our $VERSION = '0.02';

my $palette = [
	[ 0,   0,   0   ], # black
	[ 42,  0,   0   ], # red
	[ 0,   42,  0   ], # green
	[ 42,  21,  0   ], # yellow
	[ 0,   0,   42  ], # blue
	[ 42,  0,   42  ], # magenta
	[ 0,   42,  42  ], # cya
	[ 42,  42,  42  ], # white
	                   # bright
	[ 21,  21,  21  ], # black
	[ 63,  21,  21  ], # red
	[ 21,  63,  21  ], # green
	[ 63,  63,  21  ], # yellow
	[ 21,  21,  63  ], # blue
	[ 63,  21,  63  ], # magenta
	[ 21,  63,  63  ], # cyan
	[ 63,  63,  63  ]  # white
];

=head1 METHODS

=head2 new( )

Creates a new default palette object.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new;

	bless $self, $class;

	for( 0..@$palette ) {
		$self->set( $_, $palette->[ $_ ] );
	}

	return $self;
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