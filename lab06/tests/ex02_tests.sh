#!/bin/bash
#
# Tests for ex02.sh (instructor access via POSIX ACLs).
#
# This file is meant to be sourced by ex02.sh, which defines the settings
# (SHARED_DIR, GROUP_INSTRUCTORS, USER_CARL, ...) and sources the shared
# helpers in lib/common.sh (print_title, run_as_user, ...). Do not run it
# directly.

test_instructor_access() {
    print_title "Step 4: test the access of $USER_CARL"

    # The files of Alice and Bob must exist (created by ex01.sh).
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
