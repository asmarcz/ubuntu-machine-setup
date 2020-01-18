#!/bin/bash
HOME=/home/$SUDO_USER

install_vim() {
	APT_ARRAY+=(vim-gtk3)
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

install_pyenv() {
	# https://github.com/pyenv/pyenv/wiki/Common-build-problems 
	apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
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
		APT_ARRAY+=(bat)
	elif [ "$RUST_INSTALLED" = true ]; then
		"$HOME"/.cargo/bin/cargo install bat
	else
		echo 'Could not install bat. It is neither in apt repository nor Rust is installed.' 1>&2
	fi
}

install_exa() {
	if [ "$RUST_INSTALLED" = true ]; then
		"$HOME"/.cargo/bin/cargo install exa
	else
		echo 'Could not install exa. Rust is not installed.' 1>&2
	fi
}

install_clang() {
	APT_ARRAY+=(clang make)
}

install_git() {
	APT_ARRAY+=(git)
}

install_aliases() {
	cat "$SCRIPT_DIR"/aliases >> "$HOME"/.bashrc
}

install_php() {
	APT_ARRAY+=(php-pear php-fpm php-dev php-zip php-curl php-xmlrpc php-gd php-mysql php-pgsql php-mbstring php-xml)
}

install_filezilla() {
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

install_libmagic() {
	APT_ARRAY+=(libmagic-dev)
}

install_shellcheck() {
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
			#echo "${BASH_REMATCH[@]}"
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

	IS=$(grep -c '#node-ubuntu-machine-setup' "$HOME"/.profile)
	if [[ "$IS" -eq 0 ]]; then
		echo 'export PATH=$PATH:/opt/node/bin #node-ubuntu-machine-setup' >> "$HOME"/.profile
	fi
}

install_nextcloud() {
	add-apt-repository ppa:nextcloud-devs/client
	APT_ARRAY+=(nextcloud-client)
}

ask() {
	read -rp "Install $1? [y/n] " YN
	if [ "$YN" != "n" ]; then
		install_"$1"
	fi
}

SEED=${RANDOM:0:4}

SCRIPT_DIR=$(dirname "$0")
declare -a APT_ARRAY

declare -a NAMES
YES=false
BELL=false
if [[ $# -gt 0 ]]; then
	for EL in "$@"; do
		if [[ "$EL" = '-y' ]]; then
			YES=true
		elif [[ "$EL" = '-b' ]]; then
			BELL=true
		else
			NAMES+=("$EL")
		fi
	done
fi

if [[ ( "$YES" = true ) && ( $# -eq 1 ) || ( $# -eq 0 ) ]]; then
	REGEX='install_([a-zA-Z0-9]+)'
	for EL in $(declare -F); do
		if [[ $EL =~ $REGEX ]]; then
			NAMES+=("${BASH_REMATCH[1]}")
		fi
	done
fi

for EL in "${NAMES[@]}"; do
	T=$(type -t "install_$EL")
	if [[ "$T" = 'function' ]]; then
		if [[ "$YES" = true ]]; then
			install_"$EL"
		else
			ask "$EL"
			if [[ "$BELL" = true ]]; then
				paplay '/usr/share/sounds/freedesktop/stereo/complete.oga'
			fi
		fi
	else
		echo "$EL is not currently supported."
	fi
done

if [ ${#APT_ARRAY[@]} -gt 0 ]; then
	apt update
	apt install -y "${APT_ARRAY[@]}"
fi
