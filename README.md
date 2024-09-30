# What is this

My scripts and configs for Linux

# Dependencies to install

If you have internet, most of that stuff can be downloaded by install script using system package manager.

- `coreutils` >= 8.22
- `rustc` and `cargo`
- `chsh`
- `git`
- `ping`
- `wget` or `curl`
- `ncurses` (not necessary)
- package manager: `pkg`, `apt`, `apt-get`, `winget`, `pacman`, `zypper`, `xbps-install`, `yum`, `aptitude`, `dnf`, `emerge`, `up2date`, `urpmi`, `slackpkg`, `apk`, `brew`, `flatpak` or `snap`
- `sudo` or `doas`
- `awk` or `gawk`

# Consists configs for

- `emacs` (WIP)
- `nano`
- `alacritty`
- `git`

# Automatic installation

## Cloning the repository

```console
$ git clone https://github.com/TwoSpikes/dotfiles.git
$ cd dotfiles
```

## Installation

```console
$ sh .dotfiles-setup.sh .
```

Or to install everything

```console
$ yes | sh .dotfiles-setup.sh .
```

> [!Note]
> After installation it is safe to remove local dotfiles repository

# Manual installation

## .dotfiles-setup.sh

### Installation

```console
$ cp ./.dotfiles-setup.sh ~/
```

Then you need to restart your shell

```console
$ exec $SHELL
```

## .gitconfig-default .gitmessage

### What is this?

This is a basic Git configuration

<details><summary>
Manual installation
</summary>

```console
$ cp ./.gitconfig-default ~/
$ cp ~/.gitconfig-default ~/.gitconfig
```
Now, in file `~/.gitconfig`
uncomment lines `[user] name` and `[user] email`\
Change `Your Name` to your name\
Change `youremail@example.com` to your email

```console
$ cp ./.gitmessage ~/
```

</details>

## .config/nvim

Vim configuration is moved to its own [repository](https://github.com/TwoSpikes/extra.nvim)

## tsch.sh [deprecated]

### What is this?

It is a script that runs tsch (`TwoSpikes ChooseHub`)\
It is my old thing that asks for my several most used commands but no I do not use it.

### Installation

```console
$ echo "source ./shscripts/tsch.sh" >> ~/.bashrc
```

Then you need to restart the shell

### Running
```console
$ tsch
```

## .emacs.d/

### What is this?

It is a configuration for GNU Emacs

### Installation

```console
$ cp -r ./.emacs.d/ ~/
```

# Contribution and other stuff

## Copy configs to this repo and commit

After installing dotfiles, run:
```console
$ dotfiles commit
```

If using Vim/NeoVim:
```console
:DotfilesCommit
```

[!Warning]
> Do not run this command in home directory, run it only in this repository, otherwise it will delete some files on your computer

## Get dotfiles version

```console
$ dotfiles version
```
