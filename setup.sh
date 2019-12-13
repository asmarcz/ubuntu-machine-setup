#!/bin/bash
HOME=/home/$SUDO_USER

install_vim() {
	APT_ARRAY+=(vim-gtk3)
	cat "$SCRIPT_DIR"/vim_config >> "$HOME"/.vimrc
}

install_miniconda() {
	MINICONDA=miniconda_installer
	wget -O $MINICONDA "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
	bash $MINICONDA
	rm $MINICONDA
	echo ". ~/miniconda3/etc/profile.d/conda.sh" >> "$HOME"/.profile
}

RUST_INSTALLED=false
if [ -f "$HOME"/.cargo/bin/rustc ]; then
	RUST_INSTALLED=true
fi
install_rust() {
	RUST=rust_installer
	wget -O $RUST "https://sh.rustup.rs"
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
		echo "Could not install bat. It is neither in apt repository nor Rust is installed." 1>&2
	fi
}

install_exa() {
	if [ "$RUST_INSTALLED" = true ]; then
		"$HOME"/.cargo/bin/cargo install exa
	else
		echo "Could not install exa. Rust is not installed." 1>&2
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
	wget -O $FFDEV "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US" 
	tar -xjvf $FFDEV -C /opt
	mv /opt/firefox /opt/firefox_dev
	chgrp -R "$SUDO_USER" /opt/firefox_dev
	chmod -R g+rwx /opt/firefox_dev
	cp "$SCRIPT_DIR"/firefox_dev.desktop "$HOME"/.local/share/applications
	rm $FFDEV
}

install_vscode() {
	CODE=vscode
	wget -O $CODE "https://go.microsoft.com/fwlink/?LinkID=760868"
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
	IS=$(grep '#go-ubuntu-machine-setup' $HOME/.profile | wc -l)
	if [[ "$IS" -eq 0 ]]; then
		echo 'export PATH=$PATH:/usr/local/go/bin #go-ubuntu-machine-setup' >> $HOME/.profile
	fi
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
if [[ $# -gt 0 ]]; then
	for EL in $@; do
		NAMES+=("$EL")
	done
else	
	REGEX="install_([a-zA-Z0-9]+)"
	for EL in $(declare -f); do
		if [[ $EL =~ $REGEX ]]; then
			NAMES+=("${BASH_REMATCH[1]}")
		fi
	done
fi

for EL in "${NAMES[@]}"; do
	T=$(type -t "install_$EL")
	if [[ "$T" = "function" ]]; then
		ask "$EL"
	else
		echo "$EL is not currently supported."
	fi
done

if [ ${#a[@]} -gt 0 ]; then
	apt update
	apt install -y "${APT_ARRAY[@]}"
fi
