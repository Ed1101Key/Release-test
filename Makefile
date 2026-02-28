SHELL := /bin/bash

NAME := release-test

VERSION ?= 1.0

PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin

BUILD_DIR := build
DIST_DIR := dist

CXX ?= g++
CXXFLAGS ?= -O2 -std=c++17 -Wall -Wextra -Werror -Wno-unused-parameter
LDFLAGS ?=
LDLIBS ?= -lfmt

.PHONY: help clean pkg pkg-deb pkg-rpm

help:
	@echo "Targets:"
	@echo "  make pkg    Build a deb or rpm package (auto-detected), output in $(DIST_DIR)/"
	@echo "  make clean  Remove build and dist artifacts"

clean:
	rm -rf "$(BUILD_DIR)" "$(DIST_DIR)" ./*.deb ./*.rpm

GIT_TAG := $(shell git describe --tags --exact-match 2>/dev/null || true)
PKG_VERSION := $(if $(GIT_TAG),$(patsubst v%,%,$(GIT_TAG)),$(VERSION))

OS_ID := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo unknown)
OS_LIKE := $(shell . /etc/os-release 2>/dev/null && echo $$ID_LIKE || echo)

PKG_TYPE ?= $(shell \
	if echo "$(OS_ID) $(OS_LIKE)" | grep -Eqi '(debian|ubuntu)'; then echo deb; \
	elif echo "$(OS_ID) $(OS_LIKE)" | grep -Eqi '(rhel|fedora|centos|alma|rocky)'; then echo rpm; \
	else echo deb; fi)

pkg:
	@mkdir -p "$(DIST_DIR)"
	@echo "Building $(PKG_TYPE) package, version=$(PKG_VERSION)"
	@if [ "$(PKG_TYPE)" = "deb" ]; then \
		$(MAKE) pkg-deb; \
	elif [ "$(PKG_TYPE)" = "rpm" ]; then \
		$(MAKE) pkg-rpm; \
	else \
		echo "Unknown PKG_TYPE=$(PKG_TYPE)" >&2; exit 2; \
	fi

pkg-deb:
	@set -euo pipefail; \
	name="$(NAME)"; ver="$(PKG_VERSION)"; \
	work="$(BUILD_DIR)/deb/$${name}-$${ver}"; \
	rm -rf "$${work}"; mkdir -p "$${work}"; \
	tar --exclude='./$(BUILD_DIR)' --exclude='./$(DIST_DIR)' -cf - . | (cd "$${work}" && tar -xf -); \
	bash ./packaging/debian/gen-changelog.sh "$${name}" "$${ver}" > "$${work}/debian/changelog"; \
	(cd "$${work}" && dpkg-buildpackage -us -uc -b); \
	find "$(BUILD_DIR)/deb" -maxdepth 1 -type f -name "*.deb" -exec cp -v {} "$(DIST_DIR)/" \;

pkg-rpm:
	@set -euo pipefail; \
	name="$(NAME)"; ver="$(PKG_VERSION)"; \
	root="$$(pwd)"; \
	topdir="$${root}/$(BUILD_DIR)/rpmbuild"; \
	rm -rf "$${topdir}"; \
	mkdir -p "$${topdir}/BUILD" "$${topdir}/RPMS" "$${topdir}/SOURCES" "$${topdir}/SPECS" "$${topdir}/SRPMS"; \
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
		git archive --format=tar.gz --prefix="$${name}-$${ver}/" -o "$${topdir}/SOURCES/$${name}-$${ver}.tar.gz" HEAD; \
	else \
		tar --exclude="./$(BUILD_DIR)" --exclude="./$(DIST_DIR)" --exclude="./.git" \
		    --transform="s,^[.]/,$${name}-$${ver}/," \
		    -czf "$${topdir}/SOURCES/$${name}-$${ver}.tar.gz" .; \
	fi; \
	sed -e "s/^Version:[[:space:]]*.*/Version:        $${ver}/" -e "s/@VERSION@/$${ver}/g" "packaging/rpm/$${name}.spec.in" > "$${topdir}/SPECS/$${name}.spec"; \
	rpmbuild --define "_topdir $${topdir}" -ba "$${topdir}/SPECS/$${name}.spec"; \
	mkdir -p "$(DIST_DIR)"; \
	find "$${topdir}/RPMS" -type f -name "*.rpm" -exec cp -v {} "$(DIST_DIR)/" \;
