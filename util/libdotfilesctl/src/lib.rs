use ::std::borrow::Borrow;
use ::std::io::{Error, ErrorKind, Write};
use ::std::fs::read_to_string;
use ::std::process::{exit, Stdio, Command};
use ::std::path::PathBuf;
use ::std::str;
use ::std::sync::Arc;

pub mod package_manager_wrapper;
use self::package_manager_wrapper::PackageManagerWrapper;

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

pub struct DotfilesInstaller {
    pub config: Config,
    pub osinfo: Osinfo,

    git_found: bool,
}

impl DotfilesInstaller {
    pub fn new() -> Self {
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

            git_found: which("git").is_ok(),
        }
    }

    fn get_latest_dotfiles(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("git")?;

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

        let version_file_path = (*self.config.dotfiles_path.clone().unwrap()).join(".dotfiles-version");
        if !version_file_path.exists() {
            return Err(Error::new(ErrorKind::NotFound, "Failed to get latest dotfiles"));
        }

        return Ok(());
    }

    pub fn bootstrap(&self, pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
        pmw.check_dependency_result("curl")?;
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

        return Ok(());
    }
}

pub fn download_rustup(pmw: &PackageManagerWrapper) -> ::std::io::Result<()> {
    pmw.check_dependency_result("curl")?;
    eprintln!("Downloading rustup from https://sh.rustup.rs ...");

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
        eprintln!("curl failed");
        exit(1);
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
