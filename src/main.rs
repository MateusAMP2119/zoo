//! The zoo command; entry point `main`.
//!
//! Runs the official `claude` binary as the agent named on the command line,
//! sharing this terminal with it.

use std::process::{Command, ExitCode};

fn main() -> ExitCode {
    // 1. The agent comes as the first argument; without one, Claude Code runs as itself.
    let mut claude = Command::new("claude");
    if let Some(agent) = std::env::args().nth(1) {
        claude.args(["--agent", &agent]);
    }
    // 2. Claude Code takes over the terminal until it exits, and its exit code is ours.
    match run(claude) {
        Ok(code) => ExitCode::from(code),
        Err(reason) => {
            eprintln!("zoo: could not run claude: {reason}");
            eprintln!("zoo: install Claude Code with https://claude.ai/install.sh, or rerun the zoo installer");
            ExitCode::FAILURE
        }
    }
}

/// On Unix zoo becomes `claude`, so Ctrl+C and job control reach Claude Code alone.
#[cfg(unix)]
fn run(mut claude: Command) -> std::io::Result<u8> {
    use std::os::unix::process::CommandExt;
    Err(claude.exec())
}

/// On Windows Ctrl+C reaches every process on the console; zoo lets Claude Code
/// handle it and waits, as `cargo run` does.
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
