package Gitolite::Hooks::Update;

# everything to do with the update hook
# ----------------------------------------------------------------------

@EXPORT = qw(
  update
  update_hook
);

use Exporter 'import';

use Gitolite::Common;
use Gitolite::Conf::Load;

use strict;
use warnings;

# ----------------------------------------------------------------------

sub update {
    trace( 3, @ARGV );
    # this is the *real* update hook for gitolite

    my ( $ref, $oldsha, $newsha, $oldtree, $newtree, $aa ) = args(@ARGV);

    my $ret = access( $ENV{GL_REPO}, $ENV{GL_USER}, $aa, $ref );
    trace( 1, "access($ENV{GL_REPO}, $ENV{GL_USER}, $aa, $ref) -> $ret" );
    _die $ret if $ret =~ /DENIED/;

    check_vrefs($ref, $oldsha, $newsha, $oldtree, $newtree, $aa);

    exit 0;
}

sub check_vrefs {
    my($ref, $oldsha, $newsha, $oldtree, $newtree, $aa) = @_;
    my $name_seen = 0;
    for my $vref ( vrefs($ENV{GL_REPO}, $ENV{GL_USER}) ) {
        trace(1, "vref=$vref");
        if ($vref =~ m(^VREF/NAME/)) {
            # this one is special; we process it right here, and only once
            next if $name_seen++;

            for my $ref ( map { chomp; s(^)(VREF/NAME/); $_; } `git diff --name-only $oldtree $newtree` ) {
                check_vref($aa, $ref);
            }
        } else {
            my($dummy, $pgm, @args) = split '/', $vref;
            $pgm = "$ENV{GL_BINDIR}/VREF/$pgm";
            -x $pgm or die "$vref: helper program missing or unexecutable\n";

            open( my $fh, "-|", $pgm, @_, $vref, @args ) or die "$vref: can't spawn helper program: $!\n";
            while (<$fh>) {
                my ( $ref, $deny_message ) = split( ' ', $_, 2 );
                check_vref($aa, $ref, $deny_message);
            }
            close($fh) or die $!
              ? "Error closing sort pipe: $!"
              : "$vref: helper program exit status $?";
        }
    }
}

sub check_vref {
    my ($aa, $ref, $deny_message) = @_;

    my $ret = access( $ENV{GL_REPO}, $ENV{GL_USER}, $aa, $ref );
    trace( 1, "access($ENV{GL_REPO}, $ENV{GL_USER}, $aa, $ref)", "-> $ret" );
    _die "$ret" . ( $deny_message ? "\n$deny_message" : '' )
        if $ret =~ /DENIED/ and $ret !~ /by fallthru/;
    trace( 1, "remember, fallthru is success here!") if $ret =~ /by fallthru/;
}

{
    my $text = '';

    sub update_hook {
        trace(1);
        if ( not $text ) {
            local $/ = undef;
            $text = <DATA>;
        }
        return $text;
    }
}

# ----------------------------------------------------------------------

sub args {
    my ( $ref, $oldsha, $newsha ) = @_;
    my ( $oldtree, $newtree, $aa );

    # this is special to git -- the hash of an empty tree
    my $empty = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';
    $oldtree = $oldsha eq '0' x 40 ? $empty : $oldsha;
    $newtree = $newsha eq '0' x 40 ? $empty : $newsha;

    my $merge_base = '0' x 40;
    # for branch create or delete, merge_base stays at '0'x40
    chomp( $merge_base = `git merge-base $oldsha $newsha` )
      unless $oldsha eq '0' x 40
          or $newsha eq '0' x 40;

    $aa = 'W';
    # tag rewrite
    $aa = '+' if $ref =~ m(refs/tags/) and $oldsha ne ( '0' x 40 );
    # non-ff push to ref (including ref delete)
    $aa = '+' if $oldsha ne $merge_base;

    # XXX $aa = 'D' if ( $repos{$ENV{GL_REPO}}{DELETE_IS_D} or $repos{'@all'}{DELETE_IS_D} ) and $newsha eq '0' x 40;
    # XXX $aa = 'C' if ( $repos{$ENV{GL_REPO}}{CREATE_IS_C} or $repos{'@all'}{CREATE_IS_C} ) and $oldsha eq '0' x 40;

    # and now "M" commits.  This presents a bit of a problem.  All the other
    # accesses (W, +, C, D) were mutually exclusive in some sense.  Sure a W could
    # be a C or a + could be a D but that's by design.  A merge commit, however,
    # could still be any of the others (except a "D").

    # so we have to *append* 'M' to $aa (if the repo has MERGE_CHECK in
    # effect and this push contains a merge inside)

=for XXX
    if ( $repos{ $ENV{GL_REPO} }{MERGE_CHECK} or $repos{'@all'}{MERGE_CHECK} ) {
        if ( $oldsha eq '0' x 40 or $newsha eq '0' x 40 ) {
            warn "ref create/delete ignored for purposes of merge-check\n";
        } else {
            $aa .= 'M' if `git rev-list -n 1 --merges $oldsha..$newsha` =~ /./;
        }
    }
=cut

    return ( $ref, $oldsha, $newsha, $oldtree, $newtree, $aa );
}

1;

__DATA__
#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    exit 0 if $ENV{GL_BYPASS_UPDATE_HOOK};
    die "GL_BINDIR not set; aborting\n" unless $ENV{GL_BINDIR};
}
use lib $ENV{GL_BINDIR};
use Gitolite::Hooks::Update;

# gitolite update hook
# ----------------------------------------------------------------------

update();               # is not expected to return
exit 1;                 # so if it does, something is wrong
