# What is this

My scripts and configs for Linux

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

# Manual installation

## .dotfiles-setup.sh

### Installation

```console
$ cp ./.dotfiles-setup.sh ~/
```

Then you need to restart your shell

```console
$ exec $SHELL -l
```

## .gitconfig-default .gitmessage

### What is this?

This is a basic Git configuration

### Installation

```console
$ cp ./.gitconfig-default ~/
$ cp ~/.gitconfig-default ~/.gitconfig
```
Now, in file `~/.gitconfig`
Uncomment lines `[user] name` and `[user] email`\
Change `Your Name` to your name\
Change `youremail@example.com` to your email

```console
$ cp ./.gitmessage ~/
```

## .config/nvim/

### What is this?

This is NeoVim/Vim configuration

<details><summary>
Screenshots
</summary>

<img src=.github/images/Screenshot_2024-04-13-18-21-05-51_84d3000e3f4017145260f7618db1d683.jpg>
<img src=.github/images/Screenshot_2024-04-13-18-23-57-59_84d3000e3f4017145260f7618db1d683.jpg>

</details>

> [!Warning]
> It works better in NeoVim, and packer.nvim does not work yet in version of Vim/NeoVim without Lua.

Change to light theme: `:set background=light` \
Change to dark theme: `:set background=dark`

<details><summary>
Manual installation
</summary>

### Installation

```console
$ cp -r ./.config/nvim/ ~/.config/
```

### Extra step for Vim

```console
$ echo "so ~/.config/nvim/init.vim" >> ~/.vimrc
```

</details>

<details><summary>
Config for dotfiles
</summary>

#### Where is it?

```console
$ mkdir -p ~/.config/dotfiles/vim/
$ vim ~/.config/dotfiles/vim/config.json
```

If you want to change default dotfiles config path:
```console
$ DOTFILES_VIM_CONFIG_PATH=your_path nvim
```

#### Default config

> [!Note]
> Fields starting with `_comment` are comments

```json
{
"_comment_01":"Transparent background",
"_comment_02":"Values:",
"_comment_03":"    always - In dark and light theme",
"_comment_04":"    dark   - In dark theme",
"_comment_05":"    light  - In light theme",
"_comment_06":"    never  - Non-transparent",
	"use_transparent_bg": "dark",

"_comment_07":"Prevent setting up LSP if false",
"_comment_08":"Useful if it does not work",
	"setup_lsp": false,

"_comment_09":"light - light background",
"_comment_10":"dark  - dark background",
	"background": "dark",

"_comment_11":"Use italic style for text",
"_comment_12":"Useful for terminals with bugged italic font (like Termux)",
	"use_italic_style": true,

"_comment_13":"Ending field to not put comma every time"
}
```

</details>

## tsch.sh [deprecated]

### What is this?

It is a script that runs tsch (`TwoSpikes ChooseHub`)\
It is my old thing that asks for my several most used commands but no I do not use it.

### Installation

```console
$ echo "source ./tsch.sh" >> ~/.bashrc
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

## xterm-color-table.vim

### What is this?

It is an xterm color table (256 colors) for vim/neovim.\
Fork from [this repository](https://github.com/guns/xterm-color-table.vim)

### Installation

```console
$ cp ./xterm-color-table.vim ~/
```

### Running in Vim/NeoVim

```console
$ vim
```

Then you need to run this command

```vim
:Sxct       " In a horizontal split
:Vxct       " In a vertical split
:Txct       " In a new tab
:Exct       " In a new buffer
:Oxct       " In a fullscreen buffer
```
