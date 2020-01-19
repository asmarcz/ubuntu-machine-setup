# About

This script is what I've built while installing the stuff my friends and I use on my secondary machine. It is meant to quickly install all of the tools after clean Ubuntu-based-something install.

It may not suit your needs. Some of the things rely on default configuration/expected way of use.


# Usage

```
git clone --depth=1 https://github.com/asmarcz/ubuntu-machine-setup
```

Then substitute the example files with yours:
- `alises` is dumped into ~/.bashrc
- `vim_config` is dumped into ~/.vimrc
- all color schemes and config file for QTerminal are copied from qterminal (note that my config uses JetBrains Mono font)

1. Run script as is and it will prompt you for all of the avaible tools.
```
$ ./setup.sh 
Install aliases? [y/n]
...
```

2. Specify names of tools you want to install.
```
$ ./setup.sh bat firefoxdev
Install bat? [y/n]
...
Install firefoxdev? [y/n]
...
```

## Options
Append `-y` flag to skip prompts. Install everything available:
```
$ ./setup.sh -y
...
```

Append `-b` to hear bell ring after installation of each tool finishes. Install everything with ring after each:
```
$ ./setup.sh -y -b
...
```

List all available tools:
```
$ ./setup.sh --show-all
aliases
bat
...
```


# Notes

## Miniconda
If you choose not to initialize conda automatically you will need to run `init_conda` in order to use it. I usually disable it because I am sick of how slow it is to initialize.

## pyenv
The same as Miniconda. You will need to run `init_pyenv`. However pyenv will work even if you disable it. After installing it you would do:
```
$ pyenv install 3.8.1 # the version I want to invoke from my terminal
$ pyenv global 3.8.1
```
This will save you from slow start up but also provide you with whatever Python version.
The `script.sh` prepends `"$HOME"/.pyenv/shims` to your PATH so that it works with auto-initialization disabled. You would then run `init_pyenv` to have completions and all features.

## Node
Installs latest LTS release.


# How to extend

Just create a function inside the `setup.sh` and the rest will work out of the box.

```
...
install_yourToolOfChoice() {
	# download
	# unpack
	# clean up
}
...
```

You can also use `APT_ARRAY` to have packages installed by apt at the very end of `script.sh`.
```
install_yourToolOfChoice() {
	APT_ARRAY+=(package-in-repository)
}
```


# License

You are free to do anything with the software including modifying and redistributing. It will be nice if you credit me.

THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
