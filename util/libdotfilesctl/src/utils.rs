#[macro_export]
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
// Archived: https://drive.google.com/file/d/1m5JVCCNYz0B4fFp9CfGbtQQHM8YQKoVk/view
pub fn copy_dir_all(
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

// If n>0, take first n lines of s (separated by "\n")
// If n=0, return an empty string
// If n<0, take s and return s, with n last lines deleted
pub fn head(s: String, n: isize) -> String {
    let lines = if n >= 0 {
        let mut lines: Vec<&str> = Vec::new();
        let mut iter = s.lines();
        let mut ind: isize = 0;

        while ind < n {
            let next_line = iter.nth(0);
            if let Some(next_line) = next_line {
                lines.push(next_line);
            } else { break; }
            ind += 1;
        }

        lines
    } else {
        let mut lines: Vec<&str> = s.lines().collect();
        let mut ind: isize = 0;

        while ind < -n {
            if lines.pop().is_none() { break; }
            ind += 1;
        }

        lines
    };
    lines.join("\n")
}
