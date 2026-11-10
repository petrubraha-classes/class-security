#!/bin/bash
#
# Usage (run ex02.sh first, it creates alice, bob and /home/IS-Lab):
# - chmod +x ex03.sh
# - sudo ./ex03.sh            -> creates everything and runs the tests
# - sudo ./ex03.sh cleanup    -> removes everything this script created
#
# Can Carl access and modify the files created by Alice and Bob?
# Yes, through POSIX ACLs: IS-Instructor gets rwx on the directory, Carl NOT being a member of IS-Lab.

# ---------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------
GROUP_STUDENTS="IS-Lab"
GROUP_INSTRUCTORS="IS-Instructor"
SHARED_DIR="/home/IS-Lab"
USER_CARL="carl"

# Lab-only password, so you can also log in as carl by hand
# (for example: su - carl). Do not reuse it on a real system.
PASSWORD_CARL="Carl-Lab-123"

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
        echo "ERROR: run this script as root, for example: sudo ./ex03.sh"
        exit 1
    fi
}

# The shared directory is created by ex02.sh, so it must exist already.
require_shared_directory() {
    if [ ! -d "$SHARED_DIR" ]; then
        echo "ERROR: $SHARED_DIR does not exist. Run sudo ./ex02.sh first."
        exit 1
    fi
}

# setfacl and getfacl come from the package "acl".
require_acl_tools() {
    if ! command -v setfacl > /dev/null 2>&1; then
        echo "setfacl not found, installing the package acl."
        apt-get install -y acl
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
    print_title "Cleanup: removing carl, group $GROUP_INSTRUCTORS and its ACL entries"

    # Remove the ACL entries of the instructors from the directory and from
    # the files inside it (-R = recursive, -x = remove the given entry).
    if [ -d "$SHARED_DIR" ]; then
        setfacl -R -x "g:$GROUP_INSTRUCTORS" "$SHARED_DIR" 2> /dev/null || true
        # -d = the default ACL (the one inherited by new files)
        setfacl -d -x "g:$GROUP_INSTRUCTORS" "$SHARED_DIR" 2> /dev/null || true
        echo "Removed the ACL entries of $GROUP_INSTRUCTORS from $SHARED_DIR"
    fi

    # userdel -r also removes the home directory and the mail spool.
    if id "$USER_CARL" > /dev/null 2>&1; then
        userdel -r "$USER_CARL"
        echo "Removed user $USER_CARL"
    fi

    if getent group "$GROUP_INSTRUCTORS" > /dev/null 2>&1; then
        groupdel "$GROUP_INSTRUCTORS"
        echo "Removed group $GROUP_INSTRUCTORS"
    fi

    echo "Cleanup finished."
}

create_group() {
    print_title "Step 1: create the group $GROUP_INSTRUCTORS"

    if getent group "$GROUP_INSTRUCTORS" > /dev/null 2>&1; then
        echo "Group $GROUP_INSTRUCTORS already exists, nothing to do."
    else
        groupadd "$GROUP_INSTRUCTORS"
        echo "Group $GROUP_INSTRUCTORS created."
    fi
}

create_user() {
    print_title "Step 2: create user $USER_CARL (member of $GROUP_INSTRUCTORS only)"

    if id "$USER_CARL" > /dev/null 2>&1; then
        echo "User $USER_CARL already exists, only adding it to $GROUP_INSTRUCTORS."
        # -a = append (keep the other groups), -G = supplementary group list
        usermod -a -G "$GROUP_INSTRUCTORS" "$USER_CARL"
    else
        # -m = create the home directory /home/<user>
        # -s = login shell
        # -G = supplementary group(s): only IS-Instructor, NOT IS-Lab
        useradd -m -s /bin/bash -G "$GROUP_INSTRUCTORS" "$USER_CARL"
        echo "User $USER_CARL created and added to $GROUP_INSTRUCTORS."
    fi

    # chpasswd reads lines of the form "user:password" from standard input.
    echo "$USER_CARL:$PASSWORD_CARL" | chpasswd

    echo
    echo "Group membership of $USER_CARL:"
    id "$USER_CARL"

    # Check the requirement: carl must not be a member of IS-Lab.
    if id -nG "$USER_CARL" | tr ' ' '\n' | grep -qx "$GROUP_STUDENTS"; then
        echo "ERROR: $USER_CARL is a member of $GROUP_STUDENTS, but must not be."
        exit 1
    fi
    echo "OK: $USER_CARL is not a member of $GROUP_STUDENTS."
}

set_acl_permissions() {
    print_title "Step 3: grant $GROUP_INSTRUCTORS access to $SHARED_DIR with ACLs"

    # The plain permissions (owner, group, others) have only ONE group slot,
    # and it is already used by IS-Lab. An ACL adds a named group entry
    # without touching the IS-Lab group or its members.

    # 1) Entry for the directory and for the files that already exist.
    #    -R = recursive, -m = modify (add) an entry
    #    g:IS-Instructor:rwX = group IS-Instructor gets read and write; the
    #    capital X gives execute only on directories (needed for cd), not on
    #    plain files.
    setfacl -R -m "g:$GROUP_INSTRUCTORS:rwX" "$SHARED_DIR"

    # 2) Default entry, inherited by the files and directories created in the
    #    future by Alice and Bob. -d = default ACL (applies to the directory).
    setfacl -d -m "g:$GROUP_INSTRUCTORS:rwx" "$SHARED_DIR"

    echo "Result:"
    getfacl "$SHARED_DIR"
}

test_instructor_access() {
    print_title "Step 4: test the access of $USER_CARL"

    # The files of Alice and Bob must exist (created by ex02.sh).
    # If they are missing (for example after a manual cleanup), create them.
    if [ ! -f "$SHARED_DIR/Alice-file.txt" ]; then
        run_as_user alice bash -c "
            cd $SHARED_DIR
            echo 'Created by Alice.' > Alice-file.txt
            chmod g+rw Alice-file.txt
        "
    fi
    if [ ! -f "$SHARED_DIR/Bob-file.txt" ]; then
        run_as_user bob bash -c "
            cd $SHARED_DIR
            echo 'Created by Bob.' > Bob-file.txt
            chmod g+rw Bob-file.txt
        "
    fi

    # --- 4a. Carl goes to the shared directory and lists it
    echo "--- Carl: cd $SHARED_DIR and list the files"
    run_as_user "$USER_CARL" bash -c "
        cd $SHARED_DIR
        pwd
        ls -l
    "

    # --- 4b. Carl modifies Alice's file
    echo
    echo "--- Carl modifies Alice's file (appends a line) and reads it back"
    run_as_user "$USER_CARL" bash -c "
        echo 'Correction added by Carl.' >> $SHARED_DIR/Alice-file.txt
        cat $SHARED_DIR/Alice-file.txt
    "

    # --- 4c. Carl modifies Bob's file
    echo
    echo "--- Carl modifies Bob's file (appends a line) and reads it back"
    run_as_user "$USER_CARL" bash -c "
        echo 'Correction added by Carl.' >> $SHARED_DIR/Bob-file.txt
        cat $SHARED_DIR/Bob-file.txt
    "

    # --- 4d. A file created AFTER the ACL was set must also be accessible
    #         (this proves the default ACL works).
    echo
    echo "--- Alice creates a NEW file; Carl must be able to modify it"
    run_as_user alice bash -c "
        cd $SHARED_DIR
        echo 'New file by Alice.' > Alice-new-file.txt
    "
    run_as_user "$USER_CARL" bash -c "
        echo 'Correction added by Carl.' >> $SHARED_DIR/Alice-new-file.txt
        cat $SHARED_DIR/Alice-new-file.txt
    "

    echo
    echo "RESULT: carl could access and modify the files created by Alice and Bob."
}

# ---------------------------------------------------------------------
# Main program
# ---------------------------------------------------------------------
set -e # stop the script if any command fails
require_root

if [ "${1:-}" = "cleanup" ]; then
    cleanup
    exit 0
fi

require_shared_directory
require_acl_tools
create_group
create_user
set_acl_permissions
test_instructor_access

print_title "Done"
echo "To try it by hand:  su - $USER_CARL   (password: $PASSWORD_CARL)"
echo "To remove it all:   sudo ./ex03.sh cleanup"
