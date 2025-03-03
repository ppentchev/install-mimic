#!/usr/bin/perl
#
# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: BSD-2-Clause

use v5.10;    ## no critic qw(ValuesAndExpressions::ProhibitVersionStrings)
use strict;
use warnings;

use English qw(CHILD_ERROR ERRNO RS -no_match_vars);
use Fcntl ':mode';
use File::Basename;
use Getopt::Std;
use POSIX ':sys_wait_h';

# We do pass a constant to `version->declare()`
## no critic qw(ValuesAndExpressions::RequireConstantVersion)
use version; our $VERSION = version->declare('0.4.1');

my $verbose = 0;

sub version() {
	say "install-mimic $VERSION";
	return;
}

sub debug($) {    ## no critic qw(Subroutines::RequireArgUnpacking)
	return unless $verbose;

	my ($msg) = @_;
	return unless defined $msg && length $msg;
	$msg =~ s/ \n* \Z //xms;
	say $msg;
	return;
}

sub check_wait_result($ $ $) {
	my ( $stat, $pid, $name ) = @_;

	if ( WIFEXITED($stat) ) {
		if ( WEXITSTATUS($stat) != 0 ) {
			die "Program '$name' (pid $pid) exited with "
				. "non-zero status "
				. WEXITSTATUS($stat) . "\n";
		}
	}
	elsif ( WIFSIGNALED($stat) ) {
		die "Program '$name' (pid $pid) was killed by signal " . WTERMSIG($stat) . "\n";
	}
	elsif ( WIFSTOPPED($stat) ) {
		die "Program '$name' (pid $pid) was stopped by signal " . WSTOPSIG($stat) . "\n";
	}
	else {
		die "Program '$name' (pid $pid) neither exited nor was "
			. "it killed or stopped; what does wait(2) status $stat "
			. "mean?!\n";
	}
}

sub run_command(@) {
	my @cmd = @_;
	debug "@cmd";
	my $pid = open my $pipe, q{-|};
	if ( !defined $pid ) {
		die "Could not fork for '@cmd': $ERRNO\n";
	}
	elsif ( $pid == 0 ) {
		exec { $cmd[0] } @cmd;
		die "Could not run '@cmd': $ERRNO\n";
	}

	my $output;
	{
		local $RS = undef;
		$output = <$pipe>;
	}
	my $res    = close $pipe;
	my $msg    = $ERRNO;
	my $status = $CHILD_ERROR;
	check_wait_result $status, $pid, "@cmd";
	if ( !$res ) {
		die "Some error occurred closing the pipe from '@cmd': $msg\n";
	}
	return $output;
}

sub install_mimic($ $; $) {
	my ( $src, $dst, $ref ) = @_;

	$ref //= $dst;
	my @st = stat $ref
		or die "Could not obtain information about $ref: $ERRNO\n";
	my $res = run_command 'install', '-c', '-o', $st[4], '-g', $st[5],
		'-m', sprintf( '%04o', S_IMODE( $st[2] ) ), $src, $dst;
	debug $res;
	return;
}

sub usage(;$) {
	my ($err) = @_;
	$err //= 1;

	my $s = <<'EOUSAGE'
Usage:	install-mimic [-v] [-r reffile] srcfile dstfile
	install-mimic [-v] [-r reffile] file1 [file2...] directory
	install-mimic -V | --version | -h | --help
	install-mimic --features

	-h	display program usage information and exit
	-V	display program version information and exit
	-r	specify a reference file to obtain the information from
	-v	verbose operation; display diagnostic output
EOUSAGE
		;

	if ($err) {
		die $s;    ## no critic qw(ErrorHandling::RequireCarping)
	}
	else {
		print "$s";
	}
	return;
}

MAIN:
{
	my %opts;

	getopts( 'hr:Vv-:', \%opts ) or usage;
	my $Vflag = $opts{V};
	my $hflag = $opts{h};
	my $features;
	if ( defined $opts{q{-}} ) {
		if ( $opts{q{-}} eq 'features' ) {
			$features = 1;
		}
		elsif ( $opts{q{-}} eq 'help' ) {
			$hflag = 1;
		}
		elsif ( $opts{q{-}} eq 'version' ) {
			$Vflag = 1;
		}
		else {
			usage;
		}
	}
	version if $Vflag;
	usage 0 if $hflag;
	if ($features) {
		say "Features: install-mimic=$VERSION";
	}
	exit 0 if $Vflag || $hflag || $features;

	$verbose = $opts{v};

	my $ref = $opts{r};
	if ( @ARGV > 1 && -d $ARGV[-1] ) {
		my $dir = pop @ARGV;

		install_mimic $_, "$dir/" . basename($_), $ref for @ARGV;
	}
	elsif ( @ARGV == 2 ) {
		install_mimic $ARGV[0], $ARGV[1], $ref;
	}
	else {
		usage;
	}
}
