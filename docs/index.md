<!--
SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
SPDX-License-Identifier: BSD-2-Clause
-->

# install-mimic &mdash; overwrite and preserve ownership

## Description

The `install-mimic` utility copies the specified files to the specified
destination (file or directory) similarly to `install(1)`, but it preserves
the ownership and access mode of the destination files.  This is useful when
updating files that have already been installed with locally modified copies
that may be owned by the current user and not by the desired owner of the
destination file (e.g. `root`).

### Examples:

Overwrite a system file with a local copy:

	install-mimic ./install-mimic.pl /usr/bin/install-mimic

Overwrite several files with local copies with the same name:

	install-mimic cinder/*.py /usr/lib/python2.7/dist-packages/cinder/

Install a new file similar to a system file:

	install-mimic -v -r /usr/bin/install-mimic install-none /usr/bin/

## Download

The source of the `install-mimic` utility may be obtained at
[its devel.ringlet.net homepage.][devel]  It is developed in
[a GitHub Git repository.][github]

## Contact

Peter Pentchev <roam@ringlet.net>

[devel]: https://devel.ringlet.net/misc/install-mimic/
[github]: https://github.com/ppentchev/install-mimic
