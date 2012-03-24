package Gitolite::Test;

# functions for the test code to use
# ----------------------------------------------------------------------

#<<<
@EXPORT = qw(
  try
  put
  text
);
#>>>
use Exporter 'import';
use File::Path qw(mkpath);
use Carp qw(carp cluck croak confess);

BEGIN {
    require Gitolite::Test::Tsh;
    *{'try'} = \&Tsh::try;
    *{'put'} = \&Tsh::put;
    *{'text'} = \&Tsh::text;
}

use strict;
use warnings;

# ----------------------------------------------------------------------

# required preamble for all tests
try "
    DEF gsh = /TRACE: gsh.SOC=/
    DEF reject = /hook declined to update/; /remote rejected.*hook declined/; /error: failed to push some refs to/

    DEF AP_1 = cd ../gitolite-admin; ok or die cant find admin repo clone;
    DEF AP_2 = AP_1; git add conf ; ok; git commit -m %1; ok; /master.* %1/
    DEF ADMIN_PUSH = AP_2 %1; glt push admin origin; ok; gsh; /master -> master/

    mkdir -p $ENV{HOME}/bin
    ln -sf $ENV{PWD}/src/gitolite $ENV{PWD}/t/glt ~/bin
    cd; rm -vrf .gito* gito* repositories

    cd tsh_tempdir;
    gitolite setup -a admin
" or die "could not setup the test environment; errors:\n\n" . text() . "\n\n";

1;
