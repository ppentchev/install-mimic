/*-
 * SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
 * SPDX-License-Identifier: BSD-2-Clause
 */

use std::env;
use std::fs;
use std::io::ErrorKind;
use std::os::unix::fs::MetadataExt;
use std::path::Path;
use std::process::Command;

use anyhow::{bail, Context, Result};
use clap::Parser;

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

#[allow(clippy::print_stdout)]
fn features() {
    println!("Features: install-mimic={VERSION_STR}");
}

fn install_mimic<SP: AsRef<Path>, DP: AsRef<Path>>(
    src: SP,
    dst: DP,
    refname: &Option<String>,
    verbose: bool,
) -> Result<()> {
    let src_path = src.as_ref().to_str().with_context(|| {
        format!(
            "Could not build a source path from {src}",
            src = src.as_ref().display()
        )
    })?;
    let dst_path = dst.as_ref().to_str().with_context(|| {
        format!(
            "Could not build a destination path from {dst}",
            dst = dst.as_ref().display()
        )
    })?;
    let filetoref = match *refname {
        Some(ref path) => path.clone(),
        None => dst_path.to_owned(),
    };
    let stat =
        fs::metadata(&filetoref).with_context(|| format!("Could not examine {filetoref}"))?;
    let user_id = stat.uid().to_string();
    let group_id = stat.gid().to_string();
    let mode = format!("{mode:o}", mode = stat.mode() & 0o7777);
    let prog_name = "install";
    let args = [
        "-c", "-o", &user_id, "-g", &group_id, "-m", &mode, "--", src_path, dst_path,
    ];
    let mut cmd = Command::new(prog_name);
    cmd.args(args);
    #[allow(clippy::print_stdout)]
    if verbose {
        println!("{prog_name} {args}", args = shell_words::join(args));
    }
    if !cmd.status().context("Could not run install")?.success() {
        bail!("Could not install {src_path} as {dst_path}");
    }
    Ok(())
}

fn parse_args() -> Result<Mode> {
    let opts = Cli::parse();
    if opts.features {
        features();
        return Ok(Mode::Handled);
    }

    let mut filenames = opts.filenames;
    let destination = filenames
        .pop()
        .context("No source or destination paths specified")?;
    if filenames.is_empty() {
        bail!("At least one source and one destination path must be specified");
    }
    Ok(Mode::Install(Config {
        filenames,
        destination,
        refname: opts.reffile,
        verbose: opts.verbose,
    }))
}

fn doit(cfg: &Config) -> Result<()> {
    let is_dir = match fs::metadata(&cfg.destination) {
        Err(err) if err.kind() == ErrorKind::NotFound => {
            if cfg.refname.is_none() {
                bail!(
                    "The destination path {dst} does not exist and no -r specified",
                    dst = cfg.destination
                );
            }
            false
        }
        Err(err) => {
            bail!("Could not examine {dst}: {err}", dst = cfg.destination);
        }
        Ok(data) => data.is_dir(),
    };
    if is_dir {
        let dstpath: &Path = cfg.destination.as_ref();
        for path in &cfg.filenames {
            let pathref: &Path = path.as_ref();
            let basename = pathref
                .file_name()
                .with_context(|| format!("Invalid source filename {path}"))?;
            install_mimic(path, dstpath.join(basename), &cfg.refname, cfg.verbose)?;
        }
        Ok(())
    } else {
        match *cfg.filenames {
            [ref source] => install_mimic(source, &cfg.destination, &cfg.refname, cfg.verbose),
            _ => bail!("The destination path must be a directory if more than one source path is specified"),
        }
    }
}

fn main() -> Result<()> {
    match parse_args().context("Could not parse the command-line arguments")? {
        Mode::Handled => Ok(()),
        Mode::Install(cfg) => doit(&cfg),
    }
}
