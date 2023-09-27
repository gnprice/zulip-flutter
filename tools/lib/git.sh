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

no_untracked_files()
{
    if git ls-files --others --exclude-standard -- "$@" \
            | grep -q .; then
        return 1
    fi
}

git_status_short()
{
    # --untracked-files=normal is the default; but the user's local config
    # may have overridden it, so we specify explicitly.
    git status --short --untracked-files=normal -- "$@"
}
