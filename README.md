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

> [!Note]
> After installation it is safe to remove local dotfiles repository

# Contribution and other stuff

## Copy configs to this repo and commit

After installing dotfiles, run:
```console
$ dotfilesctldev commit
```

If using Vim/NeoVim:
```console
:DotfilesCommit
```

> [!Warning]
> Do not run this command in home directory, run it only in this repository, otherwise it will delete some files on your computer

## Get dotfiles version

```console
$ dotfilesctldev version
```
