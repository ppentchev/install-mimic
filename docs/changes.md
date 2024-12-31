<!--
SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
SPDX-License-Identifier: BSD-2-Clause
-->

# Changelog

All notable changes to the install-mimic project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixes

- Documentation:
    - fix the 0.4.1 link on the downloads page

### Other changes

- Documentation:
    - use `reuse` 4.x, switch to `REUSE.toml`
    - drop the dependency on `mkdocstrings`, we do not use it
- Rust implementation:
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

[Unreleased]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.1...master
[0.4.1]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.0...release%2F0.4.1
[0.4.0]: https://github.com/ppentchev/install-mimic/compare/release%2F0.3.1...release%2F0.4.0
[0.3.1]: https://github.com/ppentchev/install-mimic/compare/release%2F0.3.0...release%2F0.3.1
[0.3.0]: https://github.com/ppentchev/install-mimic/compare/release%2F0.2.0...release%2F0.3.0
[0.2.0]: https://github.com/ppentchev/install-mimic/compare/release%2F0.1.1...release%2F0.2.0
[0.1.1]: https://github.com/ppentchev/install-mimic/compare/release%2F0.1.0...release%2F0.1.1
[0.1.0]: https://github.com/ppentchev/install-mimic/releases/tag/release%2F0.1.0
