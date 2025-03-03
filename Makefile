# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: BSD-2-Clause

PACKAGE=	install-mimic
VERSION=	`perl install-mimic.pl -V | awk "{print \\$$2}"`

PKG_DIR?=	..
PKG_TAR=	${PKG_DIR}/${PACKAGE}-${VERSION}.tar

PROG?=		install-mimic
MAN1?=		install-mimic.1.gz

PROG_RS?=	target/debug/install-mimic

STD_CPPFLAGS?=	-D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700

LFS_CPPFLAGS?=	-D_FILE_OFFSET_BITS=64
LFS_LDFLAGS?=

STD_CFLAGS?=	-std=c99
WARN_CFLAGS?=	-Wall -W -pedantic -Wbad-function-cast \
		-Wcast-align -Wchar-subscripts -Winline \
		-Wmissing-prototypes -Wnested-externs -Wpointer-arith \
		-Wredundant-decls -Wshadow -Wstrict-prototypes -Wwrite-strings

CC?=		gcc
CPPFLAGS?=
CPPFLAGS+=	${STD_CPPFLAGS} ${LFS_CPPFLAGS}
CFLAGS?=		-g -pipe
CFLAGS+=	${STD_CFLAGS} ${WARN_CFLAGS}
LDFLAGS?=
LDFLAGS+=	${LFS_LDFLAGS}
LIBS?=

CARGO?=		cargo

PREFIX?=	/usr
BINDIR?=	${PREFIX}/bin
SHAREDIR?=	${PREFIX}/share
MANDIR?=	${PREFIX}/share/man/man

CP?=		cp
ECHO?=		echo
GZIP?=		gzip -c9
INSTALL?=	install
MKDIR?=		mkdir -p
RM?=		rm -f
LN_S?=		ln -s

BINOWN?=	root
BINGRP?=	root
BINMODE?=	755

SHAREOWN?=	${BINOWN}
SHAREGRP?=	${BINGRP}
SHAREMODE?=	644

COPY?=		-c
STRIP?=		-s
INSTALL_PROGRAM?=	${INSTALL} ${COPY} ${STRIP} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE}
INSTALL_SCRIPT?=	${INSTALL} ${COPY} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE}
INSTALL_DATA?=	${INSTALL} ${COPY} -o ${SHAREOWN} -g ${SHAREGRP} -m ${SHAREMODE}

all:		${PROG} ${MAN1}

${PROG}:	${PROG}.o
		${CC} ${LDFLAGS} -o ${PROG} ${PROG}.o ${LIBS}

${PROG}.o:	${PROG}.c
		${CC} ${CPPFLAGS} ${CFLAGS} -c -o ${PROG}.o ${PROG}.c

${MAN1}:	${PROG}.1
		${GZIP} -cn9 ${PROG}.1 > ${MAN1} || (rm -f -- ${MAN1}; false)

${PROG_RS}:	${PROG}.rs
		${CARGO} build

install:	all
		${MKDIR} ${DESTDIR}${BINDIR}
		${INSTALL_SCRIPT} ${PROG} ${DESTDIR}${BINDIR}
		${MKDIR} ${DESTDIR}${MANDIR}1
		${INSTALL_DATA} ${MAN1} ${DESTDIR}${MANDIR}1

test-perl:	install-mimic.pl
		@[ -z "$$(command -v tidyall || true)" ] || printf "\n===== Validating the Perl 5 implementation\n\n"
		@[ -z "$$(command -v tidyall || true)" ] || tidyall -a --check-only

		@printf "\n===== Testing the Perl 5 implementation\n\n"
		[ -x install-mimic.pl ] || chmod +x install-mimic.pl
		env INSTALL_MIMIC=./install-mimic.pl prove t

test-c:		${PROG}
		@printf "\n===== Testing the C implementation\n\n"
		prove t

test-rust:	${PROG_RS}
		@printf "\n===== Testing the Rust implementation\n\n"
		env INSTALL_MIMIC=./${PROG_RS} prove t

test:		test-c test-perl

test-all:	test-c test-perl test-rust

clean:
		${RM} ${PROG} ${PROG}.o ${MAN1}
		[ ! -d "target" ] || ${CARGO} clean

distclean:	clean
		${RM} Cargo.lock

dist:
		[ -n "$$ALLOW_DIST_DEV" ] || devver
		@printf "\n===== Creating %s.*\n\n" "${PKG_TAR}"
		git archive --format=tar --prefix="${PACKAGE}-${VERSION}/" -o "${PKG_TAR}" HEAD || (rm -f -- "${PKG_TAR}"; false)
		gzip -nc9 "${PKG_TAR}" > "${PKG_TAR}.gz" || (rm -f -- "${PKG_TAR}.gz"; false)
		bzip2 -c9 "${PKG_TAR}" > "${PKG_TAR}.bz2" || (rm -f -- "${PKG_TAR}.bz2"; false)
		xz -c9 "${PKG_TAR}" > "${PKG_TAR}.xz" || (rm -f -- "${PKG_TAR}.xz"; false)
		rm -- "${PKG_TAR}"
		@printf "\n===== Created %s.*\n\n" "${PKG_TAR}"

.PHONY:		all install test-all test-c test-perl test-rust test clean dist
