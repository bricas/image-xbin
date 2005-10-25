use Test::More tests => 8;

BEGIN { 
	use_ok( 'Image::XBin' );
	use_ok( 'Image::XBin::Parser' );
	use_ok( 'Image::XBin::Pixel' );
	use_ok( 'Image::XBin::Font' );
	use_ok( 'Image::XBin::Font::Default' );
	use_ok( 'Image::XBin::Palette' );
	use_ok( 'Image::XBin::Palette::Default' );
	use_ok( 'Image::XBin::Util' );
}
