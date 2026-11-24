#!/bin/bash
#
# Shared helper functions for the lab06 exercises.

# ---------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------

print_title() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: run this script as root, for example: sudo $0"
        exit 1
    fi
}

require_shared_directory() {
    if [ ! -d "$SHARED_DIR" ]; then
        echo "ERROR: $SHARED_DIR does not exist. Create it first."
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
