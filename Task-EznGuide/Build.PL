use 5.014;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Task::EznGuide',
    license             => 'perl',
    dist_author         => q{Cameron <cthor@cpan.org>},
    dist_version_from   => 'lib/Task/EznGuide.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
		'FindBin'           => 0,
		'YAML'              => 0,
        'File::Find'        => 0,
		'File::Copy'        => 0,
		'File::stat'        => 0,
		'Digest::MD5::File' => 0,
		'Template'          => 0,
		'Template::Stash'   => 0,
		'Datetime'          => 0,
		'Text::Markdown'    => 0,
		'HTML::TreeBuilder' => 0,
		'Archive::Zip'      => 0,
		'Getopt::Long'      => 0,
    },
    add_to_cleanup     => [ 'Task-EznGuide-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
