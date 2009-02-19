use Test::More tests => 7;

BEGIN { 
    use_ok( 'Image::XBin::Palette' );
    use_ok( 'Image::XBin::Palette::Default' );
}

my $brightblack = [ 21,  21,  21  ];
my $index       = 8;

my $pal = Image::XBin::Palette->new;

isa_ok( $pal, 'Image::XBin::Palette' );

$pal->set( $index, $brightblack );
is_deeply( $pal->get( $index ), $brightblack, '$pal->get/set' );

$pal->clear;

is( $pal->get( $index ), undef, '$pal->clear' );

$pal = Image::XBin::Palette::Default->new;

isa_ok( $pal, 'Image::XBin::Palette' );
is_deeply( $pal->get( $index ), $brightblack, '$pal->get/set' );