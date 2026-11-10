#!/bin/bash
#
# Usage:
# - chmod +x ex02.sh
# - sudo ./ex02.sh            -> creates everything and runs the tests
# - sudo ./ex02.sh cleanup    -> removes everything this script created
#
# Can Alice access and modify the file created by Bob (and the other way around)?
# Yes.

# Resolve this script's own directory so sourcing works from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------
GROUP_NAME="IS-Lab"
SHARED_DIR="/home/IS-Lab"
USER_ALICE="alice"
USER_BOB="bob"

# Lab-only passwords, so you can also log in as these users by hand
# (for example: su - alice). Do not reuse these on a real system.
PASSWORD_ALICE="Alice-Lab-123"
PASSWORD_BOB="Bob-Lab-123"

# ---------------------------------------------------------------------
# Shared helpers and tests
# ---------------------------------------------------------------------
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/tests/ex01_tests.sh"

# ---------------------------------------------------------------------
# Exercise-specific functions
# ---------------------------------------------------------------------

cleanup() {
    print_title "Cleanup: removing users, group and shared directory"

    if [ -d "$SHARED_DIR" ]; then
        rm -rf "$SHARED_DIR"
        echo "Removed directory $SHARED_DIR"
    fi

    # userdel -r also removes the home directory and the mail spool.
    if id "$USER_ALICE" > /dev/null 2>&1; then
        userdel -r "$USER_ALICE"
        echo "Removed user $USER_ALICE"
    fi
    if id "$USER_BOB" > /dev/null 2>&1; then
        userdel -r "$USER_BOB"
        echo "Removed user $USER_BOB"
    fi

    if getent group "$GROUP_NAME" > /dev/null 2>&1; then
        groupdel "$GROUP_NAME"
        echo "Removed group $GROUP_NAME"
    fi

    echo "Cleanup finished."
}

create_group() {
    print_title "Step 1: create the group $GROUP_NAME"

    if getent group "$GROUP_NAME" > /dev/null 2>&1; then
        echo "Group $GROUP_NAME already exists, nothing to do."
    else
        groupadd "$GROUP_NAME"
        echo "Group $GROUP_NAME created."
    fi
}

create_user() {
    local user_name="$1"
    local user_password="$2"

    if id "$user_name" > /dev/null 2>&1; then
        echo "User $user_name already exists, only adding it to $GROUP_NAME."
        # -a = append (keep the other groups), -G = supplementary group list
        usermod -a -G "$GROUP_NAME" "$user_name"
    else
        # -m = create the home directory /home/<user>
        # -s = login shell
        # -G = supplementary group(s) the user belongs to
        useradd -m -s /bin/bash -G "$GROUP_NAME" "$user_name"
        echo "User $user_name created and added to $GROUP_NAME."
    fi

    # chpasswd reads lines of the form "user:password" from standard input.
    echo "$user_name:$user_password" | chpasswd
}

create_users() {
    print_title "Step 2: create users $USER_ALICE and $USER_BOB (members of $GROUP_NAME)"

    create_user "$USER_ALICE" "$PASSWORD_ALICE"
    create_user "$USER_BOB" "$PASSWORD_BOB"

    echo
    echo "Group membership:"
    id "$USER_ALICE"
    id "$USER_BOB"
    echo "Members listed in /etc/group:"
    getent group "$GROUP_NAME"
}

create_shared_directory() {
    print_title "Step 3: create $SHARED_DIR with group $GROUP_NAME, setgid and group write"

    # Create the directory (no error if it already exists).
    mkdir -p "$SHARED_DIR"

    # Set the group owner of the directory to IS-Lab.
    chgrp "$GROUP_NAME" "$SHARED_DIR"

    # Mode 2770, digit by digit:
    #   2 = setgid bit  -> new files inherit the directory's group
    #   7 = owner (root): read, write, execute
    #   7 = group (IS-Lab): read, write, execute   <- includes w, as required
    #   0 = others: no access
    chmod 2770 "$SHARED_DIR"

    echo "Result:"
    ls -ld "$SHARED_DIR"
    echo "(drwxrws--- means: group IS-Lab can read/write/enter, 's' = setgid is active)"
}

# ---------------------------------------------------------------------
# Main program
# ---------------------------------------------------------------------
set -e # stop the script if any command fails (tests handle expected failures explicitly)
require_root

if [ "${1:-}" = "cleanup" ]; then
    cleanup
    exit 0
fi

create_group
create_users
create_shared_directory
test_collaboration

print_title "Done"
echo "To try it by hand:  su - $USER_ALICE   (password: $PASSWORD_ALICE)"
echo "To remove it all:   sudo ./ex02.sh cleanup"
