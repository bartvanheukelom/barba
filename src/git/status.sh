import utils

# git.list_repos
#     if the working dir is a git repo, prints its absolute path and that of all submodules, recursively
git.list_repos() {
    [[ -r ".git" ]] || error "not a git repo: $(pwd)" || return

    pwd
    git submodule foreach --recursive --quiet 'echo "$toplevel/$path"'
}

# git.status_if_dirty $repo
#     prints the status of $repo only if it's not clean
git.status_if_dirty() {
    (
        set_strict_mode
        local path="$1"
        cd "$path"
        short=$(git status --short)
        if [[ "$short" != "" ]]; then
            echo "######################### $path ############################"
            git status
            echo
            echo
            echo
        fi

        # TODO alert detached HEAD
    )
}