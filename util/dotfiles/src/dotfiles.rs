pub mod checkhealth;
pub mod colors;
pub mod timer;
pub mod config;

use ::std::io::Write;
use ::std::path::PathBuf;
use ::std::process::exit;

use timer::timer_end_silent;
#[allow(unused_imports)]
use timer::{timer_endln, timer_start_silent, timer_startln, timer_total_time};

enum IsLoginShell {
    Yes,
    No,
    Unspecified,
}

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
        println!("\thelp         Show this help message");
        println!("\tversion --version -V     ");
        println!("\t             Show version");
        println!("\tinit         Initialize dotfiles");
    };
}

macro_rules! options {
    () => {
        println!("OPTIONS (case sensitive):");
        println!("\tCommon:");
        println!("\t\t--login-shell -l     Presume this is a login_shell");
        println!("\t\t++login-shell +l     Presume this is not a login_shell");
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

fn init(home: PathBuf, login_shell: IsLoginShell) -> ::std::io::Result<()> {
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
        _ = f.write_all(b"#!/bin/env sh\nenv ls $@");
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

    let config = match config::load(home) {
        Some(config) => config,
        None => {
            eprintln!("Cannot load config");
            exit(1);
        },
    };
    config::handle_config(config, login_shell);

    print!("\x1b[5 q");

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
        eprintln!("{}: Not enough arguments", program_name);
        short_help!(program_name);
        exit(1);
    }
    enum State {
        NONE,
        INIT,
        VERSION,
    }
    #[allow(non_snake_case)]
    let HOME = match ::home::home_dir() {
        Some(path) => path,
        None => {
            eprintln!("Cannot get HOME directory");
            exit(1);
        },
    };
    let mut login_shell = IsLoginShell::Unspecified;
    let mut state = State::NONE;
    while args.len() > 0 {
        match args.nth(0).unwrap().as_str() {
            "--help" | "-h" => {
                help!(program_name);
                exit(0);
            }
            "help" => match state {
                State::NONE => {
                    help!(program_name);
                    exit(0);
                },
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    exit(1);
                },
            },
            "init" => match state {
                State::NONE => {
                    state = State::INIT;
                },
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    exit(1);
                },
            },
            "version" | "--version" | "-V" => match state {
                State::NONE => {
                    state = State::VERSION;
                },
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    exit(1);
                },
            },
            "--login-shell" | "-l" => {
                login_shell = IsLoginShell::Yes;
            },
            "++login-shell" | "+l" => {
                login_shell = IsLoginShell::No;
            },
            &_ => {
                eprintln!("Unknown argument");
                short_help!(program_name);
                exit(1);
            }
        }
    }
    if matches!(login_shell, IsLoginShell::Unspecified) {
        login_shell = if program_name.starts_with('-') {
            IsLoginShell::Yes
        } else {
            match ::std::env::var("SHLVL") {
                Ok(val) => if val.as_str() == "1" {
                    IsLoginShell::Yes
                } else {
                    IsLoginShell::No
                },
                Err(_) => IsLoginShell::No,
            }
        };
    }
    match state {
        State::NONE => {}
        State::INIT => {
            match init(HOME, login_shell) {
                Ok(_) => {
                    exit(0);
                }
                Err(e) => {
                    eprintln!("error: {}", e);
                    exit(1);
                }
            };
        }
        State::VERSION => {
            version();
        }
    }
}
