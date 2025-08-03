use serde::Deserialize;
use std::io::Write;
use std::process;
use std::thread;

pub fn convert(compose_config: &str) -> anyhow::Result<Vec<serde_yaml::Value>> {
    let mut child = process::Command::new("kompose")
        .args(["--file", "-", "convert", "--stdout"])
        .env("COMPOSE_PROJECT_NAME", "dummy")
        .stdin(process::Stdio::piped())
        .stdout(process::Stdio::piped())
        .spawn()?;

    let mut stdin = child.stdin.take().unwrap();
    thread::scope(|scope| {
        scope.spawn(move || {
            stdin.write_all(compose_config.as_bytes()).unwrap();
        });
    });

    let output = child.wait_with_output()?;
    // TODO: Check exit status.
    // TODO: Check stderr.

    let documents = serde_yaml::Deserializer::from_slice(&output.stdout)
        .map(serde_yaml::Value::deserialize)
        .collect::<Result<_, _>>()?;
    Ok(documents)
    // TODO: Consider returning JSON as this would be simpler interface.
}
