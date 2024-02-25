#!/usr/bin/perl
#
# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: BSD-2-Clause

use v5.010;
use strict;
use warnings;

use File::stat;
use File::Temp;
use Test::More;

sub spurt_attr($ $)
{
	my ($fname, $data) = @_;

	open my $f, '>', $fname or
	    die "Could not open $fname for writing: $!\n";
	say $f $data->{contents} or
	    die "Could not write to $fname: $!\n";
	close $f or
	    die "Could not close $fname after writing: $!\n";
	chmod $data->{mode}, $fname or
	    die sprintf 'Could not set mode %4o on %s: %s\n',
	    $data->{mode}, $fname, $!;
	if ($> == 0 && defined $data->{owner}) {
		chown $data->{owner}[0], $data->{owner}[1], $fname or
		    die "Could not set owner $data->{owner}[0] and ".
		    "group $data->{owner}[1] on $fname: $!\n";
	}
}

sub get_non_root_owner($)
{
	my ($d) = @_;

	my $test_file = "$d/group-test.txt";
	spurt_attr $test_file, {
		contents => 'This is a test, is it not?',
		mode => 0644,
	};
	my $stat = stat $test_file or
	    die "Could not examine the test file $test_file: $!\n";
	my $gid = $stat->gid;

	my $o = [$>, $gid];
	return $o unless $o->[0] == 0;

	while (my @u = getpwent) {
		# If the group ID of the created file is non-zero, then
		# either we're not root (but this case should've been
		# handled above), or we have a setgid directory.
		# Either way, we should use/expect that group ID.
		#
		return [$u[2], $gid || $u[3]] if $u[2] > 0;
	}
	return $o;
}

sub reinit_test_data($ $)
{
	my ($d, $files) = @_;

	for my $f (sort keys %{$files}) {
		my $data = $files->{$f};
		spurt_attr "$d/$_/$f.txt", $data->{$_} for qw(src dst);
	}
}

sub check_file_attrs($ $)
{
	my ($fname, $data) = @_;

	my $st = stat $fname;
	if (!$st) {
		my $msg = $!;
		fail "$fname has the correct $_: $msg" for qw(mode owner group);
		return;
	}
	is $st->mode & 07777, $data->{mode}, "$fname has the correct mode";
	is $st->uid, $data->{owner}[0], "$fname has the correct owner";
	is $st->gid, $data->{owner}[1], "$fname has the correct group";
}

sub check_file_contents($ $)
{
	my ($fname, $contents) = @_;

	my $desc = "$fname has the correct contents";
	my $line;
	eval {
		open my $f, '<', $fname or
		    die "Could not open $fname for reading: $!\n";
		$line = <$f>;
		if (!defined $line) {
			die "Could not read even a single line from $fname: $!\n";
		}
		if (defined scalar <$f>) {
			die "Read more than one line from $fname\n";
		}
		close $f or
		    die "Could not close $fname after reading: $!\n";
		chomp $line;
	};
	if ($@) {
		my $msg = $@;
		$msg =~ s/\n*\Z//;
		fail "$desc: $msg";
		return;
	}
	is $contents, $line, $desc;
}

sub capture($ @)
{
	my ($close_stderr, @cmd) = @_;

	my $pid = open my $f, '-|';
	if (!defined $pid) {
		die "Could not fork for '@cmd': $!\n";
	} elsif ($pid == 0) {
		close STDERR if $close_stderr;
		exec { $cmd[0] } @cmd;
		die "Could not execute '@cmd': $!\n";
	}
	my @data = <$f>;
	chomp for @data;
	close $f;
	my $status = $? >> 8;
	return { exitcode => $status, lines => [ @data ] };
}

my $d = File::Temp->newdir(TEMPLATE => 'test-data.XXXXXX', TMPDIR => 1) or
    die "Could not create a temporary directory: $!\n";

for my $comp (qw(src dst)) {
	mkdir "$d/$comp" or
	    die "Could not create the $d/$comp directory: $!\n";
}

my %files = (
	1 => {
		src => {
			mode => 0601,
			contents => 'one',
		},
		dst => {
			mode => 0600,
			contents => 'something',
		},
	},

	2 => {
		src => {
			mode => 0602,
			contents => 'two',
		},
		dst => {
			mode => 0644,
			contents => 'something else',
		},
	},

	3 => {
		src => {
			mode => 0603,
			contents => 'three',
		},
		dst => {
			mode => 0755,
			contents => 'something different',
		},
	},
);

my $owner = get_non_root_owner $d;
for my $f (keys %files) {
	$_->{owner} = $owner for values %{$files{$f}};
}

my $prog = $ENV{INSTALL_MIMIC} // './install-mimic';

plan tests => 90;

my $c = capture(1, $prog);
isnt $c->{exitcode}, 0, "$prog with no parameters failed";
is scalar @{$c->{lines}}, 0, "$prog with no parameters output nothing";

$c = capture(1, $prog, '-X', '-Y', '-Z');
isnt $c->{exitcode}, 0, "$prog with bogus parameters failed";
is scalar @{$c->{lines}}, 0, "$prog with bogus parameters output nothing";

$c = capture(1, $prog, $prog);
isnt $c->{exitcode}, 0, "$prog with a single filename parameter failed";
is scalar @{$c->{lines}}, 0, "$prog with a single filename parameter output nothing";

$c = capture(0, $prog, '-V');
is $c->{exitcode}, 0, "$prog -V succeeded";
is scalar @{$c->{lines}}, 1, "$prog -V output a single line";
my $version_line = $c->{lines}[0];

$c = capture(0, $prog, '--version');
is $c->{exitcode}, 0, "$prog --version succeeded";
is scalar @{$c->{lines}}, 1, "$prog --version output a single line";
is $c->{lines}[0], $version_line, "$prog --version output the same as $prog -V";

$c = capture(0, $prog, '-h');
is $c->{exitcode}, 0, "$prog -h succeeded";
my @usage_lines = @{$c->{lines}};
my $h_lines = scalar @{$c->{lines}};
ok scalar @usage_lines > 1, "$prog -h output more than one line";

$c = capture(0, $prog, '--help');
is $c->{exitcode}, 0, "$prog --help succeeded";
is_deeply $c->{lines}, \@usage_lines, "$prog --help output the same as $prog -h";

$c = capture(0, $prog, '-h', '-V');
is $c->{exitcode}, 0, "$prog -h -V succeeded";
if ($prog =~ m{/target/}) {
	is scalar @{$c->{lines}}, scalar @usage_lines, "$prog -h output as many lines as $prog -h";
} else {
	is scalar @{$c->{lines}}, scalar @usage_lines + 1, "$prog -h -V output one line more than $prog -h";
}

$c = capture(0, $prog, '--features');
is $c->{exitcode}, 0, "$prog --features succeeded";
is scalar @{$c->{lines}}, 1, "$prog --features output a single line";
like $c->{lines}[0], qr{^ Features: \s+ .* \b install-mimic = \w+ \b }x,
    "$prog --features output a Features line containing install-mimic";

# OK, let's start doing stuff
reinit_test_data $d, \%files;

for my $f (sort keys %files) {
	my $data = $files{$f};
	my $src = "$d/src/$f.txt";
	my $dst = "$d/dst/$f.txt";
	my $c = capture(0, $prog, '--', $src, $dst);
	is $c->{exitcode}, 0, "'$prog $src $dst' succeeded";
	is scalar @{$c->{lines}}, 0, "'$prog $src $dst' output nothing";

	check_file_attrs $dst, $data->{dst};
	check_file_contents $dst, $data->{src}{contents};
}

reinit_test_data $d, \%files;

for my $f (sort keys %files) {
	my $data = $files{$f};
	my $src = "$d/src/$f.txt";
	my $dst = "$d/dst/$f.txt";

	check_file_attrs $dst, $data->{dst};
	check_file_contents $dst, $data->{dst}{contents};
}

$c = capture(0, $prog, '--', (map "$d/src/$_.txt", sort keys %files), "$d/dst");
is $c->{exitcode}, 0, "'$prog all-files $d/dst' succeeded";
is scalar @{$c->{lines}}, 0, "'$prog all-files $d/dst' output nothing";

for my $f (sort keys %files) {
	my $data = $files{$f};
	my $src = "$d/src/$f.txt";
	my $dst = "$d/dst/$f.txt";

	check_file_attrs $dst, $data->{dst};
	check_file_contents $dst, $data->{src}{contents};
}

my $ffname = "$d/dst/f3.txt";
ok ! -e "$d/dst/f3.txt", "$ffname does not exist yet";

$c = capture(0, $prog, '-r', "$d/dst/3.txt", '--', "$d/src/3.txt", $ffname);
is $c->{exitcode}, 0, "'$prog -r' succeeded";
is scalar @{$c->{lines}}, 0, "'$prog -r' output nothing";

check_file_attrs $ffname, $files{3}{dst};
check_file_contents $ffname, $files{3}{src}{contents};

ok ! -e "$d/dst-r", "$d/dst-r/ does not exist yet";
mkdir "$d/dst-r", 0755 or die "Could not create the $d/dst-r/ directory: $!\n";

$c = capture(0, $prog, '-r', "$d/dst/2.txt", '--', (map "$d/src/$_.txt", sort keys %files), "$d/dst-r");
is $c->{exitcode}, 0, "'$prog -r all' succeeded";
is scalar @{$c->{lines}}, 0, "'$prog -r all' output nothing";

for my $f (sort keys %files) {
	my $data = $files{$f};
	my $src = "$d/src/$f.txt";
	my $dst = "$d/dst-r/$f.txt";

	check_file_attrs $dst, $files{2}{dst};
	check_file_contents $dst, $data->{src}{contents};
}

$c = capture(0, $prog, '-v', '--', "$d/src/3.txt", $ffname);
is $c->{exitcode}, 0, "'$prog -v' succeeded";
is scalar @{$c->{lines}}, 1, "'$prog -v' output a single line";

$c = capture(0, $prog, '-v', '--', (map "$d/src/$_.txt", sort keys %files), "$d/dst-r");
is $c->{exitcode}, 0, "'$prog -v all' succeeded";
is scalar @{$c->{lines}}, scalar keys %files, "'$prog -v all' output the correct number of lines";
