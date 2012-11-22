#!perl -T
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Task::EznGuide' ) || print "Bail out!\n";
}

diag( "Testing Task::EznGuide $Task::EznGuide::VERSION, Perl $], $^X" );
