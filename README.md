<!--
SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
SPDX-License-Identifier: BSD-2-Clause
-->

# Overwrite and preserve ownership

\[[Home][ringlet-home] | [Download][ringlet-download] | [GitHub][github] | [ReadTheDocs][readthedocs]\]

## Description

The `install-mimic` utility copies the specified files to the specified
destination (file or directory) similarly to `install(1)`, but it preserves
the ownership and access mode of the destination files.  This is useful when
updating files that have already been installed with locally modified copies
that may be owned by the current user and not by the desired owner of the
destination file (e.g. `root`).

## Examples:

Overwrite a system file with a local copy:

``` sh
install-mimic ./install-mimic.pl /usr/bin/install-mimic
```

Overwrite several files with local copies with the same name:

``` sh
install-mimic cinder/*.py /usr/lib/python2.7/dist-packages/cinder/
```

Install a new file similar to a system file:

``` sh
install-mimic -v -r /usr/bin/install-mimic install-none /usr/bin/
```

## Contact

The `install-mimic` utility was written by [Peter Pentchev][roam].
It is developed in [a GitHub repository][github]. This documentation is
hosted at [Ringlet][ringlet-home] with a copy at [ReadTheDocs][readthedocs].

[roam]: mailto:roam@ringlet.net "Peter Pentchev"
[github]: https://github.com/ppentchev/install-mimic "The install-mimic GitHub repository"
[readthedocs]: https://install-mimic.readthedocs.io/ "The install-mimic ReadTheDocs page"
[ringlet-home]: https://devel.ringlet.net/misc/install-mimic/ "The Ringlet install-mimic homepage"
[ringlet-download]: https://devel.ringlet.net/misc/install-mimic/download/ "The Ringlet install-mimic download page"
