import utils

# git.list_repos
#     if the working dir is a git repo, prints its absolute path and that of all submodules, recursively
git.list_repos() {
    [[ -r ".git" ]] || error "not a git repo: $(pwd)" || return

    pwd
    git submodule foreach --recursive --quiet 'echo "$toplevel/$path"'
}

# prints the status of the current git repo only if it's not clean
git.status_if_dirty() {
    if git.dirty || git.detached; then
        echo "######################### $(pwd) ############################"
        
        if git.dirty; then
            # this also prints detached HEAD if applicable
            git status || return
        elif git.detached; then
            echo "detached HEAD @ $(git.current_commit --short), could be attached to:"
            git.current_refs | git.local_branch_refs | prefix '  - ' || return
        fi

        echo
        echo
    fi
}

git.dirty() {
    short=$(git status --short)
    [[ "$short" != "" ]]
}

git.current_branch() {
    local branch
    branch="$(git symbolic-ref HEAD 2>/dev/null)" || branch_name="(detached HEAD)"
    branch=${branch#"refs/heads/"}
}

git.detached() {
    ! git symbolic-ref HEAD &>/dev/null
}

git.current_commit() {
    git rev-parse "$@" HEAD || fun_error
}

git.current_refs() {
    git show-ref | { grep "$(git.current_commit)" || true; } | cut -d' ' -f2 || fun_error
}

git.local_branch_refs() {
    local branch
    while IFS= read -r ref; do
        branch=${ref#"refs/heads/"}
        if [[ "$branch" != "$ref" ]]; then
            echo "$branch"
        fi
    done
}
