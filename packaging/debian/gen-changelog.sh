#!/bin/sh
set -e

name="${1:?package name required}"
debver="${2:?package version required}"
date_rfc2822="$(LC_ALL=C date '+%a, %d %b %Y %H:%M:%S %z')"

cat <<EOF
${name} (${debver}) unstable; urgency=medium

  * Automated build.

 -- Eduard Basov <ebasov@ispmanager.ru>  ${date_rfc2822}

EOF
