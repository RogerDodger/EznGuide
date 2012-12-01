#!/usr/bin/env perl

# Check if the github repo has been updated, 
# and rebuild the site if it has

use FindBin '$Bin';
chdir($Bin);

my $stdout = `git pull git://github.com/RogerDodger/EznGuide.git master`;

if( index( $stdout, 'Already up-to-date.' ) == -1 ) {
	`./eznguide_build.pl`;
}