use Test::More tests => 16;

BEGIN { 
    use_ok( 'Image::XBin::Font' );
    use_ok( 'Image::XBin::Font::Default' );
}

my $font = Image::XBin::Font->new;

isa_ok( $font, 'Image::XBin::Font' );

my $a    = [ 0x00, 0x00, 0x10, 0x38, 0x6c, 0xc6, 0xc6, 0xfe, 0xc6, 0xc6, 0xc6, 0xc6, 0x00, 0x00, 0x00, 0x00 ];
my $char = ord( 'A' );

$font->char( $char, $a );

is( $font->characters, $char + 1, '$font->charactes' );
is( $font->width, 8, '$font->width' );
is( $font->height, 16, '$font->height' );
is_deeply( $font->char( $char ), $a, '$font->char( 65 )' );

$font->clear;

is( $font->characters, 0, '$font->charactes' );
is( $font->width, 8, '$font->width' );
is( $font->height, 0, '$font->height' );
is( $font->char( $char ), undef, '$font->char( 65 )' );

$font = Image::XBin::Font::Default->new;
isa_ok( $font, 'Image::XBin::Font' );

is( $font->characters, 256, '$font->charactes' );
is( $font->width, 8, '$font->width' );
is( $font->height, 16, '$font->height' );
is_deeply( $font->char( $char ), $a, '$font->char( 65 )' );
