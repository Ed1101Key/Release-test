#!/usr/bin/env bash
set -euo pipefail

name="${1:?package name required}"
version="${2:?package version required}"

debver="${version}-1"
date_rfc2822="$(LC_ALL=C date -R)"

cat <<EOF
${name} (${debver}) unstable; urgency=medium

  * Automated build.

 -- Eduard Basov <ebasov@ispmanager.ru>  ${date_rfc2822}
EOF
