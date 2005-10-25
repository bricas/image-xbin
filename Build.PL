use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'Image::XBin',
	dist_author        => 'Brian Cassidy <bricas@cpan.org>',
	license            => 'perl',
	create_readme      => 1,
	create_makefile_pl => 'traditional',
	requires           => {
		'Class::Accessor' => 0,
		'File::SAUCE'     => 0.12,
		'File::Temp'      => 0,
		'GD'              => 2.17,
		'IO::File'        => 0,
		'IO::String'      => 0,
		'Test::More'      => 0
	},
);

$build->create_build_script;