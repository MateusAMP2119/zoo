//! the zoo command: runs the official `claude` binary as the agent named on the command line, sharing this terminal.

use std::process::{Command, ExitCode};

fn main() -> ExitCode {
    // 1. the agent comes as the first argument; without one, claude code runs as itself.
    let mut claude = Command::new("claude");
    if let Some(agent) = std::env::args().nth(1) {
        claude.args(["--agent", &agent]);
    }
    // 2. claude code takes over the terminal until it exits, and its exit code is ours.
    match run(claude) {
        Ok(code) => ExitCode::from(code),
        Err(reason) => {
            eprintln!("zoo: could not run claude: {reason}");
            eprintln!("zoo: install claude code with https://claude.ai/install.sh, or rerun the zoo installer");
            ExitCode::FAILURE
        }
    }
}

/// on unix zoo becomes `claude`, so ctrl+c and job control reach claude code alone.
#[cfg(unix)]
fn run(mut claude: Command) -> std::io::Result<u8> {
    use std::os::unix::process::CommandExt;
    Err(claude.exec())
}

/// on windows ctrl+c reaches the whole console, so zoo ignores it and waits, as `cargo run` does.
#[cfg(windows)]
fn run(mut claude: Command) -> std::io::Result<u8> {
    #[link(name = "kernel32")]
    extern "system" {
        fn SetConsoleCtrlHandler(handler: Option<unsafe extern "system" fn(u32) -> i32>, add: i32) -> i32;
    }
    unsafe extern "system" fn ignore(_event: u32) -> i32 {
        1
    }
    unsafe { SetConsoleCtrlHandler(Some(ignore), 1) };
    let status = claude.status()?;
    Ok(status.code().unwrap_or(1) as u8)
}
