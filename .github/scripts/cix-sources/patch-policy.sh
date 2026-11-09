#!/usr/bin/env bash
# Gentoo genpatches follow kernel-2 unipatch's normal dry-run/depth search.
# Do not impose the overlay's zero-fuzz/offset qualification on inherited input.
apply_gentoo_patch_file() {
    local file=$1 depth=0
    local diagnostic
    diagnostic=$(mktemp "${T:-${TMPDIR:-/tmp}}/genpatches.XXXXXX") || return
    while ((depth < 5)); do
        printf 'Gentoo dry-run (-p%s):\n' "$depth" >> "$diagnostic"
        if LC_ALL=C patch -p"$depth" --no-backup-if-mismatch --dry-run -f < "$file" >> "$diagnostic" 2>&1; then
            cat "$diagnostic"
            rm -f "$diagnostic"
            LC_ALL=C patch -p"$depth" --no-backup-if-mismatch -f < "$file"
            return
        fi
        depth=$((depth + 1))
    done
    cat "$diagnostic" >&2
    rm -f "$diagnostic"
    return 1
}

# Reject positional drift before mutation; verify the applied hunks afterward.
# This policy is deliberately unavailable to Gentoo or vendor callers.
maintained_patch_check() {
    local file=$1 direction=$2 diagnostic status=0
    diagnostic=$(mktemp "${T:-${TMPDIR:-/tmp}}/maintained.XXXXXX") || return
    LC_ALL=C patch --batch "$direction" --fuzz=0 --no-backup-if-mismatch -p1 --dry-run -i "$file" > "$diagnostic" 2>&1 || status=$?
    cat "$diagnostic"
    if LC_ALL=C grep -Eq 'offset [-+]?[0-9]+ lines?|with fuzz [0-9]+' "$diagnostic"; then
        status=1
    fi
    rm -f "$diagnostic"
    return "$status"
}
apply_maintained_patch_file() {
    maintained_patch_check "$1" --forward || return
    LC_ALL=C patch --batch --forward --fuzz=0 --no-backup-if-mismatch -p1 -i "$1" || return
    maintained_patch_check "$1" --reverse
}
