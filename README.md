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

- `nvim` (NeoVim) or `vim`
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

## .config/nvim/

> [!Warning]
> Do not delete code that seems strange, maybe you will break something

### What is this?

This is NeoVim/Vim configuration

<details open><summary>
Screenshots
</summary>

<img src=.github/images/a4.jpg width=100px height=222px>
<img src=.github/images/Screenshot_2024-05-21-22-05-31-89_84d3000e3f4017145260f7618db1d683.jpg width=100px height=100px>
<img src=.github/images/a2.jpg width=100px height=222px>
<img src=.github/images/a1.jpg width=100px height=222px>

</details>

### Minimal requirements (approximate)

- RAM: 60 MiB (minimal), 128 MiB (recommended)
- Free disk space: 146,4 MiB (minimal, including all plugins)
- Internet connection (to download plugins)
- `vim`
- `vim-runtime` (it is often already installed as a `vim` dependency)

> [!Warning]
> Implies to use [Nerd Fonts](https://www.nerdfonts.com)

> [!Warning]
> It works better in NeoVim, and packer.nvim does not work in version of Vim/NeoVim without Lua.

> [!Note]
> Press `SPACE ?` to see help

> [!Warning]
> After updating coc-sh language server, you need to reinstall coc-sh crutch:

<details><summary>
Reinstall coc-sh crutch
</summary>

Run this:
```console
$ ONLY_SETUP_COC_SH_CRUTCH=true ./.dotfiles-setup.sh .
```

</details>

Change to light theme: `:set background=light` \
Change to dark theme: `:set background=dark`

<details><summary>
Manual installation
</summary>

### Installation

```console
$ git clone https://github.com/TwoSpikes/extra.nvim ~/extra.nvim
$ cd ~/extra.nvim/util/installer
$ cargo run --
```

### Extra step for Vim

```console
$ echo "so ~/.config/nvim/init.vim" >> ~/.vimrc
```

</details>

<details open><summary>
Config for dotfiles
</summary>

#### Autogenerate

```console
$ dotfiles setup dotfiles vim
```

#### Where is it?

```console
$ mkdir -p ~/.config/dotfiles/vim/
$ vim ~/.config/dotfiles/vim/config.json
```

If you want to change default dotfiles config path:
```console
$ DOTFILES_VIM_CONFIG_PATH=your_path nvim
```

Like
```console
$ DOTFILES_VIM_CONFIG_PATH=~/dnsjajsbdn/vim/ nvim
```

</details>

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

## Get dotfiles version

```console
dotfiles version
```
