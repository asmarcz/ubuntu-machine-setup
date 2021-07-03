alias s="du -h --max-depth=1 | sort -h"
alias ll="exa -lga"
alias lg="exa -lga --git"
alias bat="bat --theme=ansi-light"

rascii() {
	asciidoctor -b manpage -o - "$1" | man -l -
}

..() {
	local N PREVPWD
	N=1
	PREVPWD="$PWD"
	if [[ $# -eq 1 ]]; then
		N=$1
	fi
	for (( I = 0; I < $N; I++ )); do
		cd ..
	done
	OLDPWD="$PREVPWD"
}

srv() {
	local HOST PORT DOCROOT ROUTER ARG
	HOST="localhost"
	PORT="8000"
	DOCROOT="."
	ROUTER=""
	for ARG in "$@"; do
		if [[ "$ARG" = "-g" ]]; then
			HOST="0.0.0.0"
		elif [[ "$ARG" =~ ^[0-9]+$ ]]; then
			PORT="$ARG"
		elif [[ -d "$ARG" ]]; then
			DOCROOT="$ARG"
		elif [[ -f "$ARG" ]]; then
			ROUTER="$ARG"
		fi
	done
	php -S "$HOST":"$PORT" -t "$DOCROOT" $ROUTER
}

short_pwd() {
	local RE
	
	DIR="$(dirs)"
	RE="(\/.*)?(\/[^\/]+)"
	[[ "$DIR" =~ $RE ]]
	if [ -z "${BASH_REMATCH}" ]; then
		[ "$DIR" = "/" ] && printf ":/"
		return
	fi
	printf ":"
	[ "${DIR:0:1}" = "~" ] && printf "~"
	REST="${BASH_REMATCH[1]}"
	LAST="${BASH_REMATCH[2]}"

	RE="(\/.)[^\/]+"
	while [[ "$REST" =~ $RE ]]; do
		printf "${BASH_REMATCH[1]}"
		REST="${REST#*$BASH_REMATCH}"
	done

	echo "$LAST"
}
