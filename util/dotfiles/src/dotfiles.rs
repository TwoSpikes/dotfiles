pub mod checkhealth;
pub mod colors;
pub mod timer;

use cursive::CursiveExt;
use std::io::Write;
use std::path::PathBuf;

use timer::timer_end_silent;
#[allow(unused_imports)]
use timer::{timer_endln, timer_start_silent, timer_startln, timer_total_time};

#[allow(unused_macros)]
macro_rules! clear {
    () => {
        print!("{esc}[2J{esc}[1;1H", esc = 27 as char);
    };
}

macro_rules! usage {
    ($program_name:expr) => {
        println!("{}: [OPTION]... COMMAND", $program_name);
    };
}

macro_rules! commands {
    () => {
        println!("COMAMNDS (case sensitive):");
        println!("\tcommit       Commit changes to dotfiles repo");
        println!("\thelp         Show this help");
        println!("\tversion --version -V     ");
        println!("\t             Show version");
        println!("\tinit         Initialize dotfiles");
    };
}

macro_rules! options {
    () => {
        println!("OPTIONS (case sensitive):");
        println!("\tFor 'commit' subcommand:");
        println!("\t\t--only-copy -o  Only copy, but not commit");
        println!("\t\t++only-copy +o  Copy and commit (default)");
    };
}

macro_rules! help {
    ($program_name:expr) => {
        usage!($program_name);
        println!();
        commands!();
        println!();
        options!();
    };
}

macro_rules! help_invitation {
    ($program_name:expr) => {
        println!("To see full help, run:");
        println!("{} --help", $program_name);
    };
}

macro_rules! short_help {
    ($program_name:expr) => {
        usage!($program_name);
        println!();
        help_invitation!($program_name);
    };
}

#[allow(unused_macros)]
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
fn find_vim_vimruntime_path(is_termux: bool) -> String {
    let paths = ::std::fs::read_dir(if cfg!(target_os = "windows") {
        "/c/Program Files/Vim/share/vim"
    } else {
        if is_termux {
            "/data/data/com.termux/files/usr/share/vim"
        } else {
            "/usr/share/vim"
        }
    })
    .unwrap();
    let mut maxver: Option<u16> = None;
    for path in paths {
        let path = path.unwrap().path();
        let mut filename = path.file_name().unwrap().to_str().unwrap();
        if filename.starts_with("vim") {
            let mut chars = filename.chars();
            _ = chars.next();
            _ = chars.next();
            _ = chars.next();
            filename = chars.as_str();
            let version = filename.parse::<u16>().unwrap();
            if match maxver {
                None => true,
                Some(maxver) => version > maxver,
            } {
                maxver = Some(version);
            }
        }
    }
    format!("vim{}", maxver.unwrap())
}
fn commit(only_copy: bool, #[allow(non_snake_case)] HOME: PathBuf) -> ::std::io::Result<()> {
    let is_termux: bool = ::std::env::var("TERMUX_VERSION").is_ok();
    _ = ::std::fs::copy(HOME.join(".dotfiles-script.sh"), "./.dotfiles-script.sh");
    _ = ::std::fs::copy(HOME.join(".bash_profile"), "./.bash_profile");
    _ = ::std::fs::copy(HOME.join(".bashrc"), "./.bashrc");
    _ = ::std::fs::copy(HOME.join(".zshrc"), "./.zshrc");
    _ = ::std::fs::copy(
        HOME.join(".config/nvim/init.vim"),
        "./.config/nvim/init.vim",
    );
    _ = ::std::fs::copy(HOME.join(".eclrc"), "./.eclrc");
    _ = ::std::fs::copy(HOME.join("sbclrc"), "./sbclrc");
    _ = copy_dir_all(HOME.join(".config/helix"), "./.config/helix");
    _ = ::std::fs::copy(HOME.join("bin/viman"), "./bin/viman");
    _ = ::std::fs::copy(HOME.join("bin/vipage"), "./bin/vipage");
    _ = ::std::fs::copy(HOME.join("bin/inverting.sh"), "./bin/inverting.sh");
    _ = ::std::fs::copy(HOME.join("bin/ls"), "./bin/ls");
    _ = ::std::fs::copy(HOME.join("bin/n"), "./bin/n");
    _ = ::std::fs::copy(HOME.join("bin/pie"), "./bin/pie");
    _ = ::std::fs::copy(HOME.join(".tmux.conf"), "./.tmux.conf");
    _ = ::std::fs::copy(HOME.join(".gitconfig-default"), "./.gitconfig-default");
    _ = ::std::fs::copy(HOME.join(".gitmessage"), "./.gitmessage");
    _ = copy_dir_all(HOME.join(".emacs.d"), "./.emacs.d");
    _ = ::std::fs::copy(
        HOME.join(".termux/colors.properties"),
        "./.termux/colors.properties",
    );
    _ = ::std::fs::copy(
        HOME.join(".termux/termux.properties"),
        "./.termux/termux.properties",
    );
    _ = copy_dir_all(HOME.join(".config/alacritty"), "./.config/alacritty");
    _ = ::std::fs::copy(HOME.join(".nanorc"), "./.nanorc");
    _ = ::std::fs::copy(
        HOME.join(".config/coc/extensions/node_modules/bash-language-server/out/cli.js"),
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

fn init(home: PathBuf) -> ::std::io::Result<()> {
    let home_str = home
        .clone()
        .into_os_string()
        .into_string()
        .expect("Cannot convert os_string into string");
    if ::std::path::Path::new("/data/data/com.termux/files/usr/lib/libtermux-exec.so").exists() {
        ::std::env::set_var(
            "LD_PRELOAD",
            "/data/data/com.termux/files/usr/lib/libtermux-exec.so",
        );
    }

    crate::colors::init();

    let mut timer = timer_start_silent();

    let mut f = ::std::fs::File::create(home.join("bin/ls"))?;
    if ::which::which("lsd").is_ok() {
        _ = f.write_all(b"#!/bin/env sh\nlsd $@");
    } else {
        _ = f.write_all(b"#!/bin/env sh\nls $@");
    }

    macro_rules! handle_error {
        ($path: expr) => {
            match $path {
                Some(path) => path,
                None => {
                    return Err(::std::io::Error::new(
                        ::std::io::ErrorKind::NotFound,
                        "directory has not been found"
                    ));
                }
            }
        };
    }
    let usr = handle_error!(home.parent()).join("usr");
    let usr_lib_node_modules = usr.join("lib/node_modules");
    let usr_lib_node = usr.join("lib/node");
    let usr_lib_node_modules_exists = ::std::fs::exists(usr_lib_node_modules.clone())?;
    let usr_lib_node_exists = ::std::fs::exists(usr_lib_node.clone())?;
    if usr_lib_node_modules_exists && !usr_lib_node_exists {
        let _ = ::std::os::unix::fs::symlink(usr_lib_node_modules, usr_lib_node);
    }

    print!("\x1b[5 q");

    timer_end_silent(&mut timer);

    let mut sys = ::sysinfo::System::new_all();
    sys.refresh_all();
    let disks = ::sysinfo::Disks::new_with_refreshed_list();
    let disk_free_space = &disks
        .last()
        .expect("Cannot get last element of an array")
        .available_space();
    timer_total_time(
        &mut timer,
        &format!(
            "free space: {}{} GiB{} loading time",
            ::std::env::var("YELLOW_COLOR").expect("Cannot get environment variable"),
            *disk_free_space as f64 / 1_000_000_000.0f64,
            ::std::env::var("RESET_COLOR").expect("Cannot get environment variable")
        ),
    );

    let todo_path = home.join("todo");
    if todo_path.exists() {
        let content = ::std::fs::read_to_string(todo_path).expect("Cannot read file");
        if content.is_empty() {
            eprintln!("[ERROR] todo_is_empty");
        } else {
            println!("[NOTE] todo file: {}", content);
        }
    }
    Ok(())
}

fn version() {
    println!(include_str!("../../../.dotfiles-version"));
}

fn main() {
    let mut args = ::std::env::args();
    #[allow(unused_variables)]
    let program_name = &args.nth(0).expect("cannot get program name");
    if args.len() == 0 {
        println!("{}: Not enough arguments", program_name);
        short_help!(program_name);
        ::std::process::exit(1);
    }
    enum State {
        NONE,
        COMMIT { only_copy: bool },
        INIT,
        VERSION,
    }
    #[allow(non_snake_case)]
    let HOME = match ::home::home_dir() {
        Some(path) => path,
        None => panic!("Cannot get HOME directory"),
    };
    let mut state = State::NONE;
    while args.len() > 0 {
        match args.nth(0).unwrap().as_str() {
            "--help" | "help" => {
                help!(program_name);
                ::std::process::exit(0);
            }
            "commit" => match state {
                State::NONE => {
                    state = State::COMMIT { only_copy: false };
                }
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    ::std::process::exit(1);
                }
            },
            "init" => match state {
                State::NONE => {
                    state = State::INIT;
                }
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    ::std::process::exit(1);
                }
            },
            "version" | "--version" | "-V" => match state {
                State::NONE => {
                    state = State::VERSION;
                }
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    ::std::process::exit(1);
                }
            },
            "--only-copy" | "-o" => match state {
                State::COMMIT { only_copy: _ } => {
                    state = State::COMMIT { only_copy: true };
                }
                _ => {
                    eprintln!("This option can only be used with `commit` subcommand");
                    short_help!(program_name);
                    ::std::process::exit(1);
                }
            },
            "++only-copy" | "+o" => match state {
                State::COMMIT { only_copy: _ } => {
                    state = State::COMMIT { only_copy: false };
                }
                _ => {
                    println!("This option can only be used with `commit` subcommand");
                    short_help!(program_name);
                    ::std::process::exit(1);
                }
            },
            &_ => {
                println!("Unknown argument");
                short_help!(program_name);
                ::std::process::exit(1);
            }
        }
    }
    match state {
        State::NONE => {}
        State::COMMIT { only_copy } => {
            match commit(only_copy, HOME) {
                Ok(_) => {
                    ::std::process::exit(0);
                }
                Err(e) => {
                    println!("error: {}", e);
                    ::std::process::exit(1);
                }
            };
        }
        State::INIT => {
            match init(HOME) {
                Ok(_) => {
                    ::std::process::exit(0);
                }
                Err(e) => {
                    println!("error: {}", e);
                    ::std::process::exit(1);
                }
            };
        }
        State::VERSION => {
            version();
        }
    }
}
