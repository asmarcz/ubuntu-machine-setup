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

# ex - extract archive to enclosing directory inside current directory
# usage: ex [--mix|-m] <file> [files...]
ex() {
	local ARG DIR EXT MIX
	MIX=0
	for ARG in "$@"; do
		if [[ "$ARG" = "--mix" || "$ARG" = "-m" ]]; then
			MIX=1
			break
		fi
	done
	for ARG in "$@"; do
		if [ -f "$ARG" ]; then
			case "$ARG" in
				*.tar.bz2)   EXT=.tar.bz2                ;;
				*.tar.gz)    EXT=.tar.gz                 ;;
				*.tar.xz)    EXT=.tar.xz                 ;;
				*.bz2)       bunzip2 $ARG && continue    ;;
				*.rar)       EXT=.rar                    ;;
				*.gz)        gunzip $ARG && continue     ;;
				*.tar)       EXT=.tar                    ;;
				*.tbz2)      EXT=.tbz2                   ;;
				*.tgz)       EXT=.tgz                    ;;
				*.zip)       EXT=.zip                    ;;
				*.zst)       unzstd $ARG && continue     ;;
				*.Z)         uncompress $ARG && continue ;;
				*.7z)        EXT=.7z                     ;;
				*)           echo "Skipping $ARG: cannot be extracted via ex()" && continue ;;
			esac
			DIR="$(basename "$ARG")"
			DIR="${DIR%"$EXT"}"
			if [ $MIX -eq 0 ]; then
				if [ -d "$DIR" ]; then
					echo "Skipping $ARG: $DIR exists and mixing is not enabled."
					continue
				fi
			fi
			mkdir -p "$DIR"
			case "$EXT" in
				.tar.bz2)   tar xjf $ARG -c "$DIR" ;;
				.tar.gz)    tar xzf $ARG -c "$DIR" ;;
				.tar.xz)    tar xJf $ARG -c "$DIR" ;;
				.rar)       unrar $ARG -o "$DIR"   ;;
				.tar)       tar xf $ARG -c "$DIR"  ;;
				.tbz2)      tar xjf $ARG -c "$DIR" ;;
				.tgz)       tar xzf $ARG -c "$DIR" ;;
				.zip)       unzip "$ARG" -d "$DIR" ;;
				.7z)        7z x "$ARG" -o"$DIR"   ;;
			esac
		fi
	done
}
