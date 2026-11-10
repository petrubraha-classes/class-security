#!/bin/bash
#
# Shared helper functions for the lab06 exercises.
# Source this file from a script, for example:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/common.sh"
#
# These are the generic helpers common to all exercises. Exercise-specific
# settings and functions (create_group, create_user, cleanup, tests, ...)
# stay in their own scripts.

# ---------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------

# Print a visible section title.
print_title() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
}

# Make sure the script is running as root.
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: run this script as root, for example: sudo $0"
        exit 1
    fi
}

# Run a command as another user. "runuser" starts a new process that
# belongs to that user, with that user's current groups from /etc/group.
#   $1 = user name, the rest = the command and its arguments
run_as_user() {
    local user_name="$1"
    shift
    runuser -u "$user_name" -- "$@"
}
