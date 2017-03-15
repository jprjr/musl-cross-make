mingw-cross-make
===============

This is a fork of [musl-cross-make](https://github.com/richfelker/musl-cross-make),
but for mingw. I haven't tested it super-thoroughly yet, but it seems
to work!

It's a fast, Makefile-based approach for producing Windows-targeting
cross compilers. Features include:

- Single-stage GCC build, used to build both mingw and its own
  shared target libs depending on libc.

- No hard-coded absolute paths; resulting cross compilers can be
  copied/moved anywhere.

- Ability to build multiple cross compilers for different targets
  using a single set of patched source trees.

- Nothing is installed until running `make install`, and the
  installation location can be chosen at install time.

- Automatic download of source packages, including GCC prerequisites
  (GMP, MPC, MPFR), using https and checking hashes.


Usage
-----

The build system can be configured by providing a `config.mak` file in
the top-level directory. The only mandatory variable is `TARGET`, which
should contain a gcc target tuple (such as `i686-w64-mingw32`), but many
more options are available. See the provided `config.mak.dist` and
`presets/*` for examples.

To compile, run `make`. To install to `$(OUTPUT)`, run `make install`.

The default value for `$(OUTPUT)` is output; after installing here you
can move the cross compiler toolchain to another location as desired.



Supported `TARGET`s
-------------------

The following is a non-exhaustive list of `$(TARGET)` tuples that are
believed to work:

- `i686-w64-mingw32`
- `x86_64-w64-mingw32`


How it works
------------

The current mingw-cross-make is factored into two layers:

1. The top-level Makefile which is responsible for downloading,
   verifying, extracting, and patching sources, and for setting up a
   build directory, and

2. Litecross, the cross compiler build system, which is itself a
   Makefile symlinked into the build directory.

Most of the real magic takes place in litecross. It begins by setting
up symlinks to all the source trees provided to it by the caller, then
builds a combined `src_toolchain` directory of symlinks that combines
the contents of the top-level gcc and binutils source trees and
symlinks to gmp, mpc, and mpfr. One configured invocation them
configures all the GNU toolchain components together in a manner that
does not require any of them to be installed in order for the others
to use them.

Rather than building the whole toolchain tree at once, though,
litecross starts by building just the gcc directory and its
prerequisites, to get an `xgcc` that can be used to build mingw. It
then configures mingw, installs mingw's headers to a staging "build
sysroot", and builds mingw's crt libraries using those headers. At this point it
has all the prerequisites to build the full toolchain.

Litecross does not actually depend on the mingw-cross-make top-level
build system; it can be used with any pre-extracted, properly patched
set of source trees.


Project scope and goals
-----------------------

The primary goals of this project are to:

- Quickly build mingw cross-compilers.


Patches included
----------------

- Static-linked PIE support
- Addition of `--enable-default-pie`
- Fixes for SH-specific bugs and bitrot in GCC
- Support for J2 Core CPU target in GCC & binutils
- SH/FDPIC ABI support

Do these actually work on Windows? I'll be honest, I don't totally know.
