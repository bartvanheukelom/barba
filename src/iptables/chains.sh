import utils

# ensure all given chains are empty or nonexistent
iptables.flush_chains() {
    for chain in "$@"; do
        if iptables.chain_exists "$chain"; then
            iptables -F "$chain"
        fi
    done
}

# ensure all given chains exist
iptables.ensure_chains() {
    for chain in "$@"; do
        if ! iptables.chain_exists "$chain"; then
            iptables -N "$chain"
        fi
    done
}

# ensure all the given chains exist and are empty
iptables.ensure_empty_chains() {
    for chain in "$@"; do
        if iptables.chain_exists "$chain"; then
            iptables -F "$chain"
        else
            iptables -N "$chain"
        fi
    done
}

iptables.chain_exists() {
    local chain="$1"
    # numeric output, while ignored, speeds up the command
    iptables --numeric --list "$chain" > /dev/null 2>&1
}
