use ::std::path::Path;
use ::std::path::PathBuf;
use ::std::os::unix::process::CommandExt;
use ::std::process::exit;
use ::std::env::var;

fn is_space(c: char) -> bool {
    return c == ' ' || c == '\u{00A0}';
}

fn is_letter(c: char) -> bool {
    return c.is_alphabetic() || c == '_';
}

pub struct Config {
    pub home_path: Option<Box<PathBuf>>,
    pub dotfiles_path: Option<Box<PathBuf>>,
    pub root_path: Option<Box<PathBuf>>,
}

impl Config {
    pub fn new() -> Self {
        Self {
            home_path: None,
            dotfiles_path: None,
            root_path: None,
        }
    }
}

enum State {
    None,
    Comment,
    Name {
        name: String,
    },
    AfterName {
        name: String,
    },
    EqualSign {
        name: String,
    },
    AfterEqualSign {
        name: String,
    },
    OpenQuote {
        name: String,
    },
    StringValue {
        name: String,
        value: String,
    },
    ClosingQuote {
        name: String,
        value: String,
    },
    Identifier {
        name: String,
        identifier: String,
    },
    BackSlash {
        name: String,
        value: String,
    },
    Command {
        name: String,
    },
}

pub fn load(HOME: PathBuf) -> Option<Config> {
    let text = match ::std::fs::read_to_string(HOME.join(".config/dotfilesctl/config.cfg")) {
        Ok(text) => text,
        Err(_e) => String::new()
    };

    let mut state = State::None;
    let mut config = Config::new();
    for c in text.chars() {
        match state {
            State::None => {
                if is_letter(c) {
                    let mut name = String::new();
                    name.push(c);
                    state = State::Name {
                        name,
                    };
                    continue;
                }
                if c == '#' {
                    state = State::Comment;
                    continue;
                }
            },
            State::Comment => {
                if c == '\r' || c == '\n' {
                    state = State::None;
                    continue;
                }
            },
            State::Name {mut name} => {
                if is_letter(c) {
                    name.push(c);
                    state = State::Name {
                        name,
                    };
                    continue;
                }

                if is_space(c) {
                    state = State::AfterName {
                        name,
                    };
                    continue;
                }

                eprintln!("Error: Unfinished identifier");
                return None;
            },
            State::AfterName {ref name} => {
                if is_space(c) {
                    continue;
                }

                if c == '=' {
                    state = State::EqualSign {
                        name: name.to_string(),
                    };
                    continue;
                }

                eprintln!("Error: Nothing goes after the identifier");
                return None;
            },
            State::EqualSign {name} => {
                if is_space(c) {
                    state = State::AfterEqualSign {
                        name,
                    };
                    continue;
                }

                if is_letter(c) {
                    let mut identifier = String::new();
                    identifier.push(c);
                    state = State::Identifier {
                        name,
                        identifier,
                    };
                    continue;
                }

                eprintln!("Error: Unfinished identifier");
                return None;
            },
            State::AfterEqualSign {ref name} => {
                if is_space(c) {
                    continue;
                }

                if is_letter(c) {
                    state = State::Identifier {
                        name: name.to_string(),
                        identifier: String::new(),
                    };
                    continue;
                }

                if c == '"' {
                    state = State::OpenQuote {
                        name: name.to_string(),
                    };
                    continue;
                }

                eprintln!("Error: Incorrect value");
                return None;
            },
            State::OpenQuote {name} => {
                let mut value = String::new();
                state = parse_value_string_char(c, name, &mut value);
            },
            State::StringValue {name, mut value} => {
                state = parse_value_string_char(c, name, &mut value);
            },
            State::ClosingQuote {ref name, ref value} => {
                if is_letter(c) {
                    eprintln!("Error: Nothing goes after the value");
                    return None;
                }

                if c == '\n' || c == '\r' {
                    match parse_string_value(&mut config, name.to_string(), value.to_string()) {
                        Ok(_)=>{},
                        Err(_)=>{
                            eprintln!("Unable to parse string value");
                            return None;
                        },
                    }
                    state = State::None;
                    continue;
                }
            },
            State::Identifier {ref name, ref mut identifier} => {
                if c == '\n' || c == '\r' {
                    match parse_identifier(&mut config, name.to_string(), identifier.to_string()) {
                        Ok(_)=>{},
                        Err(_)=>{
                            eprintln!("Unable to parse identifier");
                            return None;
                        },
                    }
                    state = State::None;
                    continue;
                }

                if is_letter(c) {
                    identifier.push(c);
                    state = State::Identifier {
                        name: name.to_string(),
                        identifier: identifier.to_string(),
                    };
                    continue;
                }
            },
            State::BackSlash {name,value} => todo!(),
            State::Command {name} => todo!(),
        }
    }
    return Some(config);
}

fn parse_value_string_char(c: char, name: String, value: &mut String) -> State {
    if c == '"' {
        return State::ClosingQuote {
            name,
            value: value.to_string(),
        };
    }

    if c == '\\' {
        return State::BackSlash {
            name,
            value: value.to_string(),
        };
    }

    value.push(c);
    return State::StringValue {
        name,
        value: value.to_string(),
    };
}

fn parse_string_value(config: &mut Config, name: String, value: String) -> Result<(), ()> {
    let value = value.as_str();
    match name.as_str() {
        "home" => {
            config.home_path = Some(Box::new(Path::new(value).to_owned()));
        },
        "dotfiles" => {
            config.dotfiles_path = Some(Box::new(Path::new(value).to_owned()));
        },
        "root" => {
            config.root_path = Some(Box::new(Path::new(value).to_owned()));
        },
        _ => {
            eprintln!("Unknown name: {}", name);
            return Err(());
        },
    }
    return Ok(());
}

fn parse_identifier(config: &mut Config, name: String, identifier: String) -> Result<(), ()> {
    let identifier = identifier.as_str();
    match name.as_str() {
        _ => {
            eprintln!("Unknown name: {}", name);
            return Err(());
        },
    }
    #[allow(unreachable_code)]
    return Ok(());
}

pub fn handle_config(config: &mut Config) {
    if config.home_path.is_none() {
        config.home_path = match ::home::home_dir() {
            Some(path) => Some(Box::new(path)),
            None => None,
        };
    }

    if config.dotfiles_path.is_none() {
        let home_path = *(config.home_path.clone().unwrap());
        let dotfiles_path = home_path.join("dotfiles");
        config.dotfiles_path = Some(Box::new(dotfiles_path));
    }

    if config.root_path.is_none() {
        match var("PREFIX") {
            Ok(prefix) => {
                config.root_path = Some(Box::new(Path::new(prefix.as_str()).join("..")));
            },
            Err(_e) => {
                config.root_path = Some(Box::new(Path::new("/").to_path_buf()));
            },
        }
    }
}
