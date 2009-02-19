use Test::More tests => 6;

BEGIN { 
    use_ok( 'Image::XBin::Pixel' );
}

my $pixel = Image::XBin::Pixel->new;

isa_ok( $pixel, 'Image::XBin::Pixel' );

$pixel->fg( 1 );
is( $pixel->fg, 1, '$pixel->fg' );

$pixel->bg( 1 );
is( $pixel->bg, 1, '$pixel->bg' );

$pixel->blink( 1 );
is( $pixel->blink, 1, '$pixel->blink' );

$pixel->char( 'A' );
is( $pixel->char, 'A', '$pixel->char' );