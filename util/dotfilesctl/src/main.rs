use ::libdotfilesctl::package_manager_wrapper::PackageManagerWrapper;
use ::libdotfilesctl::DotfilesInstaller;
use ::libdotfilesctl::AutorunProgram;
use ::libdotfilesctl::SelectedShell;
use ::std::process::exit;

// TODO: make it a macro
fn exit_with_msg(msg: &str) {
    eprintln!("{}", msg);

    exit(1);
}

fn main() {
    let di = DotfilesInstaller::new();
    let pmw = PackageManagerWrapper::new();
    match di.bootstrap(&pmw) {
        Ok(_) => {},
        Err(e) => exit_with_msg(format!("bootstrap failed: {}", e).as_str()),
    };

    println!("What would you like to do?");
    todo!();
}
