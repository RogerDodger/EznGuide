Static site generator for Ezn's writing guide

## Installation ##

    EznGuide$ perl Makefile.PL
    EznGuide$ cp config-template.yml config.yml

## Usage ##

Edit the configuration as appropriate, then run:

    EznGuide$ ./eznguide_build.pl

## Note ##

All the site content is in `root/src`. Templates are loaded in asciibetical
order, so preceding the templates with a number creates a desired order.
