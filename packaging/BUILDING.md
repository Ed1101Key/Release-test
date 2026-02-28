# Building packages

This repository contains packaging for both Debian-family (deb) and RHEL-family (rpm) distributions.

## Quick start

On the target build host, run:

```bash
make pkg
```

The resulting artifacts are placed into `dist/`.

Package type is detected automatically via `/etc/os-release`:

* Debian/Ubuntu → `*.deb`
* RHEL/Alma/Rocky/CentOS/Fedora → `*.rpm`

## Dependencies

### Debian 12 / Ubuntu 22.04

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  debhelper \
  dpkg-dev \
  libfmt-dev
```

### RHEL 9/10 / AlmaLinux 9/10

```bash
sudo dnf install -y \
  rpm-build \
  gcc-c++ \
  make \
  fmt-devel \
  systemd-rpm-macros
```

## Versioning

* If the current commit has a git tag, that tag (without a leading `v`) is used as the package version.
* If the current commit is not tagged, `VERSION` from the Makefile is used.

You can override the fallback version:

```bash
make pkg VERSION=1.2.3
```
