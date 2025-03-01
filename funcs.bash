# bash functions that help script robustness
function cd {
	# this guards against:
	# 1) user definitions of cd that may print stuff, etc.
	# 2) paths not starting in / that match in user's CDPATH
	local target="$1"
	if [ -n "${target##/*}" ]; then
		# add ./ if path does not start with /
		target="./$target"
	fi
	# use builtin to avoid user-overloaded cd
	builtin cd "$target"
}
function pwd {
	# this guards against user definitons of pwd that act differently
	builtin pwd
}
