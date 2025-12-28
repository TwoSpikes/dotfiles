use ::std::io::{Error, ErrorKind};

use ::which::which;
use ::leon::{Template, vals};
use ::console::{Term, Key};

macro_rules! run_as_superuser_if_needed {
    ($name:expr, $args:expr) => {
        if ::whoami::realname() != "root"
            && !::std::env::var("TERMUX_VERSION")
                .expect("Cannot get envvar")
                .is_empty()
        {
            ::std::process::Command::new($name)
                .args($args)
                .status()
                .expect("failed to execute child process")
        } else {
            ::runas::Command::new($name)
                .args($args)
                .status()
                .expect("failed to execute child process")
        }
    };
}

enum PackageManager {
    NotFound,
    Pkg,
    Apt,
    AptGet,
    Winget,
    Pacman,
    Zypper,
    Xbps,
    Yum,
    Aptitude,
    Opkg,
    Dnf,
    Emerge,
    Up2Date,
    Urpmi,
    Slackpkg,
    Apk,
    Brew,
    Flatpak,
    Snap,
}

pub struct PackageManagerWrapper {
    pm: PackageManager,
}

impl PackageManagerWrapper {
    pub fn new() -> Self {
        let pm = Self::determine_package_manager();

        Self {
            pm
        }
    }

    fn determine_package_manager() -> PackageManager {
        use self::PackageManager::*;

        if which("pkg").is_ok() {
            return Pkg;
        }
        if which("apt").is_ok() {
            return Apt;
        }
        if which("apt-get").is_ok() {
            return AptGet;
        }
        if which("winget").is_ok() {
            return Winget;
        }
        if which("pacman").is_ok() {
            return Pacman;
        }
        if which("zypper").is_ok() {
            return Zypper;
        }
        if which("xbps-install").is_ok() {
            return Xbps;
        }
        if which("yum").is_ok() {
            return Yum;
        }
        if which("aptitude").is_ok() {
            return Aptitude;
        }
        if which("opkg").is_ok() {
            return Opkg;
        }
        if which("dnf").is_ok() {
            return Dnf;
        }
        if which("emerge").is_ok() {
            return Emerge;
        }
        if which("up2date").is_ok() {
            return Up2Date;
        }
        if which("urpmi").is_ok() {
            return Urpmi;
        }
        if which("slackpkg").is_ok() {
            return Slackpkg;
        }
        if which("apk").is_ok() {
            return Apk;
        }
        if which("brew").is_ok() {
            return Brew;
        }
        if which("flatpak").is_ok() {
            return Flatpak;
        }
        if which("snap").is_ok() {
            return Snap;
        }

        return NotFound;
    }

    pub fn install_package(&self, name: &str) -> ::std::io::Result<()> {
        use self::PackageManager::*;

        let templates = match self.pm {
            Pkg => ("pkg", vec!["install", "-y", "{}"]),
            Apt => ("apt", vec!["install", "-y", "{}"]),
            AptGet => ("apt-get", vec!["install", "-y", "{}"]),
            Winget => todo!(),
            Pacman => ("pacman", vec!["-Suy", "--noconfirm", "{}"]),
            Zypper => ("zypper", vec!["install", "-y", "{}"]),
            Xbps => ("xbps-install", vec!["-Sy", "{}"]),
            Yum => ("yum", vec!["install", "-y", "{}"]),
            Aptitude => ("aptitude", vec!["install", "-y", "{}"]),
            Opkg => ("opkg", vec!["install", "{}"]),
            Dnf => ("dnf", vec!["install", "-y", "{}"]),
            Emerge => ("emerge", vec!["--ask", "--verbose", "{}"]),
            Up2Date => ("up2date", vec!["{}"]),
            Urpmi => ("urpmi", vec!["--force", "{}"]),
            Slackpkg => ("slackpkg", vec!["install", "install", "{}"]),
            Apk => ("apk", vec!["add", "{}"]),
            Brew => ("brew", vec!["install", "{}"]),
            Flatpak => ("flatpak", vec!["install", "{}"]),
            Snap => ("snap", vec!["install", "{}"]),
            NotFound => {
                return Err(Error::new(ErrorKind::NotFound, "Package manager not found"));
            },
        };

        let program_name = Template::parse(templates.0)
            .expect("Unable to parse template")
            .render(
            &&vals(|key| Some(name.to_string().into()))
        ).expect("Unable to render template of program name");

        let mut program_arguments: Vec<String> = Vec::new();
        let mut iter = templates.1.iter();
        while let Some(arg) = iter.nth(0) {
            let arg = Template::parse(arg)
                .expect("Unable to parse template");
            let name = name.to_string();
            program_arguments.push(arg.render(
                &&vals(|key| Some(name.clone().into()))
            ).expect("Unable to render template of program argument"));
        }

        run_as_superuser_if_needed!(program_name, &program_arguments);

        Ok(())
    }

    pub fn install_package_persistently(&self, name: &str) -> bool {
        loop {
            self.install_package(name);
            if which(name).is_ok() { return true; }
            eprint!("Would you like to try again? [y/N]: ");
            let c = Term::read_key(&Term::stdout());
            eprintln!();
            let c = match c {
                Ok(x) => x,
                Err(_) => return false,
            };
            if !matches!(c, Key::Char('y')) { return false; }
        }
    }

    pub fn check_dependency(&self, name: &str) -> bool {
        if which(name).is_ok() { return true; }

        return self.install_package_persistently(name);
    }

    pub fn check_dependency_result(&self, name: &str) -> ::std::io::Result<()> {
        if which(name).is_ok() { return Ok(()); }

        return match self.install_package_persistently(name) {
            true => Ok(()),
            false => Err(Error::new(ErrorKind::Other, format!("Couldn't install package {}", name))),
        };
    }
}
