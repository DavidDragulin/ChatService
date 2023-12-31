Running the Coq Toplevel on a file that is not part of a stanza.

  $ cat >foo.v <<EOF
  > Definition mynat := nat.
  > EOF
  $ cat >dune-project <<EOF
  > (lang dune 3.0)
  > (using coq 0.3)
  > EOF
  $ dune coq top foo.v || echo failed
  Error: Cannot find file: foo.v
  Hint: Is the file part of a stanza?
  Hint: Has the file been written to disk?
  failed
