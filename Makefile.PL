#!/usr/bin/env perl

use 5.014;
use strict;

my @dependencies = qw(
	YAML
	Digest::MD5::File
	Template
	Template::Stash
	DateTime
	Text::Markdown
	Text::Typography
	HTML::TreeBuilder
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
