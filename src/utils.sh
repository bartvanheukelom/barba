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
    cd "$(dirname "$0")"
}

# prints the name of the main script
scriptname() {
	echo "$(basename "$0")"
}

log() {
	echo "[$(scriptname)] $@"
}

check_args() {
	local check=$1
	local usage=$2
    [[ "$check" != "" ]] || error "usage: $(scriptname) $usage"
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
