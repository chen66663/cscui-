#!/usr/bin/env bash
# Compatibility wrapper. New automation should call New-CscuiProject.sh.
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
printf '[DEPRECATED] Use New-CscuiProject.sh for new projects.\n' >&2
exec "$SCRIPT_DIR/New-CscuiProject.sh" "$@"
