use futures::StreamExt;
use k8s_openapi::api::core::v1;
use kube::api;
use kube::api::Resource;
use kube::runtime::controller;
use kube::runtime::watcher;
use std::collections;
use std::sync;
use tokio::time;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();
    let client = kube::Client::try_default().await?;

    let config_map_generators = api::Api::<ConfigMapGenerator>::all(client.clone());
    let config_maps = api::Api::<v1::ConfigMap>::all(client.clone());

    tracing::info!("starting configmapgen-controller");

    controller::Controller::new(config_map_generators, watcher::Config::default())
        .owns(config_maps, watcher::Config::default())
        .shutdown_on_signal()
        .run(reconcile, error_policy, sync::Arc::new(Context { client }))
        .for_each(|result| async move {
            match result {
                Ok(object_reference) => tracing::info!("reconciled {:?}", object_reference),
                Err(error) => tracing::warn!("reconcile failed: {}", error),
            }
        })
        .await;
    tracing::info!("controller terminated");
    Ok(())
}

#[derive(
    kube::CustomResource, Debug, Clone, serde::Deserialize, serde::Serialize, schemars::JsonSchema,
)]
#[kube(group = "evolutics.info", version = "v1", kind = "ConfigMapGenerator")]
#[kube(shortname = "cmg", namespaced)]
struct ConfigMapGeneratorSpec {
    content: String,
}

struct Context {
    client: kube::Client,
}

#[derive(Debug, thiserror::Error)]
enum Error {
    #[error("Failed to create ConfigMap: {0}")]
    ConfigMapCreationFailed(#[source] kube::Error),
    #[error("MissingObjectKey: {0}")]
    MissingObjectKey(&'static str),
}

async fn reconcile(
    generator: sync::Arc<ConfigMapGenerator>,
    context: sync::Arc<Context>,
) -> anyhow::Result<controller::Action, Error> {
    let client = &context.client;

    let mut contents = collections::BTreeMap::new();
    contents.insert("content".to_string(), generator.spec.content.clone());
    let owner_reference = generator.controller_owner_ref(&()).unwrap();
    let config_map = v1::ConfigMap {
        metadata: api::ObjectMeta {
            name: generator.metadata.name.clone(),
            owner_references: Some(vec![owner_reference]),
            ..api::ObjectMeta::default()
        },
        data: Some(contents),
        ..Default::default()
    };
    let config_map_api = api::Api::<v1::ConfigMap>::namespaced(
        client.clone(),
        generator
            .metadata
            .namespace
            .as_ref()
            .ok_or_else(|| Error::MissingObjectKey(".metadata.namespace"))?,
    );
    config_map_api
        .patch(
            config_map
                .metadata
                .name
                .as_ref()
                .ok_or_else(|| Error::MissingObjectKey(".metadata.name"))?,
            &api::PatchParams::apply("configmapgenerator.kube-rt.evolutics.info"),
            &api::Patch::Apply(&config_map),
        )
        .await
        .map_err(Error::ConfigMapCreationFailed)?;
    Ok(controller::Action::requeue(time::Duration::from_secs(300)))
}

fn error_policy(
    _object: sync::Arc<ConfigMapGenerator>,
    _error: &Error,
    _context: sync::Arc<Context>,
) -> controller::Action {
    controller::Action::requeue(time::Duration::from_secs(1))
}
