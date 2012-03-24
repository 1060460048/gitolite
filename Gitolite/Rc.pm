package Gitolite::Rc;

# everything to do with 'rc'.  Also defines some 'constants'
# ----------------------------------------------------------------------

@EXPORT = qw(
  $GL_ADMIN_BASE
  $GL_REPO_BASE

  $GL_UMASK

  $GL_GITCONFIG_KEYS

  glrc_default_text
  glrc_default_filename
  glrc_filename

  $ADC_CMD_ARGS_PATT
  $REF_OR_FILENAME_PATT
  $REPONAME_PATT
  $REPOPATT_PATT
  $USERNAME_PATT

  $current_data_version
);

use Exporter 'import';

use lib $ENV{GL_BINDIR};
use Gitolite::Common;

# variables that are/could be/should be in the rc file
# ----------------------------------------------------------------------

$GL_ADMIN_BASE = "$ENV{HOME}/.gitolite";
$GL_REPO_BASE  = "$ENV{HOME}/repositories";

# variables that should probably never be changed
# ----------------------------------------------------------------------

$current_data_version = "3.0";

$ADC_CMD_ARGS_PATT    = qr(^[0-9a-zA-Z._\@/+:-]*$);
$REF_OR_FILENAME_PATT = qr(^[0-9a-zA-Z][0-9a-zA-Z._\@/+ :,-]*$);
$REPONAME_PATT        = qr(^\@?[0-9a-zA-Z][0-9a-zA-Z._\@/+-]*$);
$REPOPATT_PATT        = qr(^\@?[0-9a-zA-Z[][\\^.$|()[\]*+?{}0-9a-zA-Z._\@/,-]*$);
$USERNAME_PATT        = qr(^\@?[0-9a-zA-Z][0-9a-zA-Z._\@+-]*$);

# ----------------------------------------------------------------------

use strict;
use warnings;

# ----------------------------------------------------------------------

my $rc = glrc_filename();
do $rc if -r $rc;

{
    my $glrc_default_text = '';

    sub glrc_default_text {
        trace( 1, "..should happen only on first run" );
        return $glrc_default_text if $glrc_default_text;
        local $/ = undef;
        $glrc_default_text = <DATA>;
    }
}

sub glrc_default_filename {
    trace( 1, "..should happen only on first run" );
    return "$ENV{HOME}/.gitolite.rc";
}

# where is the rc file?
sub glrc_filename {
    trace(4);

    # search $HOME first
    return "$ENV{HOME}/.gitolite.rc" if -f "$ENV{HOME}/.gitolite.rc";
    trace( 2, "$ENV{HOME}/.gitolite.rc not found" );

    # XXX for fedora, we can add the following line, but I would really prefer
    # if ~/.gitolite.rc on each $HOME was just a symlink to /etc/gitolite.rc
    # XXX return "/etc/gitolite.rc" if -f "/etc/gitolite.rc";

    return '';
}

1;

# ----------------------------------------------------------------------

__DATA__
# configuration variables for gitolite

# PLEASE READ THE DOCUMENTATION BEFORE EDITING OR ASKING QUESTIONS

# this file is in perl syntax.  However, you do NOT need to know perl to edit
# it; it should be fairly self-explanatory and easy to maintain

$GL_UMASK = 0077;
$GL_GITCONFIG_KEYS = "";

# ------------------------------------------------------------------------------
# per perl rules, this should be the last line in such a file:
1;

# Local variables:
# mode: perl
# End:
# vim: set syn=perl:
