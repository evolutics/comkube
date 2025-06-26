use futures::StreamExt;
use kube::api;
use kube::api::ResourceExt;
use kube::core;
use kube::discovery;
use kube::runtime::controller;
use kube::runtime::watcher;
use serde::Deserialize;
use std::collections;
use std::io::Write;
use std::process;
use std::sync;
use std::thread;
use tokio::time;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let client = kube::Client::try_default().await?;
    let discovery = discovery::Discovery::new(client.clone()).run().await?;

    let compose_apps = api::Api::<ComposeApplication>::all(client.clone());

    tracing::info!("Starting controller.");

    controller::Controller::new(compose_apps, watcher::Config::default())
        // TODO: Watch owned objects.
        .shutdown_on_signal()
        .run(
            reconcile,
            error_policy,
            sync::Arc::new(Context { client, discovery }),
        )
        .for_each(|_| futures::future::ready(()))
        .await;

    tracing::info!("Controller terminated.");
    Ok(())
}

#[derive(
    kube::CustomResource, Debug, Clone, serde::Deserialize, serde::Serialize, schemars::JsonSchema,
)]
#[kube(group = "evolutics.info", version = "v1", kind = "ComposeApplication")]
#[kube(shortname = "composeapp", namespaced)]
struct ComposeAppSpec {
    #[serde(flatten)]
    extra: collections::HashMap<String, serde_json::Value>,
}

struct Context {
    client: kube::Client,
    discovery: discovery::Discovery,
}

#[derive(Debug, thiserror::Error)]
enum Error {}

async fn reconcile(
    compose_app: sync::Arc<ComposeApplication>,
    context: sync::Arc<Context>,
) -> anyhow::Result<controller::Action, Error> {
    // TODO: Configure owner references.

    let documents =
        convert_with_kompose(&serde_json::to_string(&compose_app.spec).unwrap()).unwrap();
    let document_count = documents.len();
    let server_side_apply = api::PatchParams::apply("comkube").force();

    for (index, document) in documents.into_iter().enumerate() {
        let object = serde_yaml::from_value::<api::DynamicObject>(document).unwrap();
        let gvk = core::GroupVersionKind::try_from(object.types.as_ref().unwrap()).unwrap();
        let namespace = object
            .metadata
            .namespace
            .as_deref()
            .or(compose_app.metadata.namespace.as_deref());
        let name = object.name_any();

        if let Some((resource, capabilities)) = context.discovery.resolve_gvk(&gvk) {
            let api = dynamic_api(resource, capabilities, context.client.clone(), namespace);
            tracing::trace!(
                "Applying {kind}, document {number}/{document_count}:\n{pretty_object}",
                kind = gvk.kind,
                number = index + 1,
                pretty_object = serde_yaml::to_string(&object).unwrap(),
            );
            let data = serde_json::to_value(&object).unwrap();
            let _result = api
                .patch(&name, &server_side_apply, &api::Patch::Apply(data))
                .await
                .unwrap();
            tracing::info!("Applied {kind} {name}.", kind = gvk.kind);
        } else {
            tracing::warn!(
                "Cannot apply document for unknown {group}/{version}/{kind}.",
                group = gvk.group,
                version = gvk.version,
                kind = gvk.kind,
            );
        }
    }

    Ok(controller::Action::requeue(time::Duration::from_secs(300)))
}

fn error_policy(
    _object: sync::Arc<ComposeApplication>,
    error: &Error,
    _context: sync::Arc<Context>,
) -> controller::Action {
    tracing::warn!("Reconcile failed: {error}");
    controller::Action::requeue(time::Duration::from_secs(1))
}

fn convert_with_kompose(compose_config: &str) -> anyhow::Result<Vec<serde_yaml::Value>> {
    let mut child = process::Command::new("kompose")
        .args(["--file", "-", "convert", "--stdout"])
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

fn dynamic_api(
    resource: discovery::ApiResource,
    capabilities: discovery::ApiCapabilities,
    client: kube::Client,
    namespace: Option<&str>,
) -> api::Api<api::DynamicObject> {
    if capabilities.scope == discovery::Scope::Cluster {
        api::Api::all_with(client, &resource)
    } else if let Some(namespace) = namespace {
        api::Api::namespaced_with(client, namespace, &resource)
    } else {
        api::Api::default_namespaced_with(client, &resource)
    }
}
