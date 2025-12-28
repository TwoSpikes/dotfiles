use ::libdotfilesctl::package_manager_wrapper::PackageManagerWrapper;
use ::libdotfilesctl::DotfilesInstaller;

fn main() {
    let di = DotfilesInstaller::new();
    let pmw = PackageManagerWrapper::new();
    di.bootstrap(&pmw);
}
