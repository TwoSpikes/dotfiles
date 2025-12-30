use ::libdotfilesctl::package_manager_wrapper::PackageManagerWrapper;
use ::libdotfilesctl::DotfilesInstaller;
use ::libdotfilesctl::AutorunProgram;
use ::libdotfilesctl::SelectedShell;

fn main() {
    let di = DotfilesInstaller::new(AutorunProgram::Null, SelectedShell::Bash);
    let pmw = PackageManagerWrapper::new();
    //di.bootstrap(&pmw);
    di.setup_z4h(&pmw);
}
