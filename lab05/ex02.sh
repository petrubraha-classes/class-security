#!/bin/bash
#
# Usage:
# - chmod +x ex02.sh
# - sudo ./ex02.sh            -> creates everything and runs the tests
# - sudo ./ex02.sh cleanup    -> removes everything this script created
#
# Can Alice access and modify the file created by Bob (and the other way around)?
# Yes.

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
# Helper functions
# ---------------------------------------------------------------------

# Print a visible section title.
print_title() {
    echo
    echo "=============================================================="
    echo "$1"
    echo "=============================================================="
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: run this script as root, for example: sudo ./ex02.sh"
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

test_collaboration() {
    print_title "Step 4: test the collaboration mode"

    # --- 4a. Alice logs in, goes to the shared directory, creates her file
    echo "--- Alice: cd $SHARED_DIR, create Alice-file.txt, grant group rw"
    run_as_user "$USER_ALICE" bash -c "
        cd $SHARED_DIR
        echo 'Created by Alice.' > Alice-file.txt
        chmod g+rw Alice-file.txt
    "

    # --- 4b. Bob logs in, goes to the shared directory, creates his file
    echo "--- Bob: cd $SHARED_DIR, create Bob-file.txt, grant group rw"
    run_as_user "$USER_BOB" bash -c "
        cd $SHARED_DIR
        echo 'Created by Bob.' > Bob-file.txt
        chmod g+rw Bob-file.txt
    "

    echo
    echo "Files now in $SHARED_DIR (the group must be $GROUP_NAME for both):"
    ls -l "$SHARED_DIR"

    # --- 4c. Bob reads and modifies Alice's file
    echo
    echo "--- Bob modifies Alice's file (appends a line) and reads it back"
    run_as_user "$USER_BOB" bash -c "
        echo 'Line appended by Bob.' >> $SHARED_DIR/Alice-file.txt
        cat $SHARED_DIR/Alice-file.txt
    "

    # --- 4d. Alice reads and modifies Bob's file
    echo
    echo "--- Alice modifies Bob's file (appends a line) and reads it back"
    run_as_user "$USER_ALICE" bash -c "
        echo 'Line appended by Alice.' >> $SHARED_DIR/Bob-file.txt
        cat $SHARED_DIR/Bob-file.txt
    "

    echo
    echo "RESULT: both users could read and modify the other user's file."
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
