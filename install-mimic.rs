// SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
// SPDX-License-Identifier: BSD-2-Clause

use std::env;
use std::fs;
use std::io::ErrorKind;
use std::os::unix::fs::MetadataExt as _;
use std::process::Command;

use anyhow::{Context as _, Result, anyhow, bail};
use camino::{Utf8Path, Utf8PathBuf};
use clap::Parser as _;
use clap_derive::Parser;

#[derive(Parser)]
#[clap(version)]
struct Cli {
    /// Display the features supported by the program.
    #[clap(long)]
    features: bool,

    /// Specify a reference file to obtain the information from.
    #[clap(short)]
    reffile: Option<Utf8PathBuf>,

    /// Verbose operation; display diagnostic output.
    #[clap(short, long)]
    verbose: bool,

    filenames: Vec<Utf8PathBuf>,
}

const VERSION_STR: &str = env!("CARGO_PKG_VERSION");

struct Config {
    filenames: Vec<Utf8PathBuf>,
    destination: Utf8PathBuf,
    refname: Option<Utf8PathBuf>,
    verbose: bool,
}

enum Mode {
    Handled,
    Install(Config),
}

#[expect(clippy::print_stdout, reason = "This is the purpose of this function")]
fn features() {
    println!("Features: install-mimic={VERSION_STR}");
}

fn install_mimic<SP, DP, RP>(src: SP, dst: DP, refname: Option<&RP>, verbose: bool) -> Result<()>
where
    SP: AsRef<Utf8Path>,
    DP: AsRef<Utf8Path>,
    RP: AsRef<Utf8Path>,
{
    let filetoref = refname.as_ref().map_or_else(
        || dst.as_ref().to_path_buf(),
        |refpath| refpath.as_ref().to_path_buf(),
    );
    let stat = filetoref
        .metadata()
        .with_context(|| format!("Could not examine {filetoref}"))?;
    let user_id = stat.uid().to_string();
    let group_id = stat.gid().to_string();
    let mode = format!("{mode:o}", mode = stat.mode() & 0o7777);
    let prog_name = "install";
    let args = [
        "-c",
        "-o",
        &user_id,
        "-g",
        &group_id,
        "-m",
        &mode,
        "--",
        src.as_ref().as_str(),
        dst.as_ref().as_str(),
    ];
    let mut cmd = Command::new(prog_name);
    cmd.args(args);
    #[expect(clippy::print_stdout, reason = "This is the purpose of this function")]
    if verbose {
        println!("{prog_name} {args}", args = shell_words::join(args));
    }
    if !cmd.status().context("Could not run install")?.success() {
        bail!(
            "Could not install {src} as {dst}",
            src = src.as_ref(),
            dst = dst.as_ref()
        );
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
        .ok_or_else(|| anyhow!("No source or destination paths specified"))?;
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
        for path in &cfg.filenames {
            let basename = path
                .file_name()
                .ok_or_else(|| anyhow!("Invalid source filename {path}"))?;
            install_mimic(
                path,
                cfg.destination.join(basename),
                cfg.refname.as_ref(),
                cfg.verbose,
            )?;
        }
        Ok(())
    } else {
        match *cfg.filenames {
            [ref source] => {
                install_mimic(source, &cfg.destination, cfg.refname.as_ref(), cfg.verbose)
            }
            _ => bail!(
                "The destination path must be a directory if more than one source path is specified"
            ),
        }
    }
}

fn main() -> Result<()> {
    match parse_args().context("Could not parse the command-line arguments")? {
        Mode::Handled => Ok(()),
        Mode::Install(cfg) => doit(&cfg),
    }
}

#[cfg(test)]
#[expect(clippy::print_stdout, reason = "this is a test suite")]
#[expect(clippy::use_debug, reason = "this is a test suite")]
mod tests {
    use std::env;
    use std::io::ErrorKind as IoErrorKind;
    use std::process::{Command, Stdio};
    use std::sync::LazyLock;

    use anyhow::{Context as _, Result, anyhow, bail};
    use camino::{Utf8Path, Utf8PathBuf};

    static PATH: LazyLock<Result<Utf8PathBuf>> = LazyLock::new(|| {
        let current = Utf8PathBuf::from_path_buf(
            env::current_exe().context("Could not get the current executable file's path")?,
        )
        .map_err(|path| {
            anyhow!(
                "Could not represent the current executable file's path {path} as UTF-8",
                path = path.display()
            )
        })?;
        let exe_dir = {
            let basedir = current
                .parent()
                .ok_or_else(|| anyhow!("Could not get the parent directory of {current}"))?;
            if basedir
                .file_name()
                .ok_or_else(|| anyhow!("Could not get the base name of {basedir}"))?
                == "deps"
            {
                basedir
                    .parent()
                    .ok_or_else(|| anyhow!("Could not get the parent directory of {basedir}"))?
            } else {
                basedir
            }
        };
        let res = exe_dir.join("install-mimic");
        if !res.is_file() {
            bail!("Expected a file at {res}");
        }
        Ok(res)
    });

    fn get_exe_path() -> Result<&'static Utf8Path> {
        match PATH.as_deref() {
            Ok(res) => Ok(res),
            Err(err) => bail!("{err}"),
        }
    }

    #[test]
    fn prove() -> Result<()> {
        println!();
        let path = get_exe_path()?;

        // See if the 'prove' command even works
        let prove_path = "prove";
        match Command::new(prove_path)
            .args(["-V"])
            .stdout(Stdio::piped())
            .stderr(Stdio::inherit())
            .output()
        {
            Err(err) if err.kind() == IoErrorKind::NotFound => {
                println!("No '{prove_path}' command at all");
                return Ok(());
            }
            Err(err) => bail!(
                "Could not run '{prove_path}' at all: {kind}: {err}",
                kind = err.kind()
            ),
            Ok(output) if !output.status.success() => bail!("'{prove_path} -V' failed"),
            Ok(output) => {
                let contents = String::from_utf8(output.stdout).with_context(|| {
                    format!("Could not decode the output of '{prove_path} -V' as valid UTF-8")
                })?;
                println!("Got '{prove_path} -V' output {contents:?}");
                if !contents.starts_with("TAP::Harness") {
                    bail!(
                        "The output of '{prove_path} -V' did not start with 'TAP::Harness': {contents}"
                    )
                }
            }
        }

        if !Command::new(prove_path)
            .args(["-v", "t"])
            .env("INSTALL_MIMIC", path)
            .status()
            .with_context(|| format!("Could not run '{prove_path} -v t'"))?
            .success()
        {
            bail!("The TAP test suite failed");
        }
        Ok(())
    }
}
