use 5.014;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'Task-EznGuide';
all_from 'lib/Task/EznGuide.pm';

test_requires 'Test::More' => 0;

requires 'FindBin'               => 0;
requires 'YAML'                  => 0;
requires 'File::Find'            => 0;
requires 'File::Copy'            => 0;
requires 'File::stat'            => 0;
requires 'Digest::MD5::File'     => 0;
requires 'Template'              => 0;
requires 'Template::Stash'       => 0;
requires 'DateTime'              => 0;
requires 'Text::Markdown'        => 0;
requires 'HTML::TreeBuilder'     => 0;
requires 'Archive::Zip'          => 0;
requires 'Getopt::Long'          => 0;
requires 'File::Spec::Functions' => 0;

WriteAll;
