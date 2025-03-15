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
use File::stat;
use Getopt::Std;
use POSIX ':sys_wait_h';

# We do pass a constant to `version->declare()`
## no critic qw(ValuesAndExpressions::RequireConstantVersion)
use version; our $VERSION = version->declare('0.4.2');

my $verbose = 0;

sub version() {
	say "install-mimic $VERSION"
		or die "Could not write to the standard output stream: $EVAL_ERROR\n";
	return;
}

sub debug($) {    ## no critic qw(Subroutines::RequireArgUnpacking)
	return unless $verbose;

	my ($msg) = @_;
	return unless defined $msg && length $msg;
	$msg =~ s/ \n* \Z //xms;
	say $msg or die "Could not write to the standard error stream: $EVAL_ERROR\n";
	return;
}

sub check_wait_result($ $ $) {
	my ( $stat, $pid, $name ) = @_;

	if ( WIFEXITED($stat) ) {
		if ( WEXITSTATUS($stat) != 0 ) {
			die "Program '$name' (pid $pid) exited with "
				. 'non-zero status '
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

sub install_mimic($ $; $) {    ## no critic qw(ValuesAndExpressions::RequireInterpolationOfMetachars)
	my ( $src, $dst, $ref ) = @_;

	$ref //= $dst;
	my $st = stat $ref
		or die "Could not obtain information about $ref: $ERRNO\n";
	my $res = run_command 'install', '-c', '-o', $st->uid, '-g', $st->gid,
		'-m', sprintf( '%04o', S_IMODE( $st->mode ) ), $src, $dst;
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
		print "$s" or die "Could not write to the standard output stream: $EVAL_ERROR\n";
	}
	return;
}

MAIN:
{
	my %opts;

	getopts( 'hr:Vv-:', \%opts ) or usage;
	my $version_flag = $opts{V};
	my $help_flag    = $opts{h};
	my $features_flag;
	if ( defined $opts{q{-}} ) {
		if ( $opts{q{-}} eq 'features' ) {
			$features_flag = 1;
		}
		elsif ( $opts{q{-}} eq 'help' ) {
			$help_flag = 1;
		}
		elsif ( $opts{q{-}} eq 'version' ) {
			$version_flag = 1;
		}
		else {
			usage;
		}
	}
	version if $version_flag;
	usage 0 if $help_flag;
	if ($features_flag) {
		say "Features: install-mimic=$VERSION"
			or die "Could not write to the standard output stream: $EVAL_ERROR\n";
	}
	exit 0 if $version_flag || $help_flag || $features_flag;

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
