use ::std::path::Path;

use ::libdotfilesctlcfg::Config;

// Copyied from StackOverflow: https://stackoverflow.com/questions/26958489/how-to-copy-a-folder-recursively-in-rust
fn copy_dir_all(
    src: impl AsRef<::std::path::Path> + ::std::convert::AsRef<::std::path::Path>,
    dst: impl AsRef<::std::path::Path> + ::std::convert::AsRef<::std::path::Path>,
) -> ::std::io::Result<()> {
    _ = ::std::fs::create_dir_all(&dst);
    for entry in ::std::fs::read_dir(src)? {
        let entry = entry?;
        let ty = entry.file_type()?;
        if ty.is_dir() {
            _ = copy_dir_all(entry.path(), dst.as_ref().join(entry.file_name()));
        } else {
            _ = ::std::fs::copy(entry.path(), dst.as_ref().join(entry.file_name()));
        }
    }
    Ok(())
}

pub fn commit(
    only_copy: bool,
    config: Config,
) -> ::std::io::Result<()> {
    let dotfiles_path = *(config.dotfiles_path.unwrap());
    ::std::env::set_current_dir(dotfiles_path)?;
    let is_termux: bool = ::std::env::var("TERMUX_VERSION").is_ok();
    let home_path = config.home_path.unwrap();
    _ = ::std::fs::copy(home_path.join(".dotfiles-script.sh"), "./.dotfiles-script.sh");
    _ = ::std::fs::copy(home_path.join(".profile"), "./.profile");
    _ = ::std::fs::copy(home_path.join(".bashrc"), "./.bashrc");
    _ = ::std::fs::copy(home_path.join(".zshrc"), "./.zshrc");
    _ = ::std::fs::copy(home_path.join(".eclrc"), "./.eclrc");
    _ = ::std::fs::copy(home_path.join("sbclrc"), "./sbclrc");
    _ = copy_dir_all(home_path.join(".config/helix"), "./.config/helix");
    _ = ::std::fs::copy(home_path.join("bin/viman"), "./bin/viman");
    _ = ::std::fs::copy(home_path.join("bin/vipage"), "./bin/vipage");
    _ = ::std::fs::copy(home_path.join("bin/inverting.sh"), "./bin/inverting.sh");
    _ = ::std::fs::copy(home_path.join("bin/n"), "./bin/n");
    _ = ::std::fs::copy(home_path.join("bin/pie"), "./bin/pie");
    _ = ::std::fs::copy(home_path.join(".tmux.conf"), "./.tmux.conf");
    _ = ::std::fs::copy(home_path.join(".gitconfig-default"), "./.gitconfig-default");
    _ = ::std::fs::copy(home_path.join(".gitmessage"), "./.gitmessage");
    _ = copy_dir_all(home_path.join(".emacs.d"), "./.emacs.d");
    _ = ::std::fs::copy(
        home_path.join(".termux/colors.properties"),
        "./.termux/colors.properties",
    );
    _ = ::std::fs::copy(
        home_path.join(".termux/termux.properties"),
        "./.termux/termux.properties",
    );
    _ = copy_dir_all(home_path.join(".config/alacritty"), "./.config/alacritty");
    _ = ::std::fs::copy(home_path.join(".nanorc"), "./.nanorc");
    _ = ::std::fs::copy(
        home_path.join(".config/coc/extensions/node_modules/bash-language-server/out/cli.js"),
        "./\"coc-sh crutch\"/",
    );
    if !only_copy {
        match ::std::process::Command::new("git")
            .args(["commit", "--all", "--verbose"])
            .stdout(::std::process::Stdio::inherit())
            .stdin(::std::process::Stdio::inherit())
            .output()
        {
            Ok(_) => Ok(()),
            Err(e) => Err(e),
        }
    } else {
        Ok(())
    }
}
