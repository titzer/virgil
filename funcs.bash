# bash functions that help script robustness
function cd {
    # this guards against:
    # 1) user definitions of cd that may print stuff, etc.
    # 2) paths not starting in / that match in user's CDPATH
    if [ x-P = "x$1" ]; then poption="-P"; shift; fi
    local target="$1"
    if [ -n "${target##/*}" ]; then
	# add ./ if path does not start with /
	target="./$target"
    fi
    # use builtin to avoid user-overloaded cd
    builtin cd $poption "$target"
}
function pwd {
    # this guards against user definitons of pwd that act differently
    builtin pwd
}
function pushd {
    builtin pushd $*
}
function popd {
    builtin popd
}
function follow_links {
    local PLACE="$1"
    while [ -h "$PLACE" ]; do
	DIR="$(cd -P "$(command dirname "$PLACE")" && pwd)"
        PLACE="$(command readlink "$PLACE")"
	[[ "$PLACE" != /* ]] && PLACE="$DIR/$PLACE"
    done
    DIR="$(cd -P "$(command dirname "$PLACE")" && pwd)"
}
