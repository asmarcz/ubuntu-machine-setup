#!/bin/bash
HOME=/home/$SUDO_USER

dependency_vim() {
	APT_ARRAY+=(vim-gtk3)
}

install_vim() {
	cat "$SCRIPT_DIR"/vim_config >> "$HOME"/.vimrc
}

install_miniconda() {
	MINICONDA=miniconda_installer$SEED
	wget -O $MINICONDA 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh'
	bash $MINICONDA
	rm $MINICONDA
	IS=$(grep -c '#miniconda-ubuntu-machine-setup' "$HOME"/.bashrc)
	if [[ "$IS" -eq 0 ]]; then
		printf 'init_conda() {\n\t' >> "$HOME"/.bashrc
		printf 'export PATH="/home/asmar/miniconda3/bin:$PATH"\n\t' >> "$HOME"/.bashrc
		echo '. ~/miniconda3/etc/profile.d/conda.sh #miniconda-ubuntu-machine-setup' >> "$HOME"/.bashrc
		echo '}' >> "$HOME"/.bashrc
		read -rp 'Do you want to initialize conda automatically? [y/n] ' YN
		if [ "$YN" != "n" ]; then
			echo 'init_conda' >> "$HOME"/.bashrc
		fi
	fi
}

dependency_pyenv() {
	# https://github.com/pyenv/pyenv/wiki/Common-build-problems 
	APT_ARRAY+=(make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git)
}

install_pyenv() {
	curl https://pyenv.run | bash
	IS=$(grep -c '#pyenv-ubuntu-machine-setup' "$HOME"/.profile)
	if [[ "$IS" -eq 0 ]]; then
		echo 'export PATH="$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH" #pyenv-ubuntu-machine-setup' >> "$HOME"/.profile
		echo 'pyenv rehash' >> "$HOME"/.profile
		printf 'init_pyenv() {\n\teval "$(pyenv init -)"\n' >> "$HOME"/.bashrc
		printf '\teval "$(pyenv virtualenv-init -)"\n}\n' >> "$HOME"/.bashrc
		read -rp 'Do you want to initialize pyenv automatically? [y/n] ' YN
		if [ "$YN" != "n" ]; then
			echo 'init_pyenv' >> "$HOME"/.bashrc
		fi
	fi
}

RUST_INSTALLED=false
if [ -f "$HOME"/.cargo/bin/rustc ]; then
	RUST_INSTALLED=true
fi
install_rust() {
	RUST=rust_installer$SEED
	wget -O $RUST 'https://sh.rustup.rs'
	bash $RUST
	rm $RUST
	RUSTUP=$HOME/.cargo/bin/rustup
	COMPLETION=$HOME/.local/share/bash-completion/completions
	$RUSTUP completions bash > "$COMPLETION"/rustup
	$RUSTUP completions bash cargo > "$COMPLETION"/cargo
	RUST_INSTALLED=true
}

install_bat() {
	IS_APT=$(apt-cache search --names-only '^bat$' | wc -l)
	if [ "$IS_APT" -eq 1 ]; then
		apt install -y bat
	elif [ "$RUST_INSTALLED" = true ]; then
		"$HOME"/.cargo/bin/cargo install bat
	else
		echo 'Could not install bat. It is neither in apt repository nor Rust is installed.' 1>&2
	fi
}

dependency_exa() {
	if [[ "$RUST_INSTALLED" = false ]]; then
		register_dependency exa rust
	fi
}

install_exa() {
	"$HOME"/.cargo/bin/cargo install exa
}

dependency_clang() {
	APT_ARRAY+=(clang make)
}

dependency_git() {
	APT_ARRAY+=(git)
}

install_aliases() {
	cat "$SCRIPT_DIR"/aliases >> "$HOME"/.bashrc
}

dependency_php() {
	APT_ARRAY+=(php-pear php-fpm php-dev php-zip php-curl php-xmlrpc php-gd php-mysql php-pgsql php-mbstring php-xml)
}

dependency_filezilla() {
	APT_ARRAY+=(filezilla)
}

install_firefoxdev() {
	FFDEV=ffdev$SEED
	wget -O $FFDEV 'https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US'
	tar -xjvf $FFDEV -C /opt
	mv /opt/firefox /opt/firefox_dev
	chgrp -R "$SUDO_USER" /opt/firefox_dev
	chmod -R g+rwx /opt/firefox_dev
	cp "$SCRIPT_DIR"/firefox_dev.desktop "$HOME"/.local/share/applications
	rm $FFDEV
}

install_vscode() {
	CODE=vscode$SEED
	wget -O $CODE 'https://go.microsoft.com/fwlink/?LinkID=760868'
	dpkg -i $CODE
	rm $CODE
}

install_go() {
	TEXT=$(wget -q -O - https://golang.org/dl/ | grep downloadBox | grep linux-amd64)
	REGEX='href="(.+)"'
	[[ $TEXT =~ $REGEX ]]
	URL="${BASH_REMATCH[1]}"
	GO=go$SEED
	wget -O $GO "$URL"
	tar -C /usr/local -xzf $GO
	rm $GO
	IS=$(grep -c '#go-ubuntu-machine-setup' "$HOME"/.profile)
	if [[ "$IS" -eq 0 ]]; then
		echo 'export PATH=$PATH:/usr/local/go/bin #go-ubuntu-machine-setup' >> "$HOME"/.profile
		GOPATH=$(/usr/local/go/bin/go env GOPATH)
		echo 'export PATH=$PATH:'"$GOPATH"'/bin #go-ubuntu-machine-setup' >> "$HOME"/.profile
	fi
}

dependency_libmagic() {
	APT_ARRAY+=(libmagic-dev)
}

dependency_shellcheck() {
	APT_ARRAY+=(shellcheck)
}

# installs latest LTS
install_node() {	
	REGEX='href="(latest-v([0-9]+).*)"'
	MAX=0
	SOURCE='https://nodejs.org/dist/'
	while read -r L; do
		[[ "$L" =~ $REGEX ]]
		if [[ "${#BASH_REMATCH[@]}" -eq 3 ]]; then
			if [[ "${BASH_REMATCH[2]}" -gt $MAX && $(("${BASH_REMATCH[2]}" % 2)) -eq 0 ]]; then
				MAX="${BASH_REMATCH[2]}"
				BASE_URL="${BASH_REMATCH[1]}"
			fi
		fi
	done <<< "$(wget -q -O - $SOURCE)"
	
	COMPLETE="$(wget -q -O - "$SOURCE$BASE_URL" | grep linux-x64 | grep xz)"
	REGEX='href="(.+)"'
	[[ "$COMPLETE" =~ $REGEX ]]
	ARCHIVE="${BASH_REMATCH[1]}"
	
	URL="$SOURCE$BASE_URL$ARCHIVE"
	NODE=node$SEED
	wget -O $NODE "$URL"
	tar -xJf $NODE -C /opt
	rm $NODE

	REGEX='(.+)\.tar\.xz'
	[[ "$ARCHIVE" =~ $REGEX ]]
	mv /opt/"${BASH_REMATCH[1]}" /opt/node
	chown -R "$SUDO_USER":"$SUDO_USER" /opt/node

	IS=$(grep -c '#node-ubuntu-machine-setup' "$HOME"/.profile)
	if [[ "$IS" -eq 0 ]]; then
		echo 'export PATH=$PATH:/opt/node/bin #node-ubuntu-machine-setup' >> "$HOME"/.profile
	fi
}

dependency_nextcloud() {
	add-apt-repository ppa:nextcloud-devs/client
	APT_ARRAY+=(nextcloud-client)
}

dependency_qterminal() {
	APT_ARRAY+=(qterminal)
}

install_qterminal() {
	mkdir -p "$HOME"/.config/qterminal.org/color-schemes
	cp "$SCRIPT_DIR"/qterminal/*.schema "$HOME"/.config/qterminal.org/color-schemes
	cp "$SCRIPT_DIR"/qterminal/*.colorscheme "$HOME"/.config/qterminal.org/color-schemes
	cp "$SCRIPT_DIR"/qterminal/qterminal.ini "$HOME"/.config/qterminal.org
	chown -R "$SUDO_USER":"$SUDO_USER" "$HOME"/.config/qterminal.org
}

install_jetbrainsmono() {
	REGEX='download.jetbrains.com/fonts/[a-zA-Z0-9.-]*'
	SOURCE='https://www.jetbrains.com/lp/mono/'
	while read -r L; do
		[[ "$L" =~ $REGEX ]]
		if [[ -n "${BASH_REMATCH[0]}" ]]; then
			URL="${BASH_REMATCH[0]}"
			break
		fi
	done <<< "$(wget -q -O - $SOURCE)"
	JBMONO=jbmono$SEED
	wget -O $JBMONO "$URL"
	mkdir -p "$HOME"/.fonts
	unzip -d "$HOME"/.fonts $JBMONO
	fc-cache -f -v
	rm $JBMONO
}

ask() {
	read -rp "Install $1? [y/n] " YN
	if [ "$YN" != "n" ]; then
		install_"$1"
		FULLFILLED[$(get_names_index "$EL")]=true
	fi
}

ask_dep() {
	read -rp "Install $1? [y/n] " YN
	if [[ "$YN" != "n" ]]; then
		dependency_"$1"
		FULLFILLED_DEP[$(get_names_index "$EL")]=true
	fi
}

SEED=${RANDOM:0:4}

SCRIPT_DIR=$(dirname "$0")
declare -a APT_ARRAY

declare -a NAMES
YES=false
BELL=false
SHOWALL=false
if [[ $# -gt 0 ]]; then
	for EL in "$@"; do
		if [[ "$EL" = '-y' ]]; then
			YES=true
		elif [[ "$EL" = '-b' ]]; then
			BELL=true
		elif [[ "$EL" = '--show-all' ]]; then
			SHOWALL=true
		else
			NAMES+=("$EL")
		fi
	done
fi

get_names_index() {
	local RET=-1
	for (( I = 0; I < ${#NAMES[@]}; I++ )); do
		if [[ "${NAMES[$I]}" = "$1" ]]; then
			RET=$I
			break
		fi
	done
	echo $RET
}

populate_names() {
	INSTALL_REGEX='install_([a-zA-Z0-9]+)'
	DEPENDENCY_REGEX='dependency_([a-zA-Z0-9]+)'
	for EL in $(declare -F); do
		if [[ "$EL" =~ $INSTALL_REGEX ]]; then
			if [[ "$(get_names_index ${BASH_REMATCH[1]})" -eq -1 ]]; then
				NAMES+=("${BASH_REMATCH[1]}")
			fi
		elif [[ "$EL" =~ $DEPENDENCY_REGEX ]]; then
			if [[ "$(get_names_index ${BASH_REMATCH[1]})" -eq -1 ]]; then
				NAMES+=("${BASH_REMATCH[1]}")
			fi
		fi
	done
}

if [[ "$SHOWALL" = true ]]; then
	populate_names
	for TOOL in "${NAMES[@]}"; do
		echo "$TOOL"
	done
	exit 0
elif [[ "${#NAMES[@]}" -eq 0 ]]; then
	populate_names
fi

if [[ "$(id -u)" -ne 0 ]]; then
	echo 'You need to run this script with root privileges.' 1>&2
	exit 1
fi

declare -a FULLFILLED_DEP
declare -a FULLFILLED
declare -a DEPENDENCIES

for (( I = 0; I < "${#NAMES[@]}"; I++ )); do
	FULLFILLED_DEP[$I]=false
	FULLFILLED[$I]=false
	DEPENDENCIES[$I]=-1
done

register_dependency() {
	local DEP
	DEP=$(get_names_index "$2")
	if [[ "$DEP" -eq -1 ]]; then
		DEP="${#NAMES[@]}"
		NAMES+=("$2")
		FULLFILLED_DEP+=(false)
		FULLFILLED+=(false)
		DEPENDENCIES+=(-1)
	fi
	DEPENDENCIES[$(get_names_index "$1")]="$DEP"
}

go_through_dependencies() {
	local RAN=false
	for (( I = 0; I < "${#NAMES[@]}"; I++ )); do
		EL="${NAMES[$I]}"
		T=$(type -t "dependency_$EL")
		if [[ "$T" = 'function' && "${FULLFILLED_DEP[$I]}" = false ]]; then
			if [[ "$YES" = true ]]; then
				dependency_"$EL"
				FULLFILLED_DEP[$I]=true
			else
				ask_dep "$EL"
			fi
			RAN=true
		fi
	done
	if [[ "$RAN" = true ]]; then
		go_through_dependencies # causes infinite loop when user declines dependency
	fi
}

go_through_dependencies

if [[ ${#APT_ARRAY[@]} -gt 0 ]]; then
	apt update
	apt install -y "${APT_ARRAY[@]}"
fi

process() {
	local I="$1"
	local EL="${NAMES[$I]}"
	if [[ "${FULLFILLED[$I]}" = false ]]; then
		if [[ "${DEPENDENCIES[$I]}" -ne -1 ]]; then
			echo "Installing dependency ${NAMES[${DEPENDENCIES[$I]}]} for $EL."
			process "${DEPENDENCIES[$I]}"
		fi
		T=$(type -t "dependency_$EL")
		if [[ "$T" = 'function' && "${FULLFILLED_DEP[$I]}" = true || "$T" != 'function' ]]; then
			if [[ "$YES" = true || "${FULLFILLED_DEP[$I]}" = true ]]; then
				install_"$EL"
				FULLFILLED[$I]=true
			else
				ask "$EL"
			fi
			if [[ "$BELL" = true ]]; then
				paplay '/usr/share/sounds/freedesktop/stereo/complete.oga'
			fi
		elif [[ "$T" = 'function' && "${FULLFILLED_DEP[$I]}" = false ]]; then
			echo "Could not install $EL. Dependencies were not fullfilled or user declined." 1>&2
		fi
	fi
}

for (( I = 0; I < "${#NAMES[@]}"; I++ )); do
	EL="${NAMES[$I]}"
	T=$(type -t "install_$EL")
	if [[ "$T" = 'function' ]]; then
		process $I
	else
		T=$(type -t "dependency_$EL")
		if [[ "$T" != 'function' ]]; then
			echo "$EL is not currently supported."
		fi
	fi
done
