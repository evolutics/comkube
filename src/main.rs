mod get_desired_state;
mod kompose;

use futures::StreamExt;
use kube::api;
use kube::api::ResourceExt;
use kube::core;
use kube::discovery;
use kube::runtime::controller;
use kube::runtime::watcher;
use std::sync;
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

#[derive(kube::CustomResource, Debug, Clone, serde::Deserialize, serde::Serialize)]
#[kube(
    group = "evolutics.info",
    version = "v1",
    kind = "ComposeApplication",
    namespaced,
    schema = "disabled",
    shortname = "composeapp"
)]
struct ComposeAppSpec {
    #[serde(flatten)]
    value: serde_json::Value,
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
    let objects = self::get_desired_state::get(&compose_app);
    let document_count = objects.len();
    let server_side_apply = api::PatchParams::apply("comkube").force();

    for (index, object) in objects.into_iter().enumerate() {
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

#[cfg(test)]
mod tests {
    #[test]
    fn helm_chart_metadata_matches_package() -> anyhow::Result<()> {
        #[derive(Debug, PartialEq, serde::Deserialize)]
        #[serde(rename_all = "camelCase")]
        struct Chart {
            name: String,
            description: String,
            home: String,
            sources: Vec<String>,
            app_version: String,
        }
        let chart = serde_yaml::from_str::<Chart>(include_str!("../chart/Chart.yaml"))?;

        assert_eq!(
            chart,
            Chart {
                name: env!("CARGO_PKG_NAME").into(),
                description: env!("CARGO_PKG_DESCRIPTION").into(),
                home: env!("CARGO_PKG_HOMEPAGE").into(),
                sources: vec![env!("CARGO_PKG_REPOSITORY").into()],
                app_version: env!("CARGO_PKG_VERSION").into(),
            },
        );
        Ok(())
    }
}
