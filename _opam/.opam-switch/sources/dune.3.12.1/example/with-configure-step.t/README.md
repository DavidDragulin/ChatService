This project shows how to add a configure step to a project using Dune.

In order to keep things composable, it offers several way to configure
the project:

1.  with the classic `./configure <args...>`. When doing this, the
    configuration script are run immediately, and the resulting configuration
    is frozen for the rest of the build.

2.  by copying `config.defaults` to `config` and editing it. The configuration
    scripts will be run as part of the build using what is written in `config`.
    When `config` is edited, the configuration scripts will be automatically
    rerun.

3.  by doing nothing. The configuration scripts will be run as part of the
    build using the default values provided in `config.defaults`.

Technically this is how it works:

`configure` is a simple OCaml script that:

- parses the command line
- generates a `config` file using what was given on the command line
- calls `ocaml real_configure.ml`
- `real_configure.ml` does some stuff and generates `config.full`

`config.full` is what is used by the rest of the build.

Now in order to support (2) and (3), we setup the following rules in the
toplevel `dune` file:

- a rule to produce `config` by copying `config.default`
- a rule to produce `config.full` by running `real_configure.ml`

This all works as described because if Dune knows how to build a file and this
file is already present in the source tree, it will always prefer the file
that's already there.
