#!/bin/bash
#
# Tests for ex01.sh (collaboration mode via setgid + group write).

test_collaboration() {
    print_title "Test the collaboration mode"

    # Alice logs in, goes to the shared directory, creates her file
    echo "--- Alice: cd $SHARED_DIR, create Alice-file.txt, grant group rw"
    run_as_user "$USER_ALICE" bash -c "
        cd $SHARED_DIR
        echo 'Created by Alice.' > Alice-file.txt
        chmod g+rw Alice-file.txt
    "

    # Bob logs in, goes to the shared directory, creates his file
    echo "--- Bob: cd $SHARED_DIR, create Bob-file.txt, grant group rw"
    run_as_user "$USER_BOB" bash -c "
        cd $SHARED_DIR
        echo 'Created by Bob.' > Bob-file.txt
        chmod g+rw Bob-file.txt
    "

    echo
    echo "Files now in $SHARED_DIR (the group must be $GROUP_NAME for both):"
    ls -l "$SHARED_DIR"

    # Bob reads and modifies Alice's file
    echo
    echo "--- Bob modifies Alice's file (appends a line) and reads it back"
    run_as_user "$USER_BOB" bash -c "
        echo 'Line appended by Bob.' >> $SHARED_DIR/Alice-file.txt
        cat $SHARED_DIR/Alice-file.txt
    "

    # Alice reads and modifies Bob's file
    echo
    echo "--- Alice modifies Bob's file (appends a line) and reads it back"
    run_as_user "$USER_ALICE" bash -c "
        echo 'Line appended by Alice.' >> $SHARED_DIR/Bob-file.txt
        cat $SHARED_DIR/Bob-file.txt
    "

    echo
    echo "RESULT: both users could read and modify the other user's file."
}
