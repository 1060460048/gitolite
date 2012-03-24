package Gitolite::Conf;

# explode/parse a conf file
# ----------------------------------------------------------------------

@EXPORT = qw(
  compile
  explode
  parse
);

use Exporter 'import';
use Getopt::Long;

use lib $ENV{GL_BINDIR};
use Gitolite::Common;
use Gitolite::Rc;
use Gitolite::Conf::Sugar;
use Gitolite::Conf::Store;

use strict;
use warnings;

# ----------------------------------------------------------------------

sub compile {
    trace(3);
    # XXX assume we're in admin-base/conf

    _chdir( $rc{GL_ADMIN_BASE} );
    _chdir("conf");

    parse(sugar('gitolite.conf'));

    # the order matters; new repos should be created first, to give store a
    # place to put the individual gl-conf files
    new_repos();
    store();
}

sub parse {
    my $lines = shift;
    trace(4, scalar(@$lines) . " lines incoming");

    for my $line (@$lines) {
        # user or repo groups
        if ( $line =~ /^(@\S+) = (.*)/ ) {
            add_to_group( $1, split( ' ', $2 ) );
        } elsif ( $line =~ /^repo (.*)/ ) {
            set_repolist( split( ' ', $1 ) );
        } elsif ( $line =~ /^(-|C|R|RW\+?(?:C?D?|D?C?)M?) (.* )?= (.+)/ ) {
            my $perm  = $1;
            my @refs  = parse_refs( $2 || '' );
            my @users = parse_users($3);

            # XXX what do we do? s/\bCREAT[EO]R\b/~\$creator/g for @users;

            for my $ref (@refs) {
                for my $user (@users) {
                    add_rule( $perm, $ref, $user );
                }
            }
        } elsif ( $line =~ /^config (.+) = ?(.*)/ ) {
            my ( $key, $value ) = ( $1, $2 );
            my @validkeys = split( ' ', ( $rc{GL_GITCONFIG_KEYS} || '' ) );
            push @validkeys, "gitolite-options\\..*";
            my @matched = grep { $key =~ /^$_$/ } @validkeys;
            # XXX move this also to add_config: _die "git config $key not allowed\ncheck GL_GITCONFIG_KEYS in the rc file for how to allow it" if (@matched < 1);
            # XXX both $key and $value must satisfy a liberal but secure pattern
            add_config( 1, $key, $value );
        } elsif ( $line =~ /^subconf (\S+)$/ ) {
            set_subconf($1);
        } else {
            _warn "?? $line";
        }
    }
}

1;
