#!/usr/bin/env perl

use 5.014;
use strict;
use Getopt::Long;

GetOptions(\my %opt, 'devel|development');

my @dependencies = qw(
	FindBin
	YAML
	File::Find
	File::Copy
	File::stat
	Digest::MD5::File
	Template
	Template::Stash
	DateTime
	Text::Markdown
	Text::Typography
	HTML::TreeBuilder
	Archive::Zip
	Getopt::Long
);

if (eval { require App::cpanminus; 1; }) {
	*install = sub { system 'cpanm', @_ };
}
else {
	require CPAN;
	CPAN->import;
}

say "Installing ependencies...";
install(@dependencies);
