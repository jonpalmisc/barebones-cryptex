This repo aims to be a "minimum working example" for building a program and
packaging it in a cryptex for use with the Apple SRD. The example cryptex in
the SRD repo uses quite a complicated build system which makes it hard to
follow the build process; this repo exists to clarify the essential parts of
the process.

Contained is the "simple server" example from the SRD repo. Running `make` will
build the server and package it in a cryptex. Running `make install` will
install the cryptex to your device (must set `CRYPTEXCTL_UDID`).

You are encouraged to read `Makefile` for more information and context.
