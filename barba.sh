# source this file to enable importing of modules, e.g.:
#
#     #!/bin/bash
#     source "$(dirname "$0")/barba/barba.sh"

barba_root="$(dirname "$BASH_SOURCE")"
barba_root="$(cd "$barba_root" && pwd)"
barba_src="$barba_root/src"
if ${barba_debug_imports:-false}; then
    echo "barba_src=$barba_src"
fi

import() {
    local module
    for module in "$@"; do
        import_module "$module"
    done
}

import_module() {
    # give these local vars unique names because they will be visible
    # in the sourced module file
    local _bim_module="$1"
    local _bim_guardvar="_barba_imported_${_bim_module//./__}"
    local _bim_filename="${_bim_module//.//}.sh"
    
    if ${barba_debug_imports:-false}; then
        echo "import_module $_bim_module; guardvar=$_bim_guardvar filename=$_bim_filename $_bim_guardvar=${!_bim_guardvar:-''}"
    fi
    
    if ! declare -p "$_bim_guardvar" > /dev/null 2>&1; then
        source "$barba_src/$_bim_filename"
        # TODO can be done without eval?
        eval "$_bim_guardvar=true"
    elif ${barba_debug_imports:-false}; then
        echo "import_module $_bim_module; already imported"
    fi
}
