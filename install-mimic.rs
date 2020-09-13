/*-
 * Copyright (c) 2016 - 2018  Peter Pentchev
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

use std::{
    env,
    fs,
    io,
    io::Write,
    os::unix::fs::MetadataExt,
    path::Path,
    process::Command
};

use getopts::Options;

const USAGE_STR: &'static str = "Usage:	install-mimic [-v] [-r reffile] srcfile dstfile
	install-mimic [-v] [-r reffile] file1 [file2...] directory
	install-mimic -V | --version | -h | --help
	install-mimic --features

	-h	display program usage information and exit
	-V	display program version information and exit
	-r	specify a reference file to obtain the information from
	-v	verbose operation; display diagnostic output";

const VERSION_STR: &'static str = "0.4.0";

fn version()
{
	println!("install-mimic {}", VERSION_STR);
}

fn usage() -> !
{
	panic!("{}", USAGE_STR)
}

fn features()
{
	println!("Features: install-mimic={}", VERSION_STR);
}

fn stat_fatal(fname: &str) -> fs::Metadata
{
	match fs::metadata(fname) {
		Err(e) => panic!("Could not examine {}: {}", fname, e),
		Ok(m) => m,
	}
}

fn install_mimic(src: &str, dst: &str, refname: &Option<String>, verbose: bool)
{
	let filetoref = match *refname {
		Some(ref s) => s.clone(),
		None => String::from(dst),
	};
	let stat = stat_fatal(&filetoref);
	let uid = stat.uid().to_string();
	let gid = stat.gid().to_string();
	let mode = format!("{:o}", stat.mode() & 0o7777);
	let mut cmd = Command::new("install");
	cmd .args(&["-c",
	    "-o", &uid,
	    "-g", &gid,
	    "-m", &mode,
	    "--", src, dst,
	    ]);
	if verbose {
		println!("{:?}", cmd);
	}
	match cmd.status() {
		Err(e) => panic!("Could not run install: {}", e),
		Ok(m) => match m.success() {
			false => panic!("Could not install {} as {}", src, dst),
			true => m,
		}
	};
}

fn main()
{
	let args: Vec<String> = env::args().collect();

	let mut optargs = Options::new();
	optargs.optflag("", "features", "display program features information and exit");
	optargs.optflag("h", "help", "display program usage information and exit");
	optargs.optopt("r", "", "specify a reference file to obtain the information from", "");
	optargs.optflag("V", "version", "display program version information and exit");
	optargs.optflag("v", "", "verbose operation; display diagnostic output");
	let opts = match optargs.parse(&args[1..]) {
		Err(e) => {
			writeln!(io::stderr(), "{}", e).unwrap();
			usage()
		},
		Ok(m) => m,
	};
	if opts.opt_present("V") {
		version();
	}
	if opts.opt_present("h") {
		println!("{}", USAGE_STR);
	}
	if opts.opt_present("features") {
		features();
	}
	if opts.opt_present("h") || opts.opt_present("V") || opts.opt_present("features") {
		return;
	}
	let refname = opts.opt_str("r");
	let verbose = opts.opt_present("v");
		
	let lastidx = opts.free.len();
	if lastidx < 2 {
		usage();
	}
	let lastidx = lastidx - 1;
	let lastarg = &opts.free[lastidx];
	let is_dir = match Path::new(lastarg).exists() {
		true => stat_fatal(lastarg).is_dir(),
		false => match refname {
			Some(_) => false,
			None => usage(),
		},
	};
	if is_dir {
		let dstpath = Path::new(lastarg);
		for f in &opts.free[0..lastidx] {
			let basename = match Path::new(f).file_name() {
				None => panic!("Invalid source filename {}", f),
				Some(s) => s,
			};
			let dstname = match dstpath.join(Path::new(basename)).to_str() {
				None => panic!("Could not build a destination path for {} in {}", f, dstpath.display()),
				Some(s) => s,
			}.to_string();
			install_mimic(f, &dstname, &refname, verbose);
		}
	} else if lastidx != 1 {
		usage();
	} else {
		install_mimic(&opts.free[0], lastarg, &refname, verbose);
	}
}
