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
        println!("\tsetup dotfiles vim");
        println!("\t             Generate config for dotfiles vim");
    };
}

macro_rules! options {
    () => {
        println!("OPTIONS (case sensitive):");
        println!("\tFor 'commit' subcommand:");
        println!("\t\t--only-copy -o  Only copy, but not commit");
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
        println!("{} --help", stringify!($program_name));
    };
}

macro_rules! short_help {
    ($program_name:expr) => {
        usage!($program_name);
        println!();
        help_invitation!($program_name);
    };
}

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

#[derive(Clone, Copy)]
enum UseTransparentBg {
    Never,
    InDarkMode,
    InLightMode,
    Always,
}
impl ToString for UseTransparentBg {
    fn to_string(&self) -> String {
        String::from(match self {
            UseTransparentBg::Never => "never",
            UseTransparentBg::InDarkMode => "dark",
            UseTransparentBg::InLightMode => "light",
            UseTransparentBg::Always => "always",
        })
    }
}

#[derive(Clone, Copy)]
enum Background {
    Light,
    Dark,
}
impl ToString for Background {
    fn to_string(&self) -> String {
        String::from(match self {
            Background::Dark => "dark",
            Background::Light => "light",
        })
    }
}

#[derive(Clone, Copy)]
enum Language {
    Automatic,
    Russian,
    English,
}
impl ToString for Language {
    fn to_string(&self) -> String {
        String::from(match self {
            Language::Automatic => "auto",
            Language::Russian => "russian",
            Language::English => "english",
        })
    }
}

#[derive(Clone, Copy)]
enum FalseTrue {
    False,
    True,
}
impl ToString for FalseTrue {
    fn to_string(&self) -> String {
        String::from(match self {
            FalseTrue::False => "false",
            FalseTrue::True => "true",
        })
    }
}

#[derive(Clone, Copy, Debug)]
struct DotfilesSetupVimGetOptionsCursiveUserData {
    do_not_save: bool,
}
impl DotfilesSetupVimGetOptionsCursiveUserData {
    pub fn new() -> Self {
        DotfilesSetupVimGetOptionsCursiveUserData { do_not_save: false }
    }
}

#[derive(Clone)]
struct DotfilesVimConfigOptions {
    use_transparent_bg: UseTransparentBg,
    background: Background,
    cursorcolumn: FalseTrue,
    cursorline: FalseTrue,
    linenr: FalseTrue,
    language: Language,
}
impl DotfilesVimConfigOptions {
    pub fn new() -> Self {
        return DotfilesVimConfigOptions {
            use_transparent_bg: UseTransparentBg::InDarkMode,
            background: Background::Dark,
            cursorcolumn: FalseTrue::False,
            cursorline: FalseTrue::True,
            linenr: FalseTrue::True,
            language: Language::Automatic,
        };
    }
}
fn dotfiles_setup_vim_get_options() -> ::std::io::Result<DotfilesVimConfigOptions> {
    let cursive_user_data = DotfilesSetupVimGetOptionsCursiveUserData::new();

    let mut app = ::cursive::Cursive::default();
    let mut use_transparent_bg_group: cursive::views::RadioGroup<UseTransparentBg> =
        cursive::views::RadioGroup::new();
    let mut background_group: cursive::views::RadioGroup<Background> =
        cursive::views::RadioGroup::new();
    let mut cursorcolumn_group: cursive::views::RadioGroup<FalseTrue> =
        cursive::views::RadioGroup::new();
    let mut cursorline_group: cursive::views::RadioGroup<FalseTrue> =
        cursive::views::RadioGroup::new();
    let mut linenr_group: cursive::views::RadioGroup<FalseTrue> = cursive::views::RadioGroup::new();
    let mut language_group: cursive::views::RadioGroup<Language> =
        cursive::views::RadioGroup::new();
    let label_effect = ::cursive::theme::Effect::Bold;
    let main_layer_view = ::cursive::views::Dialog::new()
        .content(
            ::cursive::views::ListView::new()
                .child(
                    "",
                    ::cursive::views::TextView::new("Use transparent background")
                        .effect(label_effect),
                )
                .child(
                    "",
                    ::cursive::views::LinearLayout::horizontal()
                        .child(use_transparent_bg_group.button(UseTransparentBg::Never, "never"))
                        .child(::cursive::views::DummyView)
                        .child(
                            use_transparent_bg_group
                                .button(UseTransparentBg::InDarkMode, "in dark mode")
                                .selected(),
                        )
                        .child(::cursive::views::DummyView)
                        .child(
                            use_transparent_bg_group
                                .button(UseTransparentBg::InLightMode, "in light mode"),
                        )
                        .child(::cursive::views::DummyView)
                        .child(use_transparent_bg_group.button(UseTransparentBg::Always, "always")),
                )
                .child(
                    "",
                    ::cursive::views::TextView::new("Background").effect(label_effect),
                )
                .child(
                    "",
                    ::cursive::views::LinearLayout::horizontal()
                        .child(background_group.button(Background::Dark, "dark").selected())
                        .child(::cursive::views::DummyView)
                        .child(background_group.button(Background::Light, "light")),
                )
                .child(
                    "",
                    ::cursive::views::TextView::new("Show cursor column").effect(label_effect),
                )
                .child(
                    "",
                    ::cursive::views::LinearLayout::horizontal()
                        .child(
                            cursorcolumn_group
                                .button(FalseTrue::False, "false")
                                .selected(),
                        )
                        .child(::cursive::views::DummyView)
                        .child(cursorcolumn_group.button(FalseTrue::True, "true")),
                )
                .child(
                    "",
                    ::cursive::views::TextView::new("Show cursor line").effect(label_effect),
                )
                .child(
                    "",
                    ::cursive::views::LinearLayout::horizontal()
                        .child(cursorline_group.button(FalseTrue::False, "false"))
                        .child(::cursive::views::DummyView)
                        .child(cursorline_group.button(FalseTrue::True, "true").selected()),
                )
                .child(
                    "",
                    ::cursive::views::TextView::new("Show line numbers").effect(label_effect),
                )
                .child(
                    "",
                    ::cursive::views::LinearLayout::horizontal()
                        .child(linenr_group.button(FalseTrue::False, "false"))
                        .child(::cursive::views::DummyView)
                        .child(linenr_group.button(FalseTrue::True, "true").selected()),
                )
                .child(
                    "",
                    ::cursive::views::TextView::new("Language").effect(label_effect),
                )
                .child(
                    "",
                    ::cursive::views::LinearLayout::horizontal()
                        .child(
                            language_group
                                .button(Language::Automatic, "Automatic")
                                .selected(),
                        )
                        .child(::cursive::views::DummyView)
                        .child(language_group.button(Language::Russian, "Russian"))
                        .child(::cursive::views::DummyView)
                        .child(language_group.button(Language::English, "English")),
                ),
        )
        .button("Save", move |s| {
            let mut user_data = cursive_user_data.clone();
            user_data.do_not_save = false;
            s.set_user_data(user_data);

            s.quit()
        })
        .button("Cancel", move |s| {
            let mut user_data = cursive_user_data.clone();
            user_data.do_not_save = true;
            s.set_user_data(user_data);

            s.quit()
        })
        .title("Setting up dotfiles vim config");
    app.add_layer(main_layer_view);
    app.run();
    let user_data = app
        .user_data::<DotfilesSetupVimGetOptionsCursiveUserData>()
        .expect("Cannot get user data")
        .clone();
    let options = if !user_data.do_not_save {
        DotfilesVimConfigOptions {
            use_transparent_bg: *use_transparent_bg_group.selection(),
            background: *background_group.selection(),
            cursorcolumn: *cursorcolumn_group.selection(),
            cursorline: *cursorline_group.selection(),
            linenr: *linenr_group.selection(),
            language: *language_group.selection(),
        }
    } else {
        DotfilesVimConfigOptions::new()
    };
    Ok(options)
}

fn dotfiles_setup_vim(home: PathBuf) -> ::std::io::Result<()> {
    let options = dotfiles_setup_vim_get_options()?;
    let path = home.join(".config/dotfiles/vim/config.json");
    if !path.exists() {
        _ = ::std::fs::create_dir_all(path.parent().expect("Cannot get parent of a path"));
    }
    let mut f = ::std::fs::File::create(path).expect("Cannot open file for writing");
    f.write(
        ::encoding_rs::UTF_8
            .encode(
                &("{
\"_comment_AUTOGENERATED\":\"Autogenerated by `dotfiles setup dotfiles vim`\",
\"_comment_01\":\"Transparent background\",
\"_comment_02\":\"Values:\",
\"_comment_03\":\"    always - In dark and light theme\",
\"_comment_04\":\"    dark   - In dark theme\",
\"_comment_05\":\"    light  - In light theme\",
\"_comment_06\":\"    never  - Non-transparent\",
	\"use_transparent_bg\": \""
                    .to_owned()
                    + &options.use_transparent_bg.to_string()
                    + "\",

\"_comment_07\":\"Prevent setting up LSP if false\",
\"_comment_08\":\"Useful if it does not work\",
	\"setup_lsp\": false,

\"_comment_09\":\"light - light background\",
\"_comment_10\":\"dark - dark background\",
	\"background\": \"" + &options.background.to_string()
                    + "\",

\"_comment_11\":\"Use italic style for text\",
\"_comment_12\":\"Useful to disable for terminals with bugged italic font (like Termux)\",
	\"use_italic_style\": false,

\"_comment_13\":\"Enable or disable highlighting for current column\",
	\"cursorcolumn\": " + &options.cursorcolumn.to_string()
                    + ",

\"_comment_14\":\"Enable or disable highlighting for current line\",
	\"cursorline\": " + &options.cursorline.to_string()
                    + ",

\"_comment_15\":\"Enable or disable showing line numbers\",
	\"linenr\": " + &options.linenr.to_string()
                    + ",

\"_comment_16\":\"Change the style of line numbers\",
\"_comment_17\":\"Aviable: absolute, relative\",
	\"linenr_style\": \"relative\",

\"_comment_18\":\"Change style of cursorline\",
\"_comment_19\":\"    dim       - Small fogging (default)\",
\"_comment_20\":\"    reverse   - Swap fg with bg\",
\"_comment_21\":\"    underline - Underline a line\",
	\"cursorline_style\": \"dim\",

\"_comment_22\":\"Open quickui menu on start\",
	\"open_menu_on_start\": false,

\"_comment_23\":\"Change quickui_border_style\",
\"_comment_24\":\"1 - Dashed, non-Unicode\",
\"_comment_25\":\"2 - Solid\",
\"_comment_26\":\"3 - Double outer border (default)\",
	\"quickui_border_style\": \"3\",

\"_comment_27\":\"Change quickui colorscheme\",
\"_comment_28\":\"Aviable: borland, gruvbox, solarized, papercol dark, papercol light\",
\"_comment_29\":\"See them at https://github.com/skywind3000/vim-quickui/blob/master/MANUAL.md\",
	\"quickui_color_scheme\": \"papercol dark\",

\"_comment_30\":\"Open on start: alpha (default), ranger, explorer\",
	\"open_on_start\": \"alpha\",

\"_comment_31\":\"Enable Github Copilot\",
\"_comment_32\":\"Useful to disable if you do not have a subscription to it\",
	\"use_github_copilot\": false,

\"_comment_33\":\"Confirm dialogue width (vim-quickui)\",
\"_comment_34\":\"Default: 30\",
	\"pad_amount_confirm_dialogue\": 30,

\"_comment_35\":\"Change cursor style\",
\"_comment_36\":\"Aviable styles:\",
\"_comment_37\":\"  block (default)   █\",
\"_comment_38\":\"  bar               ⎸\",
\"_comment_39\":\"  underline         _\",
	\"cursor_style\": \"block\",

\"_comment_40\":\"Show or do not show tabline\",
\"_comment_41\":\"  0     Do not show\",
\"_comment_42\":\"  1     Show if there is only one tab\",
\"_comment_43\":\"  2     Show always (default)\",
	\"showtabline\": 2,

\"_comment_44\":\"Path style of tab in tabline\",
\"_comment_45\":\"  name      Show only filename (default)\",
\"_comment_46\":\"  short     Short path (relative to cwd and $HOME)\",
\"_comment_47\":\"  shortdir  Short path, reduce dirnames to 1 symbol\",
\"_comment_48\":\"  full      Show full filepath\",
	\"tabline_path\": \"name\",

\"_comment_49\":\"Spacing between tabs in tabline\",
\"_comment_50\":\"  none         abCd\",
\"_comment_51\":\"  full          a  b █C█ d \",
\"_comment_52\":\"  transition    a  b  C  d (default)\",
\"_comment_53\":\"  partial       a b█c█d \",
	\"tabline_spacing\": \"transition\",

\"_comment_54\":\"Show modified symbol ● on modified files\",
	\"tabline_modified\": true,

\"_comment_55\":\"Show icons before filename in tabline\",
\"_comment_56\":\"NOTE: You will need Nerd font\",
	\"tabline_icons\": true,

\"_comment_57\":\"Use mouse clicks for switching between tabs\",
	\"tabline_pressable\": true,

\"_comment_58\":\"Enable mouse clicks\",
	\"enable_mouse\": true,

\"_comment_59\":\"Automatically activate hovered windows\",
	\"mouse_focus\": false,

\"_comment_60\":\"Use nvim-cmp instead of coc.nvim\",
	\"use_nvim_cmp\": false,

\"_comment_61\":\"Show random text at start in alpha-nvim\",
	\"enable_fortune\": false,

\"_comment_62\":\"Show icons in quickui dialogues\",
	\"quickui_icons\": true,

\"_comment_63\":\"Interface language\",
\"_comment_64\":\"Aviable: auto (default), english, russian)\",
\"_comment_65\":\"This option does not change system locale and Vim interface language\",
	\"language\": \"" + &options.language.to_string()
                    + "\",

\"_comment_66\":\"Do things that require fast terminal\",
	\"fast_terminal\": false,

\"_comment_67\":\"Enable which-key.nvim plugin\",
	\"enable_which_key\": true,

\"_comment_68\":\"Compatibility mode\",
\"_comment_69\":\"Aviable: no (default), helix, helix_hard\",
	\"compatible\": \"no\",

	\"do_not_save_previous_column_position_when_going_up_or_down\": false,

\"_comment_end\":\"Ending field to not put comma every time\"
}"),
            )
            .0
            .to_mut(),
    )?;
    Ok(())
}

fn setup(what: SetupWhat, home: PathBuf) -> ::std::io::Result<()> {
    match what {
        SetupWhat::ALL => Err(::std::io::Error::new(
            ::std::io::ErrorKind::Unsupported,
            "setting up everything is not implemented yet",
        )),
        SetupWhat::DOTFILES { what } => match what {
            DotfilesSetupWhat::ALL => Err(::std::io::Error::new(
                ::std::io::ErrorKind::Unsupported,
                "setting up everything is not implemented yet",
            )),
            DotfilesSetupWhat::VIM => dotfiles_setup_vim(home),
        },
    }
}

fn version() {
    println!(include_str!("../../../.dotfiles-version"));
}

enum DotfilesSetupWhat {
    ALL,
    VIM,
}
enum SetupWhat {
    ALL,
    DOTFILES { what: DotfilesSetupWhat },
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
        SETUP { what: SetupWhat },
        VERSION,
    }
    #[allow(non_snake_case)]
    let HOME = match ::home::home_dir() {
        Some(path) => path,
        None => panic!("Cannot get HOME directory"),
    };
    {
        let path_to_dotfiles = HOME.as_path().join("dotfiles");
        assert!(::std::env::set_current_dir(&path_to_dotfiles).is_ok());
    }
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
            "setup" => match state {
                State::NONE => {
                    state = State::SETUP {
                        what: SetupWhat::ALL,
                    };
                }
                _ => {
                    eprintln!("Subcommands can be used only with first cmdline argument");
                    short_help!(program_name);
                    ::std::process::exit(1);
                }
            },
            "dotfiles" => match state {
                State::SETUP { what } => match what {
                    SetupWhat::ALL => {
                        state = State::SETUP {
                            what: SetupWhat::DOTFILES {
                                what: DotfilesSetupWhat::ALL,
                            },
                        };
                    }
                    SetupWhat::DOTFILES { what: _ } => {
                        eprintln!("Cannot set setting up dotfiles because it is already set");
                        short_help!(program_name);
                        ::std::process::exit(1);
                    }
                },
                _ => {
                    eprintln!("This subcommand can only be used with `setup` subcommand");
                    short_help!(program_name);
                    ::std::process::exit(1);
                }
            },
            "vim" => match state {
                State::SETUP { what } => match what {
                    SetupWhat::ALL => {
                        eprintln!("Cannot set setting up dotfiles vim because it is set to set up everything");
                        short_help!(program_name);
                        ::std::process::exit(1);
                    }
                    SetupWhat::DOTFILES { what: _ } => {
                        state = State::SETUP {
                            what: SetupWhat::DOTFILES {
                                what: DotfilesSetupWhat::VIM,
                            },
                        };
                    }
                },
                _ => {
                    eprintln!("This subcommand can only be used with `setup` subcommand");
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
        State::SETUP { what } => {
            match setup(what, HOME) {
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
