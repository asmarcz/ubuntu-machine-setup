#!/bin/bash
HOME=/home/$SUDO_USER

install_vim() {
	APT_ARRAY+=(vim-gtk3)
	cat "$SCRIPT_DIR"/vim_config >> "$HOME"/.vimrc
}

install_miniconda() {
	MINICONDA=miniconda_installer
	wget -O $MINICONDA 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh'
	bash $MINICONDA
	rm $MINICONDA
	echo '. ~/miniconda3/etc/profile.d/conda.sh' >> "$HOME"/.profile
}

RUST_INSTALLED=false
if [ -f "$HOME"/.cargo/bin/rustc ]; then
	RUST_INSTALLED=true
fi
install_rust() {
	RUST=rust_installer
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
	FFDEV=ffdev
	wget -O $FFDEV 'https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US'
	tar -xjvf $FFDEV -C /opt
	mv /opt/firefox /opt/firefox_dev
	chgrp -R "$SUDO_USER" /opt/firefox_dev
	chmod -R g+rwx /opt/firefox_dev
	cp "$SCRIPT_DIR"/firefox_dev.desktop "$HOME"/.local/share/applications
	rm $FFDEV
}

install_vscode() {
	CODE=vscode
	wget -O $CODE 'https://go.microsoft.com/fwlink/?LinkID=760868'
	dpkg -i $CODE
	rm $CODE
}

install_go() {
	TEXT=$(wget -q -O - https://golang.org/dl/ | grep downloadBox | grep linux-amd64)
	REGEX='href="(.+)"'
	[[ $TEXT =~ $REGEX ]]
	URL="${BASH_REMATCH[1]}"
	GO=go
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
	NODE=node
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

SCRIPT_DIR=$(dirname "$0")
declare -a APT_ARRAY

declare -a NAMES
YES=false
if [[ $# -gt 0 ]]; then
	for EL in "$@"; do
		if [[ "$EL" = '-y' ]]; then
			YES=true
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
		fi
	else
		echo "$EL is not currently supported."
	fi
done

if [ ${#APT_ARRAY[@]} -gt 0 ]; then
	apt update
	apt install -y "${APT_ARRAY[@]}"
fi
