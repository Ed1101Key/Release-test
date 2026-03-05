SHELL := /bin/sh

NAME := release-test

# Fallback version when current commit has no git tag
VERSION ?= 1.0

# Package revision:
#   - Debian:  <version>-<release>
#   - RPM:     Release: <release>%{?dist}
RELEASE ?= 1

BUILD_DIR := build
DIST_DIR  := dist

# These flags are used by packaging rules (debian/rules and rpm spec).
CXXFLAGS ?= -O2 -std=c++17 -Wall -Wextra -Werror -Wno-unused-parameter
LDLIBS   ?= -lfmt

RPM_TOPDIR := $(abspath $(BUILD_DIR)/rpmbuild)
RPM_SPEC   := packaging/rpm/$(NAME).spec

GIT_TAG := $(shell git describe --tags --exact-match 2>/dev/null)
PKG_VERSION := $(if $(GIT_TAG),$(patsubst v%,%,$(GIT_TAG)),$(VERSION))
PKG_RELEASE := $(RELEASE)

DEB_VERSION := $(PKG_VERSION)-$(PKG_RELEASE)

OS_ID   := $(shell . /etc/os-release 2>/dev/null; echo $$ID)
OS_LIKE := $(shell . /etc/os-release 2>/dev/null; echo $$ID_LIKE)

DEB_IDS := debian ubuntu
RPM_IDS := rhel fedora centos almalinux rocky

ifneq ($(filter $(DEB_IDS),$(OS_ID) $(OS_LIKE)),)
PKG_TYPE := deb
else ifneq ($(filter $(RPM_IDS),$(OS_ID) $(OS_LIKE)),)
PKG_TYPE := rpm
endif

.PHONY: help clean pkg deps pkg-deb pkg-rpm deps-deb deps-rpm

help:
	@echo "Targets:"
	@echo "  make pkg                Build a package for current OS (deb or rpm), output in $(DIST_DIR)/"
	@echo "  make deps               Install build dependencies using distro tools (mk-build-deps / dnf builddep)"
	@echo "  make clean              Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  VERSION=<x.y.z>         Fallback version when current commit has no tag"
	@echo "  RELEASE=<n>             Debian revision / RPM release (default: 1)"
	@echo "  PKG_TYPE=deb|rpm        Override auto-detection"

clean:
	rm -rf "$(BUILD_DIR)" "$(DIST_DIR)" ./*.deb ./*.rpm

$(DIST_DIR):
	mkdir -p "$(DIST_DIR)"

pkg: $(DIST_DIR) pkg-$(PKG_TYPE)

deps: deps-$(PKG_TYPE)

# ---- Debian/Ubuntu -----------------------------------------------------------

pkg-deb:
	@mkdir -p "$(BUILD_DIR)"
	@cp -f debian/changelog "$(BUILD_DIR)/.changelog.bak" 2>/dev/null || true
	@sh packaging/debian/gen-changelog.sh "$(NAME)" "$(DEB_VERSION)" > debian/changelog
	@CXXFLAGS="$(CXXFLAGS)" LDLIBS="$(LDLIBS)" dpkg-buildpackage -us -uc -b
	@mv -f "$(BUILD_DIR)/.changelog.bak" debian/changelog 2>/dev/null || true
	@cp -v ../$(NAME)_*.deb "$(DIST_DIR)/"
	@# dbgsym may or may not be built, copy if present
	@if ls ../$(NAME)-dbgsym_*.ddeb >/dev/null 2>&1; then cp -v ../$(NAME)-dbgsym_*.ddeb "$(DIST_DIR)/"; fi

deps-deb:
	@sudo apt-get update
	@sudo apt-get install -y devscripts equivs
	@sudo mk-build-deps -i -t "apt-get -y" -r debian/control
	@rm -f $(NAME)-build-deps_*.deb 2>/dev/null || true

# ---- RHEL/Alma/Rocky/Fedora -------------------------------------------------

pkg-rpm:
	rm -rf "$(RPM_TOPDIR)"
	mkdir -p "$(RPM_TOPDIR)/BUILD" "$(RPM_TOPDIR)/RPMS" "$(RPM_TOPDIR)/SOURCES" "$(RPM_TOPDIR)/SPECS" "$(RPM_TOPDIR)/SRPMS"
	git archive --format=tar.gz --prefix="$(NAME)-$(PKG_VERSION)/" -o "$(RPM_TOPDIR)/SOURCES/$(NAME)-$(PKG_VERSION).tar.gz" HEAD
	rpmbuild \
		--define "_topdir $(RPM_TOPDIR)" \
		--define "ver $(PKG_VERSION)" \
		--define "rel $(PKG_RELEASE)" \
		--define "cxxflags $(CXXFLAGS) -g" \
		--define "ldlibs $(LDLIBS)" \
		-ba "$(RPM_SPEC)"
	find "$(RPM_TOPDIR)/RPMS" -type f -name "*.rpm" -exec cp -v {} "$(DIST_DIR)/" \;

deps-rpm:
	@sudo dnf -y install dnf-plugins-core
	@sudo dnf -y builddep "$(RPM_SPEC)"
