#!/usr/bin/env perl

use FindBin '$Bin';
chdir($Bin);

@a = `git pull git://github.com/RogerDodger/EznGuide.git`;