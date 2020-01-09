# echo to stderr
echo2() {
    echo "$@" >&2
}

# error $msg [$code=$?]
#     Prints $msg and returns $code, which defaults to the previous return code, if that's an error, otherwise 1
error() {

    # save this before it's lost
    local incode="$?"
    
    local msg=${1:-"?"}
    local code=${2:-"$incode"}
    if [[ "$code" == "0" ]]; then code=1; fi
    
    echo2 "ERROR $code: $msg"
    return "$code"
}

fun_error() {
    local msg="${FUNCNAME[1]} $1"; shift
    error "$msg" "$@"
}

trace_error() {
    local msg="In ${FUNCNAME[1]} at [${BASH_SOURCE[1]}:${BASH_LINENO[0]}]: $1"; shift
    error "$msg" "$@"
}

# errexit $msg [$code=$?]
#     Prints $msg and exits with $code, which defaults to the previous return code, if that's an error, otherwise 1
errexit() {
    error "$1" || exit
}

# throw $code:
#     returns $code
throw() {
    return "$1"
}

debug() {
    # preserve the last return code
    local incode="$?"
    
    if "${DEBUG:-"false"}"; then
        echo2 -n "DEBUG: $1"
        if [[ "$incode" != "0" ]]; then
            echo2 -n " (also, exit code is $incode)"
        fi
        echo2
    fi

    return "$incode"
}

# try_source $file
#     sources $file if it exists, otherwise returns false
try_source() {
    local file="$1"
    [[ -f "$file" ]] && source "$file" || debug "skipping source $file"
}

script_entry() {
    # TODO save original entry dir
    set_strict_mode && cd_here
}

set_strict_mode() {
    set -o errexit \
        -o nounset \
        -o pipefail
}

unset_strict_mode() {
    set +o errexit \
        +o nounset \
        +o pipefail
}

# rc_setup $cmd [$args...]
# in an RC file, run $cmd in a mode that behaves much like a normal script
rc_setup() {
    rc_setup_enter
    local rc
    "$@" && rc=$? || rc=$?
    rc_setup_leave && return $rc
}

# in an RC file, enter a mode that behaves much like a normal script
rc_setup_enter() {
    
    # during setup, exit on errors
    set_strict_mode

    # it appears that if an rcfile is interrupted, normal bash behaviour
    # is to quit the rcfile but then present the prompt. we don't want that
    trap 'error Interrupted 130' SIGINT

}

# leave the mode entered by rc_setup_enter, to restore default interactive shell behaviour
rc_setup_leave() {
    trap - SIGINT
    unset_strict_mode
}

# cd to the directory of the main script
cd_here() {
    cd "$(scriptdir)"
}

# prints the directory containing the main script
scriptdir() {
    # TODO better
    echo "$(dirname "$0")"
}

# prints the name of the main script
scriptname() {
	echo "$(basename "$0")"
}

log() {
	echo "[$(scriptname)] $@"
}

# TODO remove, does not play well with set -u
check_args() {
	local check=$1
	local usage=$2
    [[ "$check" != "" ]] || usage_error "$usage"
}

check_usage() {
    local argcount="$1"
    shift
    (( $argcount == $# )) || usage_error "$@"
}

check_fun_args() {
    local argcount="$1"
    local funname="$2"
    shift 2
    (( $argcount == $# )) || args_error "$funname" "$@"
}

usage_error() {
    args_error "$(scriptname)" "$@"
}

args_error() {
    local callable="$1"
    shift
    error "usage: $callable $*" 1
}

# returns 1 if its stdin is empty
check_output() {
	local cmd=$1

	# forward input to output, while tracking it
	local has=false
	while read line; do
		echo $line
		if [[ "$line" != "" ]]; then
			has=true
		fi
	done

	$has || error "check_output: command '$cmd' produced no output"
}

is_date() {
	[[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

require_date() {
	is_date "$1" || error "'$1' is not a valid date"
}

# tmpfile_open
#     Opens a temporary file and assigns its name to the global variable 'tmpfile_name'.
#     The file exists in /dev/shm and is guaranteed to be deleted if this process dies.
#     Example usage:
#         tmpfile_open && my_temp="$tmpfile_name" || false
tmpfile_open() {
    local mktfn
    local fd
    mktfn=$(mktemp -p /dev/shm) &&
        file_test_rw "$mktfn" &&
        exec {fd}<>"$mktfn" &&
        rm "$mktfn" &&
        tmpfile_name="/proc/self/fd/$fd" &&
        file_test_rw "$tmpfile_name"
}

# file_test_rw $filename
#     checks if the file given by $filename is writable and readable.
#     OVERWRITES THE CONTENTS OF THE FILE!
file_test_rw() {
    local filename="$1"
    local str="file_test_rw $PPID"

    # write string to the file
    echo "$str" > "$filename" || error "file_test_rw $filename failed on write" || return
    
    # check if same string can be read back
    [[ "$(cat "$filename")" == "$str" ]] || error "file_test_rw $filename failed on read" || return
    
    # clear the test
    truncate --size=0 "$filename"
}

ensure_empty_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
    fi
    mkdir -p "$dir"
}

prefix() {
    local prefix="$1"
    local line
    while IFS= read -r line; do
        echo "${prefix}${line}"
    done
}
