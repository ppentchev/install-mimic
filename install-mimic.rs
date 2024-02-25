/*-
 * Copyright (c) Peter Pentchev <roam@ringlet.net>
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

use std::env;
use std::fs;
use std::io::ErrorKind;
use std::os::unix::fs::MetadataExt;
use std::path::Path;
use std::process::Command;

use clap::Parser;
use expect_exit::{Expected, ExpectedWithError};

#[derive(Debug, Parser)]
#[clap(version)]
struct Cli {
    /// Display the features supported by the program.
    #[clap(long)]
    features: bool,

    /// Specify a reference file to obtain the information from.
    #[clap(short)]
    reffile: Option<String>,

    /// Verbose operation; display diagnostic output.
    #[clap(short, long)]
    verbose: bool,

    filenames: Vec<String>,
}

const USAGE_STR: &str = "Usage:	install-mimic [-v] [-r reffile] srcfile dstfile
	install-mimic [-v] [-r reffile] file1 [file2...] directory
	install-mimic -V | --version | -h | --help
	install-mimic --features

	-h	display program usage information and exit
	-V	display program version information and exit
	-r	specify a reference file to obtain the information from
	-v	verbose operation; display diagnostic output";

const VERSION_STR: &str = env!("CARGO_PKG_VERSION");

struct Config {
    filenames: Vec<String>,
    destination: String,
    refname: Option<String>,
    verbose: bool,
}

enum Mode {
    Handled,
    Install(Config),
}

fn usage() -> ! {
    expect_exit::exit(USAGE_STR)
}

#[allow(clippy::print_stdout)]
fn features() {
    println!("Features: install-mimic={VERSION_STR}");
}

#[allow(clippy::print_stdout)]
fn install_mimic<SP: AsRef<Path>, DP: AsRef<Path>>(
    src: SP,
    dst: DP,
    refname: &Option<String>,
    verbose: bool,
) {
    let src_path = src.as_ref().to_str().or_exit(|| {
        format!(
            "Could not build a source path from {src}",
            src = src.as_ref().display()
        )
    });
    let dst_path = dst.as_ref().to_str().or_exit(|| {
        format!(
            "Could not build a destination path from {dst}",
            dst = dst.as_ref().display()
        )
    });
    let filetoref = match *refname {
        Some(ref path) => path.clone(),
        None => dst_path.to_owned(),
    };
    let stat = fs::metadata(&filetoref).or_exit_e(|| format!("Could not examine {filetoref}"));
    let user_id = stat.uid().to_string();
    let group_id = stat.gid().to_string();
    let mode = format!("{mode:o}", mode = stat.mode() & 0o7777);
    let prog_name = "install";
    let args = [
        "-c", "-o", &user_id, "-g", &group_id, "-m", &mode, "--", src_path, dst_path,
    ];
    let mut cmd = Command::new(prog_name);
    cmd.args(args);
    if verbose {
        println!("{prog_name} {args}", args = shell_words::join(args));
    }
    if !cmd.status().or_exit_e_("Could not run install").success() {
        expect_exit::exit(&format!("Could not install {src_path} as {dst_path}"));
    }
}

#[allow(clippy::print_stdout)]
fn parse_args() -> Mode {
    let opts = Cli::parse();
    if opts.features {
        features();
        return Mode::Handled;
    }

    let mut filenames = opts.filenames;
    let destination = filenames.pop().or_exit_(USAGE_STR);
    if filenames.is_empty() {
        usage();
    }
    Mode::Install(Config {
        filenames,
        destination,
        refname: opts.reffile,
        verbose: opts.verbose,
    })
}

fn doit(cfg: &Config) {
    let is_dir = match fs::metadata(&cfg.destination) {
        Err(err) if err.kind() == ErrorKind::NotFound => {
            if cfg.refname.is_none() {
                usage();
            }
            false
        }
        Err(err) => {
            expect_exit::exit(&format!(
                "Could not examine {dst}: {err}",
                dst = cfg.destination
            ));
        }
        Ok(data) => data.is_dir(),
    };
    if is_dir {
        let dstpath: &Path = cfg.destination.as_ref();
        for path in &cfg.filenames {
            let pathref: &Path = path.as_ref();
            let basename = pathref
                .file_name()
                .or_exit(|| format!("Invalid source filename {path}"));
            install_mimic(path, dstpath.join(basename), &cfg.refname, cfg.verbose);
        }
    } else {
        match *cfg.filenames {
            [ref source] => install_mimic(source, &cfg.destination, &cfg.refname, cfg.verbose),
            _ => usage(),
        }
    }
}

fn main() {
    match parse_args() {
        Mode::Handled => (),
        Mode::Install(cfg) => doit(&cfg),
    };
}
