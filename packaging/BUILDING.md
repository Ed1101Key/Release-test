# Building packages

This repository contains packaging for both Debian-family (deb) and RHEL-family (rpm) distributions.

## Quick start

On the target build host:

    make pkg

Artifacts will be placed into `dist/`.

Package type is detected automatically via `/etc/os-release`:

* Debian/Ubuntu → `*.deb`
* RHEL/Alma/Rocky/CentOS/Fedora → `*.rpm`

## Installing build dependencies (recommended)

### Debian 12 / Ubuntu 22.04

Uses `mk-build-deps` to install `Build-Depends` from `debian/control`:

    sudo apt-get update
    sudo apt-get install -y devscripts equivs
    sudo mk-build-deps -i -t "apt-get -y" -r debian/control
    rm -f release-test-build-deps_*.deb

Or simply:

    make deps

### RHEL 9/10 / AlmaLinux 9/10

Uses `dnf builddep` to install `BuildRequires` from the rpm spec:

    sudo dnf -y install dnf-plugins-core
    sudo dnf -y builddep packaging/rpm/release-test.spec

Or simply:

    make deps

## Versioning

* If the current commit has a git tag, that tag (without a leading `v`) is used as the package version.
* If the current commit is not tagged, `VERSION` from the Makefile is used.
* `RELEASE` is used as Debian revision / RPM release.

Examples:

    make pkg VERSION=1.2.3 RELEASE=2
