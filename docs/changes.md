<!--
SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
SPDX-License-Identifier: BSD-2-Clause
-->

# Changelog

All notable changes to the install-mimic project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Rework the Rust implementation, bringing it up to date with
  Rust edition 2021 and with other changes since it was introduced.

## 0.4.0 (2018-05-04)

- Add the `--help` and `--version` long options.
- Add the `--features` long option.

## 0.3.1 (2017-09-29)

- In testing, get the file group from a new file created in
  the test directory to fix the case of enforced setgid directories.
- Create the test temporary directory in the system's temporary path
  to avoid future weird situations like the setgid case.

## 0.3.0 (2017-02-27)

- Add a Rust implementation.
- Fix a memory allocation bug in the C implementation leading to
  destination filename corruption when the target specified on
  the command line is a directory.

## 0.2.0 (2016-06-29)

- Explicitly test the Perl 5 implementation in the "test" target.
- Add tests for the -r reffile and -v command-line options.
- Let the tests continue if an expected file was not created.
- Add a C implementation.

## 0.1.1 (2016-06-28)

- Add the internal "dist" target for creating distribution tarballs.
- Add a test suite.
- Reorder the functions a bit to avoid prototype declarations.
- Make the usage() function fatal by default.
- Add a Travis CI configuration file and a cpanfile.
- Move development from GitLab to GitHub.
- Switch the homepage URL to HTTPS.

## 0.1.0 (2015-06-02)

- First public release.

[Unreleased]: https://github.com/ppentchev/install-mimic/compare/release%2F0.4.0...master
