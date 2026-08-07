<!--
SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
SPDX-License-Identifier: BSD-2-Clause
-->

# Changelog

All notable changes to the install-mimic project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.4] - 2026-08-08

### Semi-incompatible changes

- Rust implementation:
    - bump MSRV to 1.88, mainly for compatibility with the `roundlet` crate

### Fixes

- Add the `.jj` directory to the `.gitignore` file to make sure we don't
  accidentally package it up anywhere.
- Use leading slashes in the `.gitignore` file when referring to files and
  directories at top level.

### Additions

- Rust implementation:
    - add some `execline` tools for local building and testing
    - make sure tests do not fail in the packaged crate
    - add the Ringlet homepage as a Cargo package field
- CI:
    - add sourcehut CI definitions for building and testing on Alpine Linux

### Other changes

- Rust implementation:
    - do not use inline trait bounds
    - add some more Clippy overrides: inline modules, use of `std`
    - switch from `eyre` to `anyhow`
    - use the `roundlet` crate's `cli-basic-clap` feature to parse command line arguments
    - use the `roundlet` crate's `test-exe-path` feature in the test suite
    - trim down the list of files packaged into the crate
- Documentation:
    - use `uvoxen` for the `publync` build

## [0.4.3] - 2025-10-23

### Semi-incompatible changes

- Rust implementation:
    - use `camino` for UTF-8 path handling

### Fixes

- Documentation:
    - actually run the `docs` environment when run via `tox-stages`

### Additions

- Documentation:
    - add configuration for the `publync` tool for publishing to the Ringlet website
- Rust implementation:
    - add a unit test that runs the TAP test suite

### Other changes

- Build framework:
    - use single quotes for the `$CARGO` variable expansion
    - drop the `dist` target
- Documentation:
    - use `reuse` 6.x with no changes
    - bump the lower version requirements for the dependencies to avoid
      a segfault with Python 3.14
- Rust implementation:
    - drop the `Debug` trait from various structs
    - switch from `anyhow` to `eyre` for error reporting
    - bump the lower version requirements for the dependencies to the versions
      available in the Debian stable distribution
    - use //-style comments for the SPDX tags

## [0.4.2] - 2025-03-15

### Fixes

- Perl implementation:
    - various fixes suggested by `perlcritic`
- Documentation:
    - fix the 0.4.1 link on the downloads page

### Other changes

- Documentation:
    - use `reuse` 5.x, switch to `REUSE.toml`
    - drop the dependency on `mkdocstrings`, we do not use it
    - use `uvoxen` to configure and run tests
- Perl implementation:
    - reformat the source code using `perltidy`
    - various fixes suggested by `perlcritic`
    - run `perltidy` and `perlcritic` via `tidyall` in the `test-perl` target
- Rust implementation:
    - declare MSRV 1.85 for the Rust 2024 edition
    - minor changes suggested by Clippy
    - use `clap_derive` explicitly

## [0.4.1] - 2024-02-26

### Additions

- Add an EditorConfig definitions file.
- Start some MkDocs-based documentation.
- Add a Tox configuration file for running the `reuse` SPDX check tool and
  building the documentation.
- Rust implementation:
    - add the `run-clippy.sh` tool for running diagnostic checks

### Other changes

- Switch to yearless copyright notices with my e-mail address.
- Use SPDX copyright and license tags.
- Rust implementation:
    - rework it, bringing it up to date with Rust edition 2021 and with
      other changes since it was introduced
    - use the `shell-words` crate
    - use the `clap` crate for command-line parsing
    - use `anyhow` instead of `expect-exit`
    - make the path to `cargo` configurable in the Makefile

## [0.4.0] - 2018-05-04

### Additions

- Add the `--help` and `--version` long options.
- Add the `--features` long option.

## [0.3.1] - 2017-09-29

### Fixes

- In testing, get the file group from a new file created in
  the test directory to fix the case of enforced setgid directories.
- Create the test temporary directory in the system's temporary path
  to avoid future weird situations like the setgid case.

## [0.3.0] - 2017-02-27

### Fixes

- Fix a memory allocation bug in the C implementation leading to
  destination filename corruption when the target specified on
  the command line is a directory.

### Additions

- Add a Rust implementation.

## [0.2.0] - 2016-06-29

### Fixes

- Explicitly test the Perl 5 implementation in the "test" target.
- Let the tests continue if an expected file was not created.

### Additions

- Add tests for the -r reffile and -v command-line options.
- Add a C implementation.

## [0.1.1] - 2016-06-28

### Additions

- Add the internal "dist" target for creating distribution tarballs.
- Add a test suite.
- Add a Travis CI configuration file and a cpanfile.

### Other changes

- Reorder the functions a bit to avoid prototype declarations.
- Make the usage() function fatal by default.
- Move development from GitLab to GitHub.
- Switch the homepage URL to HTTPS.

## [0.1.0] - 2015-06-02

### Started

- First public release.

[Unreleased]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.4...master
[0.4.4]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.3...release%2F0.4.4
[0.4.3]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.2...release%2F0.4.3
[0.4.2]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.1...release%2F0.4.2
[0.4.1]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.0...release%2F0.4.1
[0.4.0]: https://github.com/ppentchev/install-mimic/compare/release%2F0.3.1...release%2F0.4.0
[0.3.1]: https://github.com/ppentchev/install-mimic/compare/release%2F0.3.0...release%2F0.3.1
[0.3.0]: https://github.com/ppentchev/install-mimic/compare/release%2F0.2.0...release%2F0.3.0
[0.2.0]: https://github.com/ppentchev/install-mimic/compare/release%2F0.1.1...release%2F0.2.0
[0.1.1]: https://github.com/ppentchev/install-mimic/compare/release%2F0.1.0...release%2F0.1.1
[0.1.0]: https://github.com/ppentchev/install-mimic/releases/tag/release%2F0.1.0
