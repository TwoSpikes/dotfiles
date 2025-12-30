use ::std::io::{Error, ErrorKind, Write};
use ::std::fs::{read_to_string, OpenOptions, copy};
use ::std::process::{Stdio, Command};
use ::std::path::PathBuf;
use ::std::str;
use ::std::fmt::Formatter;

pub mod package_manager_wrapper;
use self::package_manager_wrapper::PackageManagerWrapper;
mod utils;
use utils::copy_dir_all;
use utils::head;

use ::libdotfilesctlcfg::Config;

use ::dirs::home_dir;
use ::which::which;
use ::console::{Term, Key};

pub struct Osinfo {
    pub os: String,
    pub ver: String,

    pub termux_version: Option<String>,
}

impl Osinfo {
    pub fn new() -> Self {
        let info = ::os_info::get();

        let termux_version = match ::std::env::var("TERMUX_VERSION") {
            Ok(x) => Some(x.to_string()),
            Err(_) => None,
        };

        Self {
            os: info.os_type().to_string(),
            ver: info.version().to_string(),

            termux_version,
        }
    }
}

pub enum AutorunProgram {
    Null,
    Neovim,
}

impl ::std::fmt::Display for AutorunProgram {
    fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
        use AutorunProgram::*;

        write!(f, "{}", match self {
            Null => "None",
            Neovim => "Neovim",
        })
    }
}

pub enum SelectedShell {
    Bash,
    Zsh,
}

impl ::std::fmt::Display for SelectedShell {
    fn fmt(&self, f: &mut Formatter) -> ::std::fmt::Result {
        use SelectedShell::*;

        write!(f, "{}", match self {
            Bash => "bash",
            Zsh => "zsh",
        })
    }
}

pub struct DotfilesInstaller {
    pub config: Config,
    pub osinfo: Osinfo,

    autorun_program: AutorunProgram,
    selected_shell: SelectedShell,
}

impl DotfilesInstaller {
    pub fn new(autorun_program: AutorunProgram, selected_shell: SelectedShell) -> Self {
        let home_path = home_dir().expect("Cannot get home directory");
        let root_path = Some(Box::new(PathBuf::from(match ::std::env::var("PREFIX") {
            Ok(x) => x,
            Err(_) => "/".to_string(),
        })));

        let config = Config {
            home_path: Some(Box::new(home_path.clone())),
            dotfiles_path: Some(Box::new(home_path.join("dotfiles"))),
            root_path,
        };

        Self {
            config,
            osinfo: Osinfo::new(),

            autorun_program,
            selected_shell,
        }
    }

    fn get_latest_dotfiles(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("git", "git")?;

        let output = Command::new("git")
            .args(&[
                "clone",
                "--depth=1",
                "https://github.com/TwoSpikes/dotfiles.git",
                (*self.config.dotfiles_path.clone().unwrap())
                .display().to_string().as_str(),
            ])
            .output()
            .expect("Failed to get output of git process");

        if !output.status.success() {
            return Err(Error::new(ErrorKind::Other, match output.status.code() {
                Some(x) => format!("git finished with error code: {}", x),
                None => "git was killed by a signal".into(),
            }));
        }

        let version_file_path = (*self.config.dotfiles_path.clone().unwrap()).join(".dotfiles-version");
        if !version_file_path.exists() {
            return Err(Error::new(ErrorKind::NotFound, "Failed to get latest dotfiles"));
        }

        return Ok(());
    }

    fn check_for_cargo(&self, pmw: &PackageManagerWrapper) -> bool {
        if which("cargo").is_ok() { return true; }

        match self.osinfo.os.as_str() {
            "Termux"|
            "Void"|
            "FreeBSD"|
            "Arch Linux"|
            "Arch Linux 32" => {
                return pmw.check_dependency("rust", "cargo");
            },
            "openSUSE Leap" | "openSUSE Tumbleweed" => {
                return pmw.check_dependency("rustup", "cargo");
            },
            "Alpine Linux" => {
                if which("ld.lld").is_err() &&
                    which("ld64.lld").is_err() &&
                        which("lld-link").is_err() &&
                        which("wasm-ld").is_err() {
                            if pmw.install_package("gcc").is_err() { return false; };
                }
                return download_rustup(&pmw).is_ok();
            },
            _ => {
                return download_rustup(&pmw).is_ok();
            },
        }
    }

    pub fn bootstrap(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("curl", "curl")?;
        let version_file_path = (*self.config.dotfiles_path.clone().unwrap()).join(".dotfiles-version");
        let local_dotfiles_version = read_to_string(version_file_path);
        let local_dotfiles_version = match local_dotfiles_version {
            Ok(x) => Ok(x.trim().to_string()),
            Err(e) => Err(e),
        };

        match local_dotfiles_version {
            Ok(ref x) => println!("Local dotfiles version: {}", x),
            Err(ref e) => eprintln!("Local dotfiles not found: {}", e),
        }

        let curl_output = Command::new("curl")
            .args(&[
                "-fsS",
                "https://raw.githubusercontent.com/TwoSpikes/dotfiles/master/.dotfiles-version",
            ])
            .stdout(Stdio::piped())
            .output()
            .expect("Failed get output of curl process");
        let latest_dotfiles_version = match curl_output.status.success() {
            true => Ok(str::from_utf8(&curl_output.stdout).expect("Output of curl was not a valid utf-8 text").trim()),
            false => match curl_output.status.code() {
                Some(x) => Err(Error::new(ErrorKind::Other, format!("curl finished with error code: {}", x))),
                None => Err(Error::new(ErrorKind::Other, format!("curl was killed by a signal"))),
            },
        };

        if local_dotfiles_version.is_err() && latest_dotfiles_version.is_err() {
            eprintln!("Neither local nor latest dotfiles were found");
            match latest_dotfiles_version {
                Ok(_) => unreachable!(),
                Err(e) => return Err(e),
            }
        }

        match latest_dotfiles_version {
            Ok(ref x) => println!("Latest dotfiles version: {}", x),
            Err(ref e) => eprintln!("Latest dotfiles not found: {}", e),
        }

        match local_dotfiles_version {
            Ok(local_dotfiles_version) => {
                if let Ok(latest_dotfiles_version) = latest_dotfiles_version && local_dotfiles_version != latest_dotfiles_version {
                    println!("Dotfiles are old, new version is avelible");
                    print!("Do you want to update dotfiles? [Y/n]: ");
                    ::std::io::stdout().flush()?;
                    let c = Term::read_key(&Term::stdout());
                    eprintln!();
                    let c = c?;
                    if !matches!(c, Key::Char('n')) {
                        match self.get_latest_dotfiles(&pmw) {
                            Ok(_) => {},
                            Err(e) => {
                                print!("Dotfiles were not updated, would you like to continue? [y/N]: ");
                                ::std::io::stdout().flush()?;
                                let c = Term::read_key(&Term::stdout());
                                eprintln!();
                                let c = c?;
                                if !matches!(c, Key::Char('y')) {
                                    return Err(e);
                                }
                            },
                        }
                    }
                }
            },
            Err(e) => {
                if latest_dotfiles_version.is_ok() {
                    print!("Do you want to download dotfiles? [Y/n]: ");
                    ::std::io::stdout().flush()?;
                    let c = Term::read_key(&Term::stdout());
                    eprintln!();
                    let c = c?;
                    return Err(if !matches!(c, Key::Char('n')) {
                        e
                    } else {
                        Error::new(ErrorKind::Interrupted, "User cancelled dotfiles downloading")
                    });
                };
            },
        }

        print!("Would you like to start? [Y/n]: ");
        ::std::io::stdout().flush()?;
        let c = Term::read_key(&Term::stdout());
        eprintln!();
        let c = c?;
        if matches!(c, Key::Char('n')) {
            return Err(Error::new(ErrorKind::Interrupted, "Cancelled by user"));
        }

        if !self.check_for_cargo(&pmw) {
            return Err(Error::new(ErrorKind::Other, "Failed to install Cargo"));
        };

        ::std::env::set_current_dir(*self.config.dotfiles_path.clone().unwrap())?;

        let status = run_as_superuser_if_needed!(
            "cargo",
            &[
                "install",
                "--path",
                "util/dotfiles",
            ]
        );

        if !status.success() {
            return Err(Error::new(ErrorKind::Other, "Build failed"));
        }

        return Ok(());
    }

    fn setup_zsh(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("zsh", "zsh")?;
        copy((*self.config.dotfiles_path.clone().unwrap()).join(".zshrc"), *self.config.home_path.clone().unwrap())?;
        copy((*self.config.dotfiles_path.clone().unwrap()).join(".dotfiles-script.sh"), *self.config.home_path.clone().unwrap())?;
        copy((*self.config.dotfiles_path.clone().unwrap()).join(".profile"), *self.config.home_path.clone().unwrap())?;
        copy_dir_all((*self.config.dotfiles_path.clone().unwrap()).join("bin"), (*self.config.home_path.clone().unwrap()).join("bin"))?;
        Ok(())
    }

    fn setup_bash(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("bash", "bash")?;
        copy((*self.config.dotfiles_path.clone().unwrap()).join(".bashrc"), *self.config.home_path.clone().unwrap())?;
        copy((*self.config.dotfiles_path.clone().unwrap()).join(".dotfiles-script.sh"), *self.config.home_path.clone().unwrap())?;
        copy((*self.config.dotfiles_path.clone().unwrap()).join(".profile"), *self.config.home_path.clone().unwrap())?;
        copy_dir_all((*self.config.dotfiles_path.clone().unwrap()).join("bin"), (*self.config.home_path.clone().unwrap()).join("bin"))?;
        Ok(())
    }

    pub fn setup_shell(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        let dotfiles_config_path = (*self.config.dotfiles_path.clone().unwrap()).join(".config/dotfiles");

        ::std::fs::create_dir_all(&dotfiles_config_path)?;

        let mut file = OpenOptions::new()
            .append(true)
            .create(true)
            .open(dotfiles_config_path.join("config.cfg"))?;

        writeln!(&mut file, "autorun_program = {}", self.autorun_program)?;
        writeln!(&mut file, "shell = {}", self.selected_shell)?;

        use SelectedShell::*;
        match self.selected_shell {
            Bash => self.setup_bash(&pmw),
            Zsh => self.setup_zsh(&pmw),
        }
    }

    pub fn setup_common_lisp(&self) -> ::std::io::Result<()> {
        copy((*self.config.dotfiles_path.clone().unwrap()).join(".eclrc"), *self.config.home_path.clone().unwrap())?;
        copy((*self.config.dotfiles_path.clone().unwrap()).join("sbclrc"), *self.config.home_path.clone().unwrap())?;
        Ok(())
    }

    pub fn setup_emacs(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("emacs", "emacs")?;

        let emacs_config_path = (*self.config.dotfiles_path.clone().unwrap()).join(".emacs.d");

        ::std::fs::create_dir_all(&emacs_config_path)?;

        copy_dir_all(emacs_config_path, *self.config.home_path.clone().unwrap())?;

        Ok(())
    }

    pub fn setup_bd(&self) -> ::std::io::Result<()> {
        let bd_path = (*self.config.home_path.clone().unwrap()).join(".zsh/plugins/bd");
        let bd_script_path = bd_path.clone().join("bd.zsh");
        let zshrc_path = (*self.config.home_path.clone().unwrap()).join(".zshrc");

        if !bd_script_path.exists() {

            let output = Command::new("curl")
                .args(&[
                    "https://raw.githubusercontent.com/Tarrasch/zsh-bd/master/bd.zsh",
                ])
                .output()
                .expect("Failed to get output of curl process");
            let output = str::from_utf8(&output.stdout).expect("Output of curl was not a valid utf-8 text");

            let mut f = OpenOptions::new()
                .write(true)
                .create(true)
                .open(bd_script_path)?;
            write!(&mut f, "{}", output)?;
        }

        let mut f = OpenOptions::new()
            .append(true)
            .create(true)
            .open(zshrc_path)?;
        writeln!(&mut f, "\n# zsh-bd\n. $HOME/.zsh/plugins/bd/bd.zsh")?;

        Ok(())
    }

    pub fn setup_z4h(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("curl", "curl")?;

        let curl_output = Command::new("curl")
            .args(&[
                "-fsS",
                "https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install",
            ])
            .output()
            .expect("Failed to get output of curl process");

        if !curl_output.status.success() {
            return Err(Error::new(ErrorKind::Other, match curl_output.status.code() {
                Some(x) => format!("curl finished with error code: {}", x),
                None => "curl was killed by a signal".into(),
            }));
        }

        let output = str::from_utf8(&curl_output.stdout).expect("Output of curl was not a valid utf-8 text");
        let output = head(output.to_string(), -1);

        let mut shell = Command::new("sh")
            .stdin(Stdio::piped())
            .spawn()
            .expect("Failed to spawn sh process");

        let mut stdin = shell.stdin.take().expect("Failed to take over input of sh process");

        stdin.write_all(output.as_bytes()).expect("Failed to write to sh");

        shell.wait()?;

        Ok(())
    }

    pub fn setup_helix(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("helix", "hx")?;
        Ok(())
    }
}

fn download_rustup(pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
    pmw.check_dependency_result("curl", "curl")?;

    let output = Command::new("curl")
        .args(&[
            "--proto",
            "=https",
            "https://sh.rustup.rs",
            "-sSf",
        ])
        .stdout(Stdio::piped())
        .output()
        .expect("Failed get output of curl process");

    if !output.status.success() {
        return Err(Error::new(ErrorKind::Other, match output.status.code() {
            Some(x) => format!("curl finished with error code: {}", x),
            None => "curl was killed by a signal".into(),
        }));
    }

    let mut process = Command::new("sh")
        .stdin(Stdio::piped())
        .spawn()
        .expect("Failed to spawn sh process");

    let mut stdin = process.stdin.take().expect("Failed to take over input of sh process");
    let stdout = str::from_utf8(&output.stdout).expect("Output of curl was not a valid utf-8 text");

    stdin.write_all(stdout.as_bytes()).expect("Failed to write to sh");

    process.wait()?;

    Ok(())
}
