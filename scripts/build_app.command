#!/bin/bash
set -Eeuo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/build_app.sh"
printf '\nPress Return to close...'
read -r _
