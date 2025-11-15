use ::std::process::exit;

use libdotfilesctlcfg::load;
use libdotfilesctlcfg::handle_config;

use libdotfilesctldev::commit;

macro_rules! usage {
    ($program_name:expr) => {
        println!("{}: [OPTION]... COMMAND", $program_name);
    };
}

macro_rules! commands {
    () => {
        println!("COMMANDS (case sensitive):");
        println!("\tcommit      Commit changes to dotfiles repo");
        println!("\thelp        Show this help message");
    };
}

macro_rules! options {
    () => {
        println!("OPTIONS (case sensitive):");
        println!("\tFor 'commit' subcommand:");
        println!("\t\t--only-copy -o       Only copy, but not commit");
        println!("\t\t++only-copy +o       Copy and commit (default)");
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

fn main() {
    let mut args = ::std::env::args();
    let program_name = args.nth(0).expect("Cannot get program name");
    if args.len() == 0 {
        eprintln!("{}: error: Not enough arguments", program_name);
        short_help!(program_name);
        exit(1);
    }
    enum State {
        None,
        Commit { only_copy: bool },
    }
    let mut state = State::None;
    while args.len() > 0 {
        match args.nth(0).unwrap().as_str() {
            "--help" | "-h" => {
                help!(program_name);
                exit(0);
            },
            "help" => match state {
                State::None => {
                    help!(program_name);
                    exit(0);
                },
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    exit(1);
                },
            },
            "commit" => match state {
                State::None => {
                    state = State::Commit {
                        only_copy: false,
                    };
                },
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    exit(1);
                },
            },
            "--only-copy" | "-o" => match state {
                State::Commit { only_copy: _ } => {
                    state = State::Commit {
                        only_copy: true,
                    };
                },
                _ => {
                    eprintln!("This option can only be used with `commit` subcommand");
                    short_help!(program_name);
                    exit(1);
                },
            },
            "++only-copy" | "+o" => match state {
                State::Commit { only_copy: _ } => {
                    state = State::Commit {
                        only_copy: false,
                    };
                },
                _ => {
                    eprintln!("This option can only be used with `commit` subcommand");
                    short_help!(program_name);
                    exit(1);
                },
            },
            &_ => {
                eprintln!("Unknown argument");
                short_help!(program_name);
                exit(1);
            },
        }
    }
    let home = match ::home::home_dir() {
        Some(path) => path,
        None => {
            eprintln!("Cannot get HOME directory");
            exit(1);
        },
    };
    match state {
        State::None => {},
        State::Commit { only_copy } => {
            let mut config = match load(home) {
                Some(config) => config,
                None => {
                    eprintln!("Cannot load config");
                    exit(1)
                },
            };
            handle_config(&mut config);
            match commit(only_copy, config) {
                Ok(_) => {
                    exit(0);
                }
                Err(e) => {
                    eprintln!("error: {}", e);
                    exit(1);
                }
            };
        }
    }
}
