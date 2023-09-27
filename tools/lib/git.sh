# shellcheck shell=bash
#
# Shell functions for use with Git.

no_uncommitted_changes()
{
    if ! git diff-index --quiet --cached HEAD -- "$@"; then
        # Index differs from HEAD.
        return 1
    fi
    if ! git diff-files --quiet -- "$@"; then
        # Worktree differs from index.
        return 1
    fi
}

check_no_uncommitted_changes()
{
    if ! no_uncommitted_changes "$@"; then
        qualifier=
        if (( $# )); then
            qualifier=" in $*"
        fi
        echo >&2 "There are uncommitted changes${qualifier}.  Doing nothing, to avoid losing your work."
        return 1
    fi
}
