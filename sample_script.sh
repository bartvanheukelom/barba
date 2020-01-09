#!/bin/bash
source "$(dirname "$0")/barba.sh" || exit 100  # UPDATE THIS PATH FOR YOUR OWN SCRIPT
import utils

main() {
    set_strict_mode

    check_usage $# a b
    local a="$1"
    local b="$2"

    local equality
    equality=$(print_equal "$a" "$b")

    echo "$(scriptname) called with $a and $b which are $equality"
}

print_equal() {
    check_fun_args $# print_equal left right || return
    local left="$1"
    local right="$2"
    if [[ "$left" == "$right" ]]; then
        echo "equal"
    else
        echo "not equal"
    fi
}

main "$@"
