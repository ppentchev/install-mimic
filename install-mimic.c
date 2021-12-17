/*-
 * Copyright (c) 2016 - 2018, 2021  Peter Pentchev
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

#include <err.h>
#include <errno.h>
#include <inttypes.h>
#include <libgen.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef __printflike
#if defined(__GNUC__) && __GNUC__ >= 3
#define __printflike(x, y)	__attribute__((format(printf, (x), (y))))
#else
#define __printflike(x, y)
#endif
#endif

#define VERSION_STRING	"0.4.1"

static bool		verbose;

static void
version(void)
{
	puts("install-mimic " VERSION_STRING);
}

static void
usage(const bool _ferr)
{
	const char * const s =
	    "Usage:\tinstall-mimic [-v] [-r reffile] srcfile dstfile\n"
	    "\tinstall-mimic [-v] [-r reffile] file1 [file2...] directory\n"
	    "\tinstall-mimic -V | --version | -h | --help\n"
	    "\tinstall-mimic --features\n"
	    "\n"
	    "\t-h\tdisplay program usage information and exit\n"
	    "\t-r\tspecify a reference file to obtain the information from\n"
	    "\t-V\tdisplay program version information and exit\n"
	    "\t-v\tverbose operation; display diagnostic output\n";

	fprintf(_ferr? stderr: stdout, "%s", s);
	if (_ferr)
		exit(1);
}

static void __printflike(3, 4)
snprintf_check(char * const buf, const size_t sz, const char * const fmt, ...)
{
	va_list v;

	va_start(v, fmt);
	const int n = vsnprintf(buf, sz, fmt, v);
	va_end(v);
	if (n < 0 || (size_t)n >= sz)
		errx(1, "Internal error, could not fit '%s'-formatted output "
		    "into %zu characters", fmt, sz);
}

static void
debug_cmd(const char * const *cmd)
{
	if (!verbose)
		return;

	bool first = true;
	while (*cmd != NULL) {
		printf("%s%s", first? "": " ", *cmd);
		first = false;
		cmd++;
	}
	putchar('\n');
}

static void
check_wait_result(const pid_t pid, const int stat, const pid_t expected, const char * const progname)
{
	if (pid != expected)
		errx(1, "Waiting for %s: expected pid %ld, got %ld", progname, (long)expected, (long)pid);
	else if (WIFEXITED(stat) && WEXITSTATUS(stat) != 0)
		errx(1, "Child %s (pid %ld) exited with code %d", progname, (long)pid, WEXITSTATUS(stat));
	else if (WIFSIGNALED(stat))
		errx(1, "Child %s (pid %ld) was killed by signal %d", progname, (long)pid, WTERMSIG(stat));
	else if (WIFSTOPPED(stat))
		errx(1, "Child %s (pid %ld) was stopped by signal %d", progname, (long)pid, WSTOPSIG(stat));
	else if (!WIFEXITED(stat))
		errx(1, "Child %s (pid %ld) neither exited nor was killed or stopped; what in the world does wait(2) status %d mean?!", progname, (long)pid, stat);
}

static void
install_mimic(const char * const src, const char * const dst,
		const char * const ref)
{
	const char * const refname = ref != NULL? ref: dst;
	struct stat sb;
	if (stat(refname, &sb) == -1)
		err(1, "Could not stat %s", refname);

	char owner[20], group[20], mode[6];
	snprintf_check(owner, sizeof(owner), "%jd", (intmax_t)sb.st_uid);
	snprintf_check(group, sizeof(group), "%jd", (intmax_t)sb.st_gid);
	snprintf_check(mode, sizeof(mode), "%04o", sb.st_mode & 07777);

	const char * const cmd[] = {
		"install", "-c", "-o", owner, "-g", group, "-m", mode,
		"--", src, dst, NULL
	};
	debug_cmd(cmd);

	const pid_t pid = fork();
	if (pid == -1) {
		err(1, "Could not fork for install(1)");
	} else if (pid == 0) {
		execvp("install", (char * const *)cmd);
		err(1, "Could not execute install(1)");
	}
	int status;
	const pid_t wpid = waitpid(pid, &status, 0);
	if (wpid == -1)
		err(1, "Could not wait for the install(1) child");
	check_wait_result(wpid, status, pid, "install(1)");
}

static bool is_dir(const char * const path, const bool has_ref)
{
	struct stat st;
	if (stat(path, &st) == -1) {
		if (errno != ENOENT || !has_ref)
			err(1, "Could not check whether %s is a directory", path);
		return (false);
	}
	return (S_ISDIR(st.st_mode));
}

int
main(int argc, char * const argv[])
{
	bool features = false, hflag = false, Vflag = false;
	const char *ref = NULL;
	int ch;
	while (ch = getopt(argc, argv, "hr:Vv-:"), ch != -1)
		switch (ch) {
			case 'h':
				hflag = true;
				break;

			case 'r':
				ref = optarg;
				break;

			case 'V':
				Vflag = true;
				break;

			case 'v':
				verbose = true;
				break;

			case '-':
				if (strcmp(optarg, "features") == 0)
					features = true;
				else if (strcmp(optarg, "help") == 0)
					hflag = true;
				else if (strcmp(optarg, "version") == 0)
					Vflag = true;
				else
					usage(1);
				break;

			default:
				usage(1);
				/* NOTREACHED */
		}
	if (Vflag)
		version();
	if (hflag)
		usage(false);
	if (features)
		puts("Features: install-mimic=" VERSION_STRING);
	if (Vflag || hflag || features)
		return (0);

	argc -= optind;
	argv += optind;
	if (argc < 2)
		usage(true);

	const char * const last_dir = argv[argc - 1];
	if (is_dir(last_dir, ref != NULL)) {
		const size_t last_dir_len = strlen(last_dir);
		const bool has_slash = last_dir_len == 0? false:
		    last_dir[last_dir_len - 1] == '/';
		char *basebuf = NULL, *fullbuf = NULL;

		for (int i = 0; i < argc - 1; i++)
		{
			/* Sigh, basename(3) may modify its argument */
			const char * const src = argv[i];
			const size_t sz = strlen(src) + 1;
			basebuf = realloc(basebuf, sz);
			if (basebuf == NULL)
				err(1, "Could not allocate %zu bytes", sz);
			snprintf_check(basebuf, sz, "%s", src);
			const char * const base = basename(basebuf);

			const size_t fullsz = last_dir_len + !has_slash +
			    strlen(base) + 1;
			fullbuf = realloc(fullbuf, fullsz);
			if (fullbuf == NULL)
				err(1, "Could not allocate %zu bytes", fullsz);
			snprintf_check(fullbuf, fullsz, "%s%s%s",
			    last_dir, has_slash? "": "/", base);

			install_mimic(src, fullbuf, ref);
		}
		free(basebuf);
		free(fullbuf);
	} else {
		if (argc != 2)
			usage(true);
		install_mimic(argv[0], argv[1], ref);
	}
	return (0);
}
