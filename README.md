EznGuide
========

Webpage builder for Ezn's writing guide

##Installation

First off, install all missing dependencies from CPAN with the included
Task-EznGuide dummy module.

- `EznGuide$ cd Task-EznGuide`
- `EznGuide/Task-EznGuide$ cpan .`
- `EznGuide/Task-EznGuide$ make realclean`

Copy the config file and edit it appropriately.

- `EznGuide$ cp _config.yml config.yml`

Finally, build the site by running the build scipt.

- `EznGuide$ perl eznguide_build.pl`

##Note

All the site content is in `root/src`. Templates are loaded in asciibetical 
order, so preceding the templates with a number creates a desired order.