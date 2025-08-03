use serde::Deserialize;
use std::io::Write;
use std::process;
use std::thread;

pub fn convert(compose_config: &str) -> anyhow::Result<Vec<serde_yaml::Value>> {
    // TODO: Consider supporting OpenShift provider.
    let mut child = process::Command::new("kompose")
        .args(["--file", "-", "convert", "--stdout"])
        .env("COMPOSE_PROJECT_NAME", "dummy") // TODO: Use name from Compose config, else K8s object.
        .stderr(process::Stdio::piped())
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

    if !output.stderr.is_empty() {
        let stderr = String::from_utf8(output.stderr)?;
        tracing::debug!("Kompose stderr:\n{stderr}");
    }

    if output.status.success() {
        let documents = serde_yaml::Deserializer::from_slice(&output.stdout)
            .map(serde_yaml::Value::deserialize)
            .collect::<Result<_, _>>()?;
        Ok(documents)
    } else {
        let exit_status = output.status;
        Err(anyhow::anyhow!("Kompose failed with {exit_status}."))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn converts() -> anyhow::Result<()> {
        let actual = convert(include_str!("test_input.yaml"))?;
        let expected =
            serde_yaml::Deserializer::from_str(include_str!("test_expected_output.yaml"))
                .map(serde_yaml::Value::deserialize)
                .collect::<Result<Vec<_>, _>>()?;

        assert_eq!(actual, expected);
        Ok(())
    }
}
